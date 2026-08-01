{ pkgs, ... }:

{
  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10" # EOL but still required by discord/bitwarden/obsidian in nixpkgs 26.11 — remove once nixpkgs updates those packages
  ];

  imports = [
    ./hardware-configuration.nix
    ../../modules/workstation.nix
  ];

  networking.hostName = "laptop";

  services.logind.settings = {
    Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "lock";
    };
  };
  
  # Brightness control
  services.udev.packages = [ pkgs.brightnessctl ];
  
  # Laptop-specific packages
  environment.systemPackages = with pkgs; [
    acpi
  ];

  system.stateVersion = "24.11";
}
