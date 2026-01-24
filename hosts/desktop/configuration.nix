{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "desktop";

  # Desktop-specific packages
  environment.systemPackages = with pkgs; [
    # KiCad for electronics design
    kicad

    # VNC
    realvnc-vnc-viewer

    # Additional gaming tools
    mangohud
    gamemode
  ];

  # Gaming optimizations
  programs.gamemode.enable = true;
}
