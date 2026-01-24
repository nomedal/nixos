{ config, pkgs, lib, ... }:

{
  # KDE Plasma configuration using plasma-manager
  programs.plasma = {
    enable = true;

    # Workspace settings
    workspace = {
      clickItemTo = "select";
      lookAndFeel = "org.kde.breezedark.desktop";
      theme = "breeze-dark";
      colorScheme = "BreezeDark";
      iconTheme = "Gruvbox-Plus-Dark";
      cursor = {
        theme = "breeze_cursors";
        size = 24;
      };
      wallpaper = null; # Set manually or use a wallpaper path
    };

    # Font configuration
    fonts = {
      general = {
        family = "JetBrainsMono Nerd Font";
        pointSize = 10;
      };
      fixedWidth = {
        family = "JetBrainsMono Nerd Font Mono";
        pointSize = 10;
      };
      small = {
        family = "JetBrainsMono Nerd Font";
        pointSize = 8;
      };
      toolbar = {
        family = "JetBrainsMono Nerd Font";
        pointSize = 10;
      };
      menu = {
        family = "JetBrainsMono Nerd Font";
        pointSize = 10;
      };
      windowTitle = {
        family = "JetBrainsMono Nerd Font";
        pointSize = 10;
      };
    };

    # KWin window manager
    kwin = {
      borderlessMaximizedWindows = false;
      cornerBarrier = true;

      effects = {
        blur.enable = true;
        wobblyWindows.enable = true;
        translucency.enable = true;
        shakeCursor.enable = true;
      };

      nightLight = {
        enable = true;
        temperature = {
          day = 6500;
          night = 2500;
        };
        mode = "times";
        time = {
          morning = "06:00";
          evening = "18:00";
        };
      };

      virtualDesktops = {
        number = 2;
        rows = 1;
        names = [ "Main" "Communication" ];
      };
    };

    # Hotkeys
    hotkeys.commands = {
      "launch-wezterm" = {
        name = "Launch WezTerm";
        key = "Meta+Return";
        command = "wezterm";
      };
      "launch-brave" = {
        name = "Launch Brave";
        key = "Meta+B";
        command = "brave";
      };
      "launch-dolphin" = {
        name = "Launch Dolphin";
        key = "Meta+E";
        command = "dolphin";
      };
    };

    # Spectacle screenshots
    spectacle.shortcuts = {
      captureActiveWindow = "Meta+Print";
      captureCurrentMonitor = "Print";
      captureEntireDesktop = "Shift+Print";
      captureRectangularRegion = "Meta+Shift+Print";
    };

    # Default applications
    configFile = {
      # Terminal
      "kdeglobals"."General"."TerminalApplication" = "wezterm start --cwd .";
      "kdeglobals"."General"."TerminalService" = "org.wezfurlong.wezterm.desktop";

      # Browser
      "kdeglobals"."General"."BrowserApplication" = "brave-browser.desktop";

      # Widget style (Kvantum)
      "kdeglobals"."KDE"."widgetStyle" = "kvantum";

      # Window decorations
      "kwinrc"."org.kde.kdecoration2"."BorderSize" = "Normal";
      "kwinrc"."org.kde.kdecoration2"."BorderSizeAuto" = false;
      "kwinrc"."org.kde.kdecoration2"."ButtonsOnLeft" = "MFS";
      "kwinrc"."org.kde.kdecoration2"."ButtonsOnRight" = "HIAX";

      # Tiling with gaps (like your Krohnkite config)
      "kwinrc"."Tiling"."padding" = 4;

      # Desktop rollover
      "kwinrc"."Windows"."RollOverDesktops" = true;

      # Overview on screen edge
      "kwinrc"."Effect-overview"."BorderActivate" = 3;
    };
  };

  # Copy Kvantum MoeDark theme
  # Note: You may need to install MoeDark theme manually or package it
  xdg.configFile."Kvantum/MoeDark" = {
    source = ../../.config/Kvantum/MoeDark;
    recursive = true;
  };
}
