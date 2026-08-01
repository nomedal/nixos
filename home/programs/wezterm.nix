{ config, pkgs, lib, inputs, ... }:

{
  programs.wezterm.enable = true;

  home.file.".wezterm.lua".source = "${inputs.dotfiles}/wezterm/wezterm.lua";
}
