# Mullvad + Tailscale coexistence — see temp/mullvad-tailscale-linux.md for rationale.
#
# Three problems solved:
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
