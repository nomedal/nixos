{ config, pkgs, lib, inputs, ... }: {
  imports = [
    inputs.dms.nixosModules.dank-material-shell
    inputs.sysc-greet.nixosModules.default
    ./mullvad-tailscale.nix
  ];

  # Boot (EFI/x86 — not for ARM hosts)
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 5;
    };
    efi.canTouchEfiVariables = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Networking via NetworkManager
  networking.networkmanager.enable = true;

  # Audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # Hyprland compositor
  programs.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
  };

  # DMS — system-level integration
  programs.dank-material-shell.enable = true;

  # Greeter (sysc-greet — TUI with aquarium animation)
  # To revert: git revert this commit, nfi sysc-greet removed, nrs
  services.sysc-greet = {
    enable = true;
    compositor = "hyprland";
  };

  # PAM for DMS lock screen
  security.pam.services.hyprlock = {};

  # Desktop services
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.printing.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.mullvad-vpn.enable = true;
  virtualisation.docker.enable = true;
  programs.dconf.enable = true;
  services.flatpak.enable = true;

  # Fonts
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      dejavu_fonts
      liberation_ttf
      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans
      corefonts
      vista-fonts
      font-awesome
      cantarell-fonts
      source-han-sans
      roboto
      open-sans
    ];
    fontconfig.defaultFonts = {
      monospace = [ "JetBrainsMono Nerd Font Mono" ];
      sansSerif = [ "Noto Sans" ];
      serif     = [ "Noto Serif" ];
      emoji     = [ "Noto Color Emoji" ];
    };
  };

  # Desktop packages
  environment.systemPackages = with pkgs; [
    hyprlock
    # Filesystem
    ntfs3g
    exfatprogs
    btrfs-progs
    gparted
    kdePackages.dolphin
    kdePackages.kio-extras
    kdePackages.kservice
    kdePackages.breeze-gtk

    # Networking
    networkmanager
    bind

    # Hardware
    smartmontools
    nvme-cli

    # Development
    neovim
    vscode
    nodejs
    python3
    python3Packages.pip
    dotnet-sdk_8
    gcc
    gnumake
    cmake

    # AI coding assistants
    claude-code
    opencode

    # Cloud sync
    megasync

    # Mullvad GUI (service enabled via mullvad-tailscale.nix)
    mullvad-vpn

    # Privacy
    tor-browser

    # Applications
    brave
    chromium
    firefox
    bitwarden-desktop
    obsidian
    libreoffice-fresh
    inkscape
    vlc
    qbittorrent
    haruna

    # Communication
    discord
    vesktop
    signal-desktop
    telegram-desktop

    # Gaming
    steam
    bolt-launcher

    # Terminals
    wezterm
    kitty

    # Multimedia
    ffmpeg
    pavucontrol
    easyeffects
    obs-studio
    gpu-screen-recorder
    kooha

    # System tools
    timeshift
    veracrypt
    wireshark

    # Misc
    figlet
    unrar
    wlr-randr
  ];

  # Fix Dolphin file associations on non-Plasma desktops
  environment.etc."xdg/menus/applications.menu".text = ''
    <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
      "http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
    <Menu>
      <Name>Applications</Name>
      <DefaultAppDirs/>
      <DefaultMergeDirs/>
    </Menu>
  '';
}
