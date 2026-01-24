# PLACEHOLDER - Generate this file on your laptop with:
#   sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Example - REPLACE with your actual config from nixos-generate-config
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
  };

  swapDevices = [ ];

  # Intel CPU
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
