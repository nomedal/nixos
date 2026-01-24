{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "laptop";

  # Laptop-specific settings (new option structure)
  services.logind.settings = {
    Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "lock";
    };
  };

  # Brightness control
  programs.light.enable = true;

  # Laptop-specific packages
  environment.systemPackages = with pkgs; [
    brightnessctl
    acpi
  ];
}
