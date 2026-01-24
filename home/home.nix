{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.plasma-manager.homeModules.plasma-manager
    ./programs/zsh.nix
    ./programs/wezterm.nix
    ./programs/git.nix
    ./desktop/plasma.nix
  ];

  home.username = "user";
  home.homeDirectory = "/home/user";
  home.stateVersion = "24.11";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # User packages (in addition to system packages)
  home.packages = with pkgs; [
    # CLI tools
    eza           # Modern ls
    bat           # Better cat
    fd            # Better find
    ripgrep       # Better grep
    fzf           # Fuzzy finder
    zoxide        # Smarter cd
    duf           # Better df
    dust          # Better du
    procs         # Better ps
    bottom        # Better top/htop

    # Development
    lazygit
    gh            # GitHub CLI
    httpie        # Better curl for APIs

    # Media
    spotify
    obs-studio

    # Misc
    neofetch
    cmatrix
    sl
  ];

  # Environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "wezterm";
    BROWSER = "brave";
  };

  # XDG directories
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  # GTK theming (for non-KDE apps)
  gtk = {
    enable = true;
    theme = {
      name = "Breeze-Dark";
      package = pkgs.kdePackages.breeze-gtk;
    };
    iconTheme = {
      name = "Gruvbox-Plus-Dark";
      package = pkgs.gruvbox-plus-icons;
    };
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 10;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # Qt theming
  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };

  # Kvantum theme configuration
  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=MoeDark
  '';

  # Cursor theme
  home.pointerCursor = {
    name = "breeze_cursors";
    package = pkgs.kdePackages.breeze;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Services
  services.kdeconnect.enable = true;
}
