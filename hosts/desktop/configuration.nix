{ pkgs, ... }:

{
  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10" # EOL but still required by discord/bitwarden/obsidian in nixpkgs 26.11 — remove once nixpkgs updates those packages
  ];

  imports = [
    ./hardware-configuration.nix
    ../../modules/workstation.nix
  ];

  networking.hostName = "desktop";

  # Desktop-specific packages
  environment.systemPackages = with pkgs; [
    # KiCad for electronics design
    kicad

    # Additional gaming tools
    mangohud
  ];

  # Gaming optimizations
  programs.gamemode.enable = true;

  system.stateVersion = "24.11";
}
