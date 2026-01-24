{ config, pkgs, lib, ... }:

{
  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Allow unfree packages (for NVIDIA, Steam, etc.)
  nixpkgs.config.allowUnfree = true;

  # Boot
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Networking
  networking = {
    networkmanager.enable = true;
    firewall.enable = true;
  };

  # Timezone and locale
  time.timeZone = "Europe/Oslo"; # Adjust to your timezone
  i18n.defaultLocale = "en_US.UTF-8";

  # Audio with PipeWire
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

  # KDE Plasma 6
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # XDG Portal for Wayland
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
  };

  # Power management
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Other services
  services.tailscale.enable = true;
  virtualisation.docker.enable = true;
  programs.dconf.enable = true;

  # Flatpak
  services.flatpak.enable = true;

  # Fonts
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      # Nerd Fonts
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code

      # Standard fonts
      dejavu_fonts
      liberation_ttf
      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans

      # Microsoft fonts
      corefonts
      vista-fonts

      # Other
      font-awesome
      cantarell-fonts
      source-han-sans
      roboto
      open-sans
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font Mono" ];
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  # System packages (available to all users)
  environment.systemPackages = with pkgs; [
    # Core utilities
    git
    wget
    curl
    unzip
    unrar
    p7zip
    htop
    btop
    fastfetch
    tree
    jq
    pv
    rsync

    # Filesystem
    ntfs3g
    exfatprogs
    btrfs-progs
    gparted

    # Networking
    networkmanager
    iw
    bind

    # Hardware
    pciutils
    usbutils
    lshw
    smartmontools
    nvme-cli

    # KDE/Plasma utilities
    kdePackages.ark
    kdePackages.dolphin
    kdePackages.kate
    kdePackages.kcalc
    kdePackages.konsole
    kdePackages.gwenview
    kdePackages.okular
    kdePackages.spectacle
    kdePackages.kinfocenter
    kdePackages.plasma-pa
    kdePackages.plasma-nm
    kdePackages.bluedevil
    kdePackages.powerdevil
    kdePackages.sddm-kcm
    kdePackages.kde-gtk-config
    kdePackages.breeze-gtk
    kdePackages.kscreen

    # Kvantum theming
    kdePackages.qtstyleplugin-kvantum
    libsForQt5.qtstyleplugin-kvantum

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

    # Applications
    brave
    chromium
    firefox
    bitwarden-desktop
    obsidian
    libreoffice-fresh
    gimp
    inkscape
    vlc
    qbittorrent
    meld

    # Communication
    discord
    vesktop
    signal-desktop
    telegram-desktop

    # Gaming
    steam
    gamescope

    # Terminals
    wezterm
    kitty

    # Multimedia
    ffmpeg
    pavucontrol

    # System tools
    timeshift
    veracrypt
    wireshark

    # Misc
    figlet
    tldr
    eza
  ];

  # Shell
  programs.zsh.enable = true;

  # User account
  users.users.user = {
    isNormalUser = true;
    description = "User";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "audio"
      "video"
      "input"
      "wireshark"
    ];
  };

  # Security
  security.sudo.wheelNeedsPassword = true;
  security.polkit.enable = true;

  # System version (don't change this)
  system.stateVersion = "24.11";
}
