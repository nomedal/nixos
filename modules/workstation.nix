{ config, pkgs, lib, inputs, ... }:
let
  # Firefox that always launches inside Mullvad's split-tunnel cgroup via
  # `mullvad-exclude`, so its traffic bypasses the VPN. Used for geo-locked
  # streaming (e.g. F1 TV). Keeps the `firefox` binary name, icon, and
  # firefox.desktop id, so it also covers the app launcher and the
  # default-browser / xdg-open path — every way Firefox gets started.
  # If the Mullvad daemon is down, `mullvad-exclude` refuses to launch
  # rather than leak un-excluded — intentional.
  #
  # The launcher must call the setuid wrapper at ${config.security.wrapperDir}
  # (from services.mullvad-vpn.enableExcludeWrapper), NOT pkgs.mullvad's plain
  # mullvad-exclude — the store binary can't write
  # /sys/fs/cgroup/net_cls/mullvad-exclusions/cgroup.procs as a normal user and
  # exits without launching anything (symptom: "nothing happens").
  firefox-st-launcher = pkgs.writeShellScript "firefox-split-tunnel-launcher" ''
    exec ${config.security.wrapperDir}/mullvad-exclude ${pkgs.firefox}/bin/firefox "$@"
  '';
  firefox-split-tunnel = pkgs.runCommand "firefox-split-tunnel"
    {
      nativeBuildInputs = [ pkgs.xorg.lndir ];
      meta = pkgs.firefox.meta // { mainProgram = "firefox"; };
    } ''
    mkdir -p $out
    lndir -silent ${pkgs.firefox} $out

    rm $out/bin/firefox
    cp ${firefox-st-launcher} $out/bin/firefox
    chmod +x $out/bin/firefox

    rm $out/share/applications/firefox.desktop
    substitute ${pkgs.firefox}/share/applications/firefox.desktop \
      $out/share/applications/firefox.desktop \
      --replace-fail "Exec=firefox" "Exec=$out/bin/firefox"
  '';
in
{
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

  # gnome-keyring — Secret Service provider (org.freedesktop.secrets).
  # Apps that store credentials/sessions there (Bitwarden desktop, VS Code,
  # etc.) otherwise fail with "org.freedesktop.zbus.Error: The name is not
  # activatable" and cannot stay logged in across restarts. The PAM line
  # unlocks the login keyring with the greeter password at login.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

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
    firefox-split-tunnel   # Firefox, always launched via `mullvad-exclude` (see let-block)
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
