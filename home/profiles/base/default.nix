{ pkgs, ... }: {
  imports = [ ../../programs/zsh.nix ];

  home.stateVersion = "26.05";
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    bat
    fd
    ripgrep
    fzf
    zoxide
    duf
    dust
    procs
    bottom
    libqalculate
  ];
}
