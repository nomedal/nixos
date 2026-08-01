{ nome, ... }: {
  imports = nome.lib.mkHome {
    context  = "workstation";
    identity = "private";
    sets     = [ "coding" "hardware" "media" ];
  };

  home.file.".config/gtk-3.0/bookmarks".text = ''
    file:///mnt/4TB-HDD0 4TB-HDD0
    file:///mnt/4TB-HDD1 4TB-HDD1
  '';

  wayland.windowManager.hyprland.extraConfig =
    builtins.readFile ./hypr/desktop.lua;

  home.file.".local/bin/hypr-monitor-watch" = {
    source = ../scripts/hypr-monitor-watch;
    executable = true;
  };

  systemd.user.services.hypr-monitor-watch = {
    Unit = {
      Description = "Reload Hyprland config on monitor reconnect";
      After = [ "hyprland-session.target" ];
      BindsTo = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "%h/.local/bin/hypr-monitor-watch";
      Restart = "on-failure";
      RestartSec = "2";
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };

  xdg.configFile."easyeffects/output/990DT.json".source =
    ../configs/990DT.json;
  xdg.configFile."easyeffects/input/SM58-Disco.json".source =
    ../configs/SM58-Disco.json;
}
