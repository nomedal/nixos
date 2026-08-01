{ inputs, pkgs, lib, ... }: {
  imports = [
    ../../../programs/wezterm.nix
    ../../../programs/yazi.nix
    inputs.dms.homeModules.dank-material-shell
  ];

  home.sessionVariables = {
    TERMINAL = "wezterm";
    BROWSER  = "brave";
  };

  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;
  };

  systemd.user.services.dms = {
    Service = {
      Restart = lib.mkForce "on-failure";
      RestartSec = "3";
    };
  };

  # exec-once crashed at boot (segfault in a LADSPA plugin) racing PipeWire/
  # WirePlumber device enumeration — restart-on-failure recovers once audio
  # is actually up. `--hide-window --service-mode` is EasyEffects' own
  # supported way to start headless-with-tray (no window ever opens, so no
  # Hyprland-side window_rule/hook needed for placement). Its tray icon
  # (StatusNotifierItem) only registers once, at launch, with no retry — the
  # ExecStartPre wait blocks until quickshell/DMS's StatusNotifierWatcher is
  # actually on the bus, since starting before that leaves it with neither a
  # window nor a tray icon.
  systemd.user.services.easyeffects = {
    Unit = {
      Description = "EasyEffects audio effects";
      After = [ "pipewire.service" "wireplumber.service" "hyprland-session.target" ];
      BindsTo = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'while ! ${pkgs.systemd}/bin/busctl --user list 2>/dev/null | grep -q org.kde.StatusNotifierWatcher; do sleep 0.2; done'";
      ExecStart = "${pkgs.easyeffects}/bin/easyeffects --hide-window --service-mode";
      Restart = "on-failure";
      RestartSec = "3";
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };

  wayland.windowManager.hyprland = {
    enable  = true;
    package = pkgs.hyprland;
    # extraConfig set per-host
  };

  home.file.".config/hypr/common.lua".source = ../../../hypr/common.lua;
  home.file.".config/hypr/hyprlock.conf".source = ../../../hypr/hyprlock.conf;

  home.file."Pictures/wallpaper.jpg".source =
    ../../../../media/wallpapers/nebula_2560x1440.jpg;

  home.pointerCursor = {
    gtk.enable = true;
    package    = pkgs.bibata-cursors;
    name       = "Bibata-Modern-Classic";
    size       = 24;
  };

  qt = {
    enable = true;
    platformTheme.name = "kde";
    style = {
      name    = "breeze";
      package = pkgs.kdePackages.breeze;
    };
  };

  xdg.configFile."kdeglobals".text =
    builtins.readFile "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors"
    + ''

      [General]
      ColorScheme=BreezeDark
      widgetStyle=Breeze

      [Icons]
      Theme=breeze-dark

      [KDE]
      contrast=4
      widgetStyle=Breeze
    '';

  xdg.dataFile."color-schemes/BreezeDark.colors".source =
    "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors";

  gtk = {
    enable = true;
    theme = {
      name    = "Breeze-Dark";
      package = pkgs.kdePackages.breeze-gtk;
    };
    iconTheme = {
      name    = "Fluent-dark";
      package = pkgs.fluent-icon-theme;
    };
  };

  services.kdeconnect.enable = true;

  xdg = {
    enable   = true;
    userDirs = { enable = true; createDirectories = true; };
    mimeApps = {
      enable = true;
      defaultApplications = {
        "image/jpeg"             = "qimgv.desktop";
        "image/png"              = "qimgv.desktop";
        "image/gif"              = "qimgv.desktop";
        "image/webp"             = "qimgv.desktop";
        "image/bmp"              = "qimgv.desktop";
        "image/tiff"             = "qimgv.desktop";
        "image/svg+xml"          = "qimgv.desktop";
        "video/mp4"              = "vlc.desktop";
        "video/x-matroska"       = "vlc.desktop";
        "video/webm"             = "vlc.desktop";
        "video/x-msvideo"        = "vlc.desktop";
        "video/quicktime"        = "vlc.desktop";
        "audio/mpeg"             = "vlc.desktop";
        "audio/flac"             = "vlc.desktop";
        "audio/ogg"              = "vlc.desktop";
        "audio/wav"              = "vlc.desktop";
        "audio/x-wav"            = "vlc.desktop";
        "text/html"              = "brave-browser.desktop";
        "x-scheme-handler/http"  = "brave-browser.desktop";
        "x-scheme-handler/https" = "brave-browser.desktop";
        "x-scheme-handler/ftp"   = "brave-browser.desktop";
        "text/plain"             = "nvim.desktop";
        "text/x-shellscript"     = "nvim.desktop";
        "text/x-python"          = "nvim.desktop";
        "text/x-csrc"            = "nvim.desktop";
        "text/x-chdr"            = "nvim.desktop";
        "text/markdown"          = "nvim.desktop";
        "application/json"       = "nvim.desktop";
        "application/xml"        = "nvim.desktop";
        "application/x-nix"      = "nvim.desktop";
        "application/pdf"        = "brave-browser.desktop";
      };
    };
  };

  home.packages = with pkgs; [
    kdePackages.plasma-integration
    kdePackages.breeze
    kdePackages.breeze-icons
    gnome-calculator
  ];
}
