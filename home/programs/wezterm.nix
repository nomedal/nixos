{ config, pkgs, lib, ... }:

{
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local wezterm = require 'wezterm'
      local config = wezterm.config_builder()

      -- Font configuration
      config.font = wezterm.font_with_fallback {
        'JetBrainsMono Nerd Font',
        'Noto Color Emoji',
      }
      config.font_size = 11.0

      -- Color scheme (Gruvbox Dark to match your theme)
      config.color_scheme = 'Gruvbox dark, medium (base16)'

      -- Window appearance
      config.window_background_opacity = 0.92
      config.window_decorations = "RESIZE"
      config.window_padding = {
        left = 10,
        right = 10,
        top = 10,
        bottom = 10,
      }

      -- Tab bar
      config.hide_tab_bar_if_only_one_tab = true
      config.tab_bar_at_bottom = true
      config.use_fancy_tab_bar = false

      -- Cursor
      config.default_cursor_style = 'SteadyBlock'
      config.cursor_blink_rate = 500

      -- Bell
      config.audible_bell = "Disabled"
      config.visual_bell = {
        fade_in_duration_ms = 75,
        fade_out_duration_ms = 75,
        target = 'CursorColor',
      }

      -- Scrollback
      config.scrollback_lines = 10000

      -- Keybindings
      config.keys = {
        -- Split panes
        { key = 'd', mods = 'CTRL|SHIFT', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
        { key = 'e', mods = 'CTRL|SHIFT', action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' } },

        -- Navigate panes
        { key = 'h', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Left' },
        { key = 'l', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Right' },
        { key = 'k', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Up' },
        { key = 'j', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Down' },

        -- Close pane
        { key = 'w', mods = 'CTRL|SHIFT', action = wezterm.action.CloseCurrentPane { confirm = true } },
      }

      -- GPU acceleration
      config.front_end = "WebGpu"
      config.webgpu_power_preference = "HighPerformance"

      return config
    '';
  };
}
