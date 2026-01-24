# PLACEHOLDER - Generate this file on your actual hardware with:
#   sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
#
# This file contains your specific hardware settings like:
# - Disk/filesystem mounts
# - CPU microcode (intel-ucode or amd-ucode)
# - Kernel modules for your hardware

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Example filesystem configuration - REPLACE with your actual config
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";  # or "btrfs"
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
  };

  swapDevices = [
    # { device = "/dev/disk/by-label/swap"; }
  ];

  # CPU
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # or for AMD:
  # hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
