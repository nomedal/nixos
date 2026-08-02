# Mullvad + Tailscale coexistence — see temp/mullvad-tailscale-linux.md for rationale.
#
# Five problems solved:
#   1. Tailscale blocked while Mullvad is active — fixed by injecting nftables exemptions
#      after every Mullvad connect (NM dispatcher re-runs the fix on each reconnect because
#      Mullvad tears down its entire nftables table on every cycle).
#   2. Network broken after Mullvad disconnect — fixed by a polling watcher that detects
#      the connected→disconnected transition and bounces the active NM connection.
#      (NM dispatcher can't do this safely: nmcli con down/up fires new NM events,
#      causing an infinite loop that lockfiles don't reliably prevent.)
#   3. Rules wiped on nixos-rebuild switch (firewall restart) — fixed by
#      mullvad-tailscale-fix.service which binds to firewall.service and re-injects
#      the rules automatically.
#   4. tailscaled itself can't log in / reach the control plane while Mullvad is active —
#      tailscaled marks its own control-plane and DERP connections with fwmark
#      0x80000/0xff0000 to deliberately escape its own policy-routing table (52) via the
#      main/default routing tables, so its control connection isn't stuck behind its own
#      tunnel setup. That sends the packet out the physical interface, bypassing
#      wg0-mullvad entirely, which Mullvad's default-drop output/input chains then reject
#      (nothing else matches). Fixed by stamping a ct mark on fwmark-0x80000 packets in
#      Mullvad's mangle chain and accepting on that ct mark in output/input — mirrors
#      exactly how Mullvad marks its own split-tunnel-excluded apps (ct mark 0x00000f41),
#      so the exemption survives to the reply direction too.
#   5. Even with #4 fixed, the reply to tailscaled's bypass traffic still gets silently
#      dropped: it arrives back on the physical interface (wlp6s0), but NixOS's own
#      strict reverse-path filter (nixos-fw-rpfilter, separate from Mullvad's table)
#      checks whether the FIB would route back to that source via the *same* interface —
#      and for an unmarked lookup it wouldn't, since normal traffic's route is
#      wg0-mullvad. That's a legitimate asymmetric-routing case, not spoofing, so switch
#      to loose reverse-path checking (routed via any interface, not necessarily the
#      one the packet arrived on).
{ pkgs, ... }:

let
  mullvadTailscaleFix = pkgs.writeShellScript "mullvad-tailscale-fix" ''
    for i in $(seq 1 45); do
      if ${pkgs.mullvad-vpn}/bin/mullvad status 2>/dev/null | grep -q "Connected"; then
        break
      fi
      sleep 1
    done

    # nftables: allow Tailscale traffic through Mullvad's table
    ${pkgs.nftables}/bin/nft insert rule inet mullvad output oifname "tailscale*" accept 2>/dev/null || true
    ${pkgs.nftables}/bin/nft insert rule inet mullvad input iifname "tailscale*" accept 2>/dev/null || true

    # nftables: allow tailscaled's own control-plane/DERP connections (self-marked
    # fwmark 0x80000/0xff0000) to bypass the tunnel, same as Mullvad's own split-tunnel
    # apps. ct mark (not the packet mark) is what makes it through to the reply direction.
    ${pkgs.nftables}/bin/nft insert rule inet mullvad mangle meta mark and 0xff0000 == 0x80000 ct mark set 0x00000f42 2>/dev/null || true
    ${pkgs.nftables}/bin/nft insert rule inet mullvad output ct mark 0x00000f42 accept 2>/dev/null || true
    ${pkgs.nftables}/bin/nft insert rule inet mullvad input ct mark 0x00000f42 accept 2>/dev/null || true

    # routing: Mullvad's policy rule (5209) intercepts Tailscale IPs before table 52.
    # Add a higher-priority rule so 100.64.0.0/10 is routed via Tailscale's table.
    ${pkgs.iproute2}/bin/ip rule del to 100.64.0.0/10 priority 5200 2>/dev/null || true
    ${pkgs.iproute2}/bin/ip rule del from 100.64.0.0/10 priority 5200 2>/dev/null || true
    ${pkgs.iproute2}/bin/ip rule add to 100.64.0.0/10 priority 5200 lookup 52
    ${pkgs.iproute2}/bin/ip rule add from 100.64.0.0/10 priority 5200 lookup 52

    echo "$(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S'): Tailscale rules applied" \
      >> /var/log/mullvad-tailscale.log
  '';
in
{
  # Loose RPF: accept return traffic routed via any interface, not just the one it
  # arrived on. Required for tailscaled's self-marked bypass traffic (problem #5 above).
  networking.firewall.checkReversePath = "loose";

  # Re-inject nftables rules every time any interface comes up (covers Mullvad reconnects).
  networking.networkmanager.dispatcherScripts = [
    {
      source = pkgs.writeShellScript "99-mullvad-tailscale" ''
        if [ "$2" = "up" ] || [ "$2" = "connectivity-change" ]; then
          ${mullvadTailscaleFix} &
        fi
      '';
      type = "basic";
    }
  ];

  # Re-inject rules on every firewall start/reload (covers nixos-rebuild switch).
  # Launches the fix script in the background so it waits for Mullvad to be
  # Connected before injecting — same pattern as the NM dispatcher.
  networking.firewall.extraCommands = ''
    ${mullvadTailscaleFix} &
  '';

  # Polling watcher: bounces the active wifi connection when Mullvad drops.
  systemd.services.mullvad-watch = {
    description = "Mullvad disconnect watcher";
    after = [ "network.target" "mullvad-daemon.service" ];
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ mullvad-vpn networkmanager coreutils ];
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "mullvad-watch" ''
        LAST_STATE=""
        while true; do
          if mullvad status 2>/dev/null | grep -q "Connected"; then
            CURRENT_STATE="connected"
          else
            CURRENT_STATE="disconnected"
          fi

          if [ "$LAST_STATE" = "connected" ] && [ "$CURRENT_STATE" = "disconnected" ]; then
            sleep 2
            ACTIVE_CON=$(nmcli -t -f NAME,TYPE con show --active \
              | grep -v ':vpn' \
              | grep -v 'tailscale' \
              | grep -v 'lo' \
              | head -1 \
              | cut -d: -f1)
            if [ -n "$ACTIVE_CON" ]; then
              nmcli con down "$ACTIVE_CON" && sleep 1 && nmcli con up "$ACTIVE_CON"
              echo "$(date '+%Y-%m-%d %H:%M:%S'): Reconnected $ACTIVE_CON after VPN down" \
                >> /var/log/mullvad-tailscale.log
            fi
          fi

          LAST_STATE="$CURRENT_STATE"
          sleep 3
        done
      '';
      Restart = "always";
      RestartSec = "5s";
    };
  };
}
