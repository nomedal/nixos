# NixOS Configuration

Modular NixOS config with Flakes and Home Manager for three hosts:
- **laptop** — Intel Arc GPU, primary machine
- **desktop** — NVIDIA RTX 3070, i7-8700K
- **rpi4** — Raspberry Pi 4, home server (pihole + vaultwarden)

## Stack

- **WM**: Hyprland 0.55 (from `github:hyprwm/Hyprland/v0.55.0`)
- **Shell**: DankMaterialShell (quickshell-based, Material You theming via matugen)
- **Greeter**: greetd + tuigreet
- **Terminal**: WezTerm (CovenantUI colors)
- **Shell**: Zsh + Powerlevel10k
- **Editor**: Neovim (lazy.nvim)
- **Fonts**: JetBrainsMono Nerd Font

## Structure

```
nixos/
├── flake.nix
├── scripts/
│   └── bootstrap.sh                   # USB install automation script
├── hosts/
│   ├── common/
│   │   ├── default.nix                # HM wiring, overlays, GC, trusted-users
│   │   └── users/
│   │       └── default.nix            # user account, groups, SSH key
│   ├── laptop/
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   └── disko.nix
│   ├── desktop/
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   └── disko.nix                  # GPT + EFI + LUKS + btrfs
│   └── rpi4/
│       ├── configuration.nix          # aarch64, pihole + vaultwarden, NAT gateway
│       └── hardware-configuration.nix
├── modules/
│   ├── base.nix                       # Audio, Hyprland, DMS, greetd, fonts, packages
│   ├── mullvad-tailscale.nix          # Mullvad + Tailscale coexistence
│   └── hardware/
│       ├── intel-arc.nix              # Intel Arc / Xe driver config
│       └── nvidia.nix                 # RTX 3070 + Hyprland config
├── home/
│   ├── laptop.nix                     # mkHome + laptop overrides
│   ├── desktop.nix                    # mkHome + desktop overrides
│   ├── rpi4.nix                       # minimal headless home config
│   ├── profiles/                      # composable profile sets (base, desktop, coding, media…)
│   ├── hypr/
│   │   ├── common.lua                 # Shared Hyprland Lua config (binds, rules, look&feel)
│   │   ├── laptop.lua                 # Laptop monitor + brightness keys
│   │   └── desktop.lua                # Desktop monitors + layout
│   ├── nvim/                          # Neovim config (lazy.nvim)
│   └── programs/
│       ├── zsh.nix
│       ├── p10k.zsh
│       ├── wezterm.nix
│       ├── git.nix
│       ├── ssh.nix
│       └── nvim.nix
└── media/
    └── wallpapers/
        └── nebula_2560x1440.jpg
```

## Installing on a new machine

### Quick install (use the bootstrap script)

Boot the NixOS minimal ISO, then:

```bash
# Set Norwegian keyboard (skip if not needed)
loadkeys no

# Run the bootstrap script
bash <(curl -s https://git.nomedal.com/nome/nixos/raw/branch/master/scripts/bootstrap.sh)
```

Or clone manually and run it:

```bash
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' > ~/.config/nix/nix.conf
nix-env -iA nixos.git
git clone https://git.nomedal.com/nome/nixos ~/nixos
bash ~/nixos/bootstrap.sh
```

The script will:
1. Check network connectivity
2. Show `lsblk` and ask which disk to wipe
3. Run disko (partitions, LUKS, btrfs subvolumes, mounts)
4. Copy the repo to `/mnt/etc/nixos`
5. Run `nixos-install`
6. Set root and user passwords via `nixos-enter`

After reboot, go into BIOS and set the NVMe as first boot device.

### Manual install steps

See `CLAUDE.md` for the full annotated manual sequence.

## Day-to-day usage

```bash
# Apply config changes — omitting #hostname uses the machine's hostname automatically
sudo nixos-rebuild switch --flake /etc/nixos

# Update all flake inputs
nix flake update
sudo nixos-rebuild switch --flake /etc/nixos#desktop

# Update a single input
nix flake lock --update-input hyprland

# Check config evaluates before applying
nixos-rebuild build --flake /etc/nixos#desktop

# Garbage collect
sudo nix-collect-garbage --delete-older-than 30d
```

## Notes

- DMS handles all theming (matugen, wallpaper → Material You colors). Don't add waybar, mako, fuzzel, etc.
- quickshell comes from the flake overlay, not nixpkgs — the nixpkgs build doesn't support the `AppId` pragma DMS uses.
- Spotify is managed by `spicetify-nix` — do not use Flatpak or nixpkgs spotify. Updates via normal `nix flake update`.
- `/etc/nixos` is owned by `user` for direct git access without sudo.
