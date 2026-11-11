{ inputs, pkgs, lib, ... }: {
  imports = [
    ../../../programs/wezterm.nix
    ../../../programs/yazi.nix
    inputs.dms.homeModules.dank-material-shell
  ];

  home.sessionVariables = {
    TERMINAL = "wezterm";
    BROWSER  = "/var/lib/flatpak/exports/bin/com.brave.Browser";
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
        "text/html"              = "com.brave.Browser.desktop";
        "x-scheme-handler/http"  = "com.brave.Browser.desktop";
        "x-scheme-handler/https" = "com.brave.Browser.desktop";
        "x-scheme-handler/ftp"   = "com.brave.Browser.desktop";
        "text/plain"             = "nvim.desktop";
        "text/x-shellscript"     = "nvim.desktop";
        "text/x-python"          = "nvim.desktop";
        "text/x-csrc"            = "nvim.desktop";
        "text/x-chdr"            = "nvim.desktop";
        "text/markdown"          = "nvim.desktop";
        "application/json"       = "nvim.desktop";
        "application/xml"        = "nvim.desktop";
        "application/x-nix"      = "nvim.desktop";
        "application/pdf"        = "com.brave.Browser.desktop";
      };
    };
  };

  home.packages = with pkgs; [
    kdePackages.plasma-integration
    kdePackages.breeze
    kdePackages.breeze-icons
    gnome-calculator
  ];

  # Brave (Flatpak, see modules/workstation.nix) launch flags — the same set
  # the old nixpkgs brave wrapper passed. Written as a real file, not a
  # home.file symlink: /nix/store isn't visible inside the Flatpak sandbox.
  home.activation.braveFlags = lib.hm.dag.entryAfter [ "writeBoundary" ] (let
    flags = pkgs.writeText "brave-flags.conf" ''
      --ozone-platform-hint=auto
      --enable-wayland-ime=true
      --enable-features=AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder,WaylandWindowDecorations
      --disable-features=OutdatedBuildDetector,UseChromeOSDirectVideoDecoder
    '';
  in ''
    run install -Dm644 ${flags} "$HOME/.var/app/com.brave.Browser/config/brave-flags.conf"
  '');

  # One-way migration of the old native Brave profile into the Flatpak sandbox.
  # Runs on every activation (each rebuild + each boot via home-manager-<user>.service), but
  # only acts when the native profile is the newer one: Flatpak profile missing, or its
  # `Local State` older than the native one (Brave started fresh before the copy happened).
  # Once the Flatpak profile has been used, it is newer and this is a no-op, so a host that
  # already migrated (by hand or by this) is never overwritten. A stale Flatpak profile is
  # moved aside, never deleted.
  home.activation.braveProfileMigrate = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    native="$HOME/.config/BraveSoftware"
    fp_dir="$HOME/.var/app/com.brave.Browser/config"
    fp="$fp_dir/BraveSoftware"
    if [ -f "$native/Brave-Browser/Local State" ] \
       && { [ ! -f "$fp/Brave-Browser/Local State" ] \
            || [ "$native/Brave-Browser/Local State" -nt "$fp/Brave-Browser/Local State" ]; }; then
      if ${pkgs.procps}/bin/pgrep -u "$(id -u)" -x brave >/dev/null; then
        warnEcho "Brave profile migration skipped: Brave is running. Quit it and rebuild/reboot."
      else
        if [ -e "$fp" ]; then
          backup="$fp.stale-$(date +%Y%m%d-%H%M%S)"
          verboseEcho "Moving stale Flatpak Brave profile to $backup"
          run mv "$fp" "$backup"
        fi
        noteEcho "Copying native Brave profile into the Flatpak sandbox"
        run mkdir -p "$fp_dir"
        run cp -a "$native" "$fp"
        run rm -f "$fp"/Brave-Browser/Singleton*
      fi
    fi
  '';
}
