{ config, pkgs, lib, modulesPath, ... }:

{
  # Allow unfree packages (VS Code, etc.)
  nixpkgs.config.allowUnfree = true;

  imports = [
    # Include the NixOS ISO base
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix")
    (modulesPath + "/installer/cd-dvd/channel.nix")
  ];

  # Use your laptop's Intel Arc config
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
      intel-vaapi-driver
      vpl-gpu-rt
    ];
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    LIBVA_DRIVER_NAME = "iHD";
  };

  # ISO-specific settings
  image = {
    fileName = lib.mkForce "nixos-laptop-test.iso";
  };
  isoImage = {
    volumeID = lib.mkForce "NIXOS_TEST";
    squashfsCompression = "zstd -Xcompression-level 6";
  };

  # Include your packages for testing
  environment.systemPackages = with pkgs; [
    # Core utilities
    git wget curl unzip htop fastfetch tree jq

    # Your apps
    brave
    wezterm
    kitty
    neovim
    vscode

    # KDE utilities (already included in plasma6 ISO, but ensure they're there)
    kdePackages.dolphin
    kdePackages.konsole
    kdePackages.kate
    kdePackages.spectacle
    kdePackages.ark

    # Theming
    kdePackages.qtstyleplugin-kvantum

    # Terminal tools
    eza
    bat
    fd
    ripgrep
    fzf
    zoxide

    # System info
    pciutils
    usbutils
    mesa-demos
    intel-gpu-tools
    libva-utils

    # WiFi
    wpa_supplicant
  ];

  # Enable Zsh
  programs.zsh.enable = true;

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    noto-fonts
    noto-fonts-color-emoji
  ];

  # Enable Bluetooth for testing
  hardware.bluetooth.enable = true;

  # Networking - keep it simple, let the base installer module handle it
  networking.hostName = "nixos-live";
  # Don't override networkmanager or wireless - the base ISO module sets this up correctly

  # Include all firmware (Intel WiFi, etc.)
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  # Auto-login for live environment
  services.displayManager = {
    autoLogin = {
      enable = true;
      user = "nixos";
    };
  };

  # Set the default user's shell to zsh
  users.users.nixos = {
    shell = pkgs.zsh;
  };
}
