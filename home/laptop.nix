{ nome, ... }: {
  imports = nome.lib.mkHome {
    context  = "workstation";
    identity = "private";
    sets     = [ "coding" "hardware" "media" ];
  };

  wayland.windowManager.hyprland.extraConfig =
    builtins.readFile ./hypr/laptop.lua;
}
