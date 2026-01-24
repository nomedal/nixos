# NixOS Configuration

A modular NixOS configuration with Flakes and Home Manager, supporting both desktop (NVIDIA) and laptop (Intel Arc) setups.

## Features

- **KDE Plasma 6** with Wayland
- **Theming**: MoeDark/Gruvbox dark theme with Kvantum
- **Shell**: Zsh with Powerlevel10k, autosuggestions, syntax highlighting
- **Terminal**: WezTerm with GPU acceleration
- **Fonts**: JetBrainsMono Nerd Font
- **KWin**: Blur effects, wobbly windows, night light

## Structure

```
nixos/
├── flake.nix                 # Main flake configuration
├── modules/
│   ├── base.nix              # Shared system configuration
│   └── hardware/
│       ├── nvidia.nix        # NVIDIA GPU settings
│       └── intel-arc.nix     # Intel Arc GPU settings
├── hosts/
│   ├── desktop/
│   │   ├── configuration.nix
│   │   └── hardware-configuration.nix  # Generate this!
│   └── laptop/
│       ├── configuration.nix
│       └── hardware-configuration.nix  # Generate this!
├── home/
│   ├── home.nix              # Home Manager entry point
│   ├── programs/
│   │   ├── zsh.nix           # Shell configuration
│   │   ├── wezterm.nix       # Terminal configuration
│   │   └── git.nix           # Git configuration
│   └── desktop/
│       └── plasma.nix        # KDE Plasma configuration
├── .config/
│   └── Kvantum/
│       └── MoeDark/          # Kvantum theme
└── .p10k.zsh                 # Powerlevel10k config
```

## Installation

### 1. Boot into NixOS Installer

Download the NixOS ISO and boot from it.

### 2. Partition and Mount

```bash
# Example for a simple setup (adjust for your needs)
# Create partitions
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MB 512MB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart primary 512MB 100%

# Format
mkfs.fat -F32 -n BOOT /dev/nvme0n1p1
mkfs.ext4 -L nixos /dev/nvme0n1p2

# Mount
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/BOOT /mnt/boot
```

### 3. Generate Hardware Configuration

```bash
nixos-generate-config --root /mnt
# Copy the generated hardware-configuration.nix to the appropriate host folder
```

### 4. Clone This Repository

```bash
nix-shell -p git
git clone <your-repo-url> /mnt/etc/nixos
cd /mnt/etc/nixos
```

### 5. Update hardware-configuration.nix

Copy the generated `/mnt/etc/nixos/hardware-configuration.nix` to:
- `hosts/desktop/hardware-configuration.nix` (for desktop)
- `hosts/laptop/hardware-configuration.nix` (for laptop)

### 6. Customize

Edit these files:
- `modules/base.nix`: Change timezone, locale
- `home/programs/git.nix`: Set your name and email
- `home/home.nix`: Adjust username if needed

### 7. Install

```bash
# For desktop
nixos-install --flake .#desktop

# For laptop
nixos-install --flake .#laptop
```

### 8. Reboot

```bash
reboot
```

## Post-Installation

### Rebuild after changes

```bash
cd /etc/nixos
sudo nixos-rebuild switch --flake .#desktop  # or .#laptop
```

### Update flake inputs

```bash
nix flake update
sudo nixos-rebuild switch --flake .#desktop
```

### Garbage collection

```bash
sudo nix-collect-garbage -d
```

## Customization

### Adding packages

- System-wide: Add to `environment.systemPackages` in `modules/base.nix`
- User-only: Add to `home.packages` in `home/home.nix`

### Flatpak apps

After installation, add Flathub and install apps:

```bash
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.obsproject.Studio
flatpak install flathub org.kicad.KiCad
```

### Krohnkite Tiling

The Krohnkite tiling script isn't packaged in nixpkgs. Install manually:

```bash
# Download from GitHub
git clone https://github.com/esjeon/krohnkite.git
cd krohnkite
./build.sh
./install.sh
```

Or use the KDE Store in System Settings > Window Management > KWin Scripts.

## Troubleshooting

### NVIDIA Issues

If you have issues with NVIDIA on Wayland:

1. Try adding to kernel params: `nvidia.NVreg_PreserveVideoMemoryAllocations=1`
2. Enable nvidia-persistenced service
3. Check `nvidia-smi` works

### Intel Arc Issues

If Intel Arc isn't detected:

1. Ensure you're on kernel 6.2+ (Xe driver)
2. Check `vainfo` for hardware acceleration
3. Try removing `xe.force_probe` if your Arc GPU is already supported

## Notes

- The Powerlevel10k configuration (`.p10k.zsh`) is from your original setup
- MoeDark Kvantum theme is included in `.config/Kvantum/MoeDark/`
- Some AUR packages (like `zen-browser-bin`) may need alternatives or Flatpak versions
