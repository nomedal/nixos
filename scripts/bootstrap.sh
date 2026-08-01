#!/usr/bin/env bash
# NixOS install bootstrap — run from the NixOS minimal ISO as root
set -euo pipefail

# ── Keyboard ──────────────────────────────────────────────────────────────────
echo "Setting Norwegian keyboard layout..."
loadkeys no

# ── Network check ─────────────────────────────────────────────────────────────
echo "Checking network connectivity..."
if ! ping -c 1 1.1.1.1 &>/dev/null; then
  echo "No network. Connect with nmcli first:"
  echo "  nmcli device wifi connect \"SSID\" password \"password\""
  exit 1
fi
echo "Network OK."

# ── Enable flakes ─────────────────────────────────────────────────────────────
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' > ~/.config/nix/nix.conf

# ── Install git and clone repo ────────────────────────────────────────────────
nix-env -iA nixos.git
git clone https://git.nomedal.com/nome/nixos ~/nixos
cd ~/nixos

# ── Disk selection ────────────────────────────────────────────────────────────
echo ""
lsblk
echo ""
read -rp "Enter target disk (e.g. nvme0n1): " DISK
echo ""
echo "WARNING: This will WIPE /dev/${DISK}. Are you sure? (yes/no)"
read -r CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo "Aborted."
  exit 1
fi

# ── Disko ─────────────────────────────────────────────────────────────────────
echo "Running disko on /dev/${DISK}..."
nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode destroy,format,mount \
  hosts/desktop/disko.nix

echo "Verifying mounts..."
mount | grep /mnt

# ── Copy repo ─────────────────────────────────────────────────────────────────
mkdir -p /mnt/etc/nixos
cp -r ~/nixos/. /mnt/etc/nixos/

# ── Install ───────────────────────────────────────────────────────────────────
echo "Starting nixos-install..."
nixos-install --flake /mnt/etc/nixos#desktop

# ── Set passwords ─────────────────────────────────────────────────────────────
echo ""
echo "Setting root password..."
nixos-enter --root /mnt -- passwd root

echo "Setting user password..."
nixos-enter --root /mnt -- passwd user

echo ""
echo "Done! Run: reboot"
echo "In BIOS, set UEFI OS (nvme0n1) as first boot device."
