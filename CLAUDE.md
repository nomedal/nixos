# NixOS Config — Claude Code Context

Read this fully before touching any files.

---

## Current status (as of 2026-05-30) — all hosts on NixOS

- **laptop**: Hyprland (nixpkgs) + DankMaterialShell, fully working, Lua config
- **desktop**: Hyprland (nixpkgs) + DMS running, Lua config, EasyEffects presets declarative
- **rpi4**: active — pihole + vaultwarden in Docker, NAT gateway

---

## What is working (both hosts)

- Hyprland 0.55 (from `github:hyprwm/Hyprland/v0.55.0` flake input), **Lua config** (`home/hypr/`)
- DankMaterialShell via quickshell (from nixpkgs — quickshell 0.3.0 landed in nixpkgs-unstable
  via DMS PR #2417 merged 2026-05-14; the separate quickshell flake input and overlay were removed)
- greetd + tuigreet as display manager (`start-hyprland` on login)
- Home Manager wired through `hosts/common/default.nix`
- Dotfiles: nvim (lazy.nvim), zsh (Powerlevel10k), WezTerm (CovenantUI), git, ssh
- Wallpaper: `media/wallpapers/nebula_2560x1440.jpg` → `~/Pictures/wallpaper.jpg`
- Cursor: Bibata-Modern-Classic (24px)
- Mullvad VPN + Tailscale coexistence (`modules/mullvad-tailscale.nix`)
- Firefox always launches split-tunnelled: `modules/workstation.nix` ships `firefox-split-tunnel`
  (a `runCommand` + `lndir` rewrap of `pkgs.firefox`) instead of plain `firefox`. Its `bin/firefox`
  and `firefox.desktop` both go through `mullvad-exclude`, so CLI, app launcher, and default-browser
  opens all bypass the VPN — used for geo-locked streaming (F1 TV). Refuses to start if the Mullvad
  daemon is down (no un-excluded fallback, by design). Firefox is single-instance: the first process
  wins, so don't start an un-wrapped Firefox alongside it.
  - **Must call the setuid wrapper** `${config.security.wrapperDir}/mullvad-exclude`
    (`/run/wrappers/bin/...`, from `services.mullvad-vpn.enableExcludeWrapper = true`), NOT
    `${pkgs.mullvad}/bin/mullvad-exclude`. The plain store binary can't write
    `/sys/fs/cgroup/net_cls/mullvad-exclusions/cgroup.procs` as a normal user — it errors and never
    launches Firefox (symptom: clicking Firefox does nothing). First cut of this used the store
    binary and hit exactly that.
- Docker, Flatpak, Tailscale, printing (CUPS)
- Spotify: managed by `spicetify-nix` (`github:gerg-l/spicetify-nix` flake input) — do NOT use
  Flatpak or nixpkgs spotify. spicetify-nix pins a working Spotify version and wraps it with
  Spicetify. Configured in `home/profiles/sets/media/default.nix` via `programs.spicetify`. Theme: text.
  Extensions + custom apps declared there; updates via normal `nix flake update`.
- Dolphin: file manager, dark theme, file associations, MIME defaults — all working
  - Qt dark theme: `qt.style = breeze` + full BreezeDark color data embedded in kdeglobals
    via `builtins.readFile` — required because `plasma-apply-colorscheme` never runs without Plasma
  - Icon theme: `breeze-dark` (from `kdePackages.breeze-icons`)
  - GTK theme: `Breeze-Dark` (from `kdePackages.breeze-gtk`)
  - Thunar and tumbler removed — Dolphin is the only file manager

## Desktop-specific
- NVIDIA RTX 3070 via `modules/hardware/nvidia.nix`
- 4TB HDDs (sda, sdb) automounted via ntfs3
- `/etc/nixos` owned by `user` for direct git access without sudo
- EasyEffects presets (`990DT` output, `SM58-Disco` input) in `configs/`, deployed via `xdg.dataFile`
  in `home/desktop.nix` (EE 8.x reads presets from `~/.local/share/easyeffects/`, not `~/.config/`)
- `hypr-monitor-watch` (reloads Hyprland on monitoradded) runs as `systemd.user.services.hypr-monitor-watch`, bound to `hyprland-session.target` — do NOT use `hl.exec_once` (nil in 0.55)
- Monitors identified by `desc:` strings in `desktop.lua` (not port names like DP-1) — prevents swap after power cycle
- Tray-icon autostart (Mullvad, Signal, Vesktop, MEGAsync): each registers its StatusNotifierItem
  exactly once at launch, no retry — starting before quickshell/DMS's tray watcher exists leaves them
  with no window and no icon. Wrap the launch command in `wait_for_tray()` (`home/hypr/common.lua`),
  which blocks on a `busctl --user list` poll for `org.kde.StatusNotifierWatcher` before exec'ing.
  EasyEffects is launched headless via systemd (`--hide-window --service-mode`, its own supported
  mode) with the same busctl wait as `ExecStartPre` — see `systemd.user.services.easyeffects` in
  `home/profiles/contexts/workstation/default.nix`.

## Known issues / TODO
- **Desktop crashes (green screen), under investigation**: two crashes (2026-07-21, 2026-07-24)
  traced to Xid 56 (display engine error) caused by GPU BAR1 mapping exhaustion during Brave
  hardware video decode (VA-API → nvidia-vaapi-driver → nvidia-drm). Switched
  `modules/hardware/nvidia.nix` driver from `nvidiaPackages.stable` (595.84, same version as
  `.production`) to `nvidiaPackages.latest` (610.43.02) on 2026-07-24 as a first attempt — needs
  a reboot to load and a few days of Brave video use to confirm it's actually fixed. If it
  recurs on 610.43.02, the fallback is disabling hardware video decode in Brave
  (`brave://settings/system`) or removing `nvidia-vaapi-driver`/`LIBVA_DRIVER_NAME` entirely.
- **Blur unsupported**: DMS shows "background blur: unsupported - compositor" warning on desktop
- **agenix**: secrets management not yet set up — deferred
- First nvim launch bootstraps lazy.nvim and downloads plugins (expected)
- **rpi4 placeholder IPs**: `hosts/rpi4/configuration.nix` has `YOUR_STATIC_IP`, `YOUR_UPSTREAM_GATEWAY`,
  `YOUR_DOWNSTREAM_GATEWAY`, `YOUR_DHCP_START`, `YOUR_DHCP_END` — real values kept out of git for privacy.
  Fill them in locally before deploying. Consequence: the rpi4 config does not `nix eval` from the
  pristine repo (`toInt: Could not convert "YOUR_DOWNSTREAM_GATEWAY"`), so it must be built on the rpi4
  itself, where the real values are filled in.
- **rpi4 container images**: Vaultwarden pulls from `ghcr.io/dani-garcia/vaultwarden:latest`, not Docker
  Hub — Docker Hub now requires an authenticated (PAT) pull. Keep new rpi4 containers on GHCR/quay where
  possible.
- **No Secret Service / keyring** (fixed 2026-09): this machine had no `org.freedesktop.secrets` provider
  at all. Apps that store sessions/credentials there (Bitwarden desktop app first noticed it, after a
  `nixpkgs` bump moved it 2026.6.1 → 2026.8.0 and the new version started requiring one) failed with
  `org.freedesktop.zbus.Error: The name is not activatable` and couldn't stay logged in across restarts.
  Fixed via `services.gnome.gnome-keyring.enable` + `security.pam.services.greetd.enableGnomeKeyring` in
  `modules/workstation.nix`. (A same-week Bitwarden *browser extension* login failure was an unrelated,
  simple case of corrupted local extension state after a Brave auto-update — fixed by removing and
  reinstalling the extension, nothing to do with the keyring or the server.)

---

## Config structure

Home Manager is composed via `nome.lib.mkHome { context, identity, sets }` defined in
`lib/mkHome.nix`. Host entry points (`home/<hostname>.nix`) call mkHome and add
host-specific overrides on top.

```
nixos/
├── flake.nix                          # mkHost + nome.lib.mkHome wiring;
│                                      # inputs: nixpkgs, home-manager,
│                                      # dms, quickshell, hyprland, disko
├── lib/
│   └── mkHome.nix                     # nome.lib.mkHome { context, identity, sets }
├── scripts/
│   └── bootstrap.sh                   # USB install automation (for new installs)
├── hosts/
│   ├── common/
│   │   ├── default.nix                # HM wiring, nixpkgs overlay (quickshell),
│   │   │                              # nix GC/optimise, trusted-users
│   │   └── users/
│   │       └── default.nix            # user account, groups, SSH key
│   ├── laptop/
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   └── disko.nix
│   └── desktop/
│       ├── configuration.nix
│       ├── hardware-configuration.nix
│       └── disko.nix                  # GPT + 1G EFI + LUKS + btrfs on nvme0n1
├── modules/
│   ├── base.nix                       # Nix settings, GC, trusted-users (all hosts)
│   ├── workstation.nix                # Hyprland, DMS, greetd, fonts, packages
│   │                                  # (shared by laptop + desktop, not rpi4)
│   ├── mullvad-tailscale.nix          # Mullvad + Tailscale coexistence
│   └── hardware/
│       ├── intel-arc.nix              # DO NOT TOUCH — hard-won Arc/Xe driver config
│       └── nvidia.nix                 # RTX 3070 + Hyprland env vars
├── home/
│   ├── desktop.nix                    # mkHome { context="desktop", sets=[coding,hardware,media] }
│   │                                  # + desktop overrides (HDD bookmarks, desktop.lua)
│   ├── laptop.nix                     # mkHome { context="desktop", sets=[coding,hardware,media] }
│   │                                  # + laptop overrides (laptop.lua)
│   ├── profiles/
│   │   ├── base/
│   │   │   └── default.nix            # Shell (zsh), CLI tools — all hosts
│   │   ├── contexts/
│   │   │   ├── workstation/
│   │   │   │   └── default.nix        # Hyprland, DMS, theming (Qt/GTK/cursor),
│   │   │   │                          # MIME defaults, kdeconnect, wallpaper
│   │   │   └── server/
│   │   │       └── default.nix        # Headless tools (stub — fill when adding servers)
│   │   └── sets/
│   │       ├── coding/
│   │       │   └── default.nix        # nvim, Python env, uv, ruff, lazygit
│   │       ├── hardware/
│   │       │   └── default.nix        # Hardware tools stub (KiCad, OpenOCD etc.)
│   │       └── media/
│   │           └── default.nix        # Spotify via spicetify-nix
│   ├── users/
│   │   └── nome/
│   │       ├── preferences.nix        # username, homeDirectory, sessionVariables
│   │       └── identities/
│   │           ├── private.nix        # Personal git + ssh config
│   │           └── work.nix           # Work identity stub
│   ├── hypr/
│   │   ├── common.lua                 # Shared Hyprland Lua config (binds, rules, look&feel)
│   │   ├── laptop.lua                 # monitor (eDP-1), brightness keys
│   │   └── desktop.lua               # monitors (desc: identifiers), layout
│   ├── nvim/                          # Neovim config (lazy.nvim)
│   │   ├── init.lua
│   │   └── lua/
│   └── programs/
│       ├── zsh.nix
│       ├── p10k.zsh
│       ├── wezterm.nix                # CovenantUI colors
│       ├── git.nix
│       ├── ssh.nix
│       └── nvim.nix
└── media/
    └── wallpapers/
        └── nebula_2560x1440.jpg
```

---

## The user

- **Username**: `user` (NixOS), `nome` (git)
- **Hosts**: `laptop` (Intel Arc), `desktop` (RTX 3070, i7-8700K), `rpi4`; planned: proxmox-vm, vps
- **Shell**: zsh + Powerlevel10k, WezTerm, JetBrains Mono Nerd Font

---

## Important constraints

- **Never touch `modules/hardware/intel-arc.nix`** or
  `hosts/laptop/hardware-configuration.nix` without reading them first.
  Hard-won settings for the Arc/Xe driver.
- **Validate before switching.**
  ```bash
  nixos-rebuild build --flake .#laptop   # or .#desktop
  ```
- **DMS replaces the full desktop stack.** Don't add waybar, mako, fuzzel,
  rofi, swaylock — DMS handles all of it.
- **quickshell comes from nixpkgs** — the separate flake input and overlay were removed.
- **DMS greeter (`nixosModules.greeter`) does not work** — the `greeter` user
  can't acquire a logind seat. Use tuigreet only.
- **DMS needs `RestartSec = "3"`** — in `home/profiles/contexts/desktop/default.nix`.
  DMS starts via `hyprland-session.target` which fires before the Wayland socket is
  fully ready; without the delay it crashes 6 times, hits the systemd restart
  limit, and stays dead (grey screen).
- **Hyprland and xdg-desktop-portal-hyprland come from nixpkgs** — the separate flake input
  was removed; both track nixpkgs-unstable. `pkgs.hyprland` and `pkgs.xdg-desktop-portal-hyprland`.
- **Main monitor must not be at `y=0`** — Hyprland lets the cursor escape to `y=-1` at the
  absolute top of the workspace, which puts it above the DMS hover zone (dead zone at top edge).
  Fix: set main monitor to `position = "0x1"` and offset side monitors by 1px to match.

---

## Workflow rules

- **Before every commit**: check whether `README.md` and `CLAUDE.md` need updating to reflect the change. Include any updates in the same commit. Output "Evaluated: README.md — [reason]. CLAUDE.md — [reason]." so the user can see it was done.
- **Autocommit**: after any config change, commit immediately with a descriptive message, then `git push`.
- **End of session**: when a topic is done, prompt to update `CLAUDE.md` and `MEMORY.md`.

---

## Dotfiles flake input

`nvim`, `wezterm`, and `p10k` configs live in a separate repo (`github:nome/dotfiles`,
remote: `https://git.nomedal.com/nome/dotfiles.git`) declared as a `flake = false` input.
The nixos repo does not contain copies — it sources directly from `${inputs.dotfiles}/...`.

Workflow when editing dotfiles:
1. Edit in `~/reps/dotfiles`
2. `git push` in the dotfiles repo
3. `nix flake update dotfiles` in `/etc/nixos` (updates flake.lock to the new commit)
4. `sudo nixos-rebuild switch --flake /etc/nixos#desktop`

**Never use bare `nix flake update`** — that updates all inputs (nixpkgs, Hyprland, DMS, etc.)
at once. Always target specific inputs by name.

---

## Tools and commands

```bash
# Apply config
sudo nixos-rebuild switch --flake /etc/nixos#desktop
sudo nixos-rebuild switch --flake /etc/nixos#laptop

# Build without applying (validate)
nixos-rebuild build --flake /etc/nixos#desktop

# Update a specific flake input (preferred)
nix flake update dotfiles       # pull latest dotfiles commit
nix flake update dms            # update DMS
nix flake update nixpkgs        # update nixpkgs only

# Update ALL inputs at once (use sparingly — bumps nixpkgs, Hyprland, etc.)
nix flake update

# Diff generations
nvd diff /run/current-system result

# Garbage collect
sudo nix-collect-garbage --delete-older-than 30d
```

---

## Installing on a new machine

Use `bootstrap.sh` — it handles keymap, flakes, clone, disko, install, and
passwords. See `README.md` for details.

Key lessons from the desktop install (2026-05-21):
- Don't use `--no-root-passwd` — leaves root locked with no way in
- Set passwords before rebooting: `nixos-enter --root /mnt -- passwd user`
- disko needs `--extra-experimental-features "nix-command flakes"` on the ISO
- Norwegian keyboard on ISO: `loadkeys no`
- After install, `chown -R user:users /etc/nixos` for passwordless git access
