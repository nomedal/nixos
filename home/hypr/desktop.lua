-- Desktop (RTX 3070) Hyprland config

local hypr_dir = os.getenv("HOME") .. "/.config/hypr"
package.path = package.path .. ";" .. hypr_dir .. "/?.lua"
require("common")


----------------
---- MONITORS --
----------------

hl.monitor({ output = "desc:Microstep MAG322CQRV DA4A019430451", mode = "2560x1440@144", position = "0x1",     scale = 1 })  -- MSI MAG322CQRV (center/main)
hl.monitor({ output = "desc:BNQ BenQ RL2455 V3D00100SL0",       mode = "1920x1080@60",  position = "-1920x181", scale = 1 })  -- BenQ RL2455 (left)
hl.monitor({ output = "desc:BNQ BenQ G2420HD 84B01343SL0",      mode = "1920x1080@60",  position = "2560x181",  scale = 1 })  -- BenQ G2420HD (right)


---------------------------------
---- WORKSPACE-TO-MONITOR PINS --
---------------------------------

-- Pin workspaces to monitors by desc: so layout survives port/cable swaps
-- default = true claims the workspace as that monitor's initial one at Hyprland
-- startup — without it each monitor auto-grabs the next free sequential
-- workspace, and reassigning it later just orphans a new one (4, 5, 6, ...)
-- on whichever monitor lost its auto-assigned workspace.
hl.workspace_rule({ workspace = "1", monitor = "desc:Microstep MAG322CQRV DA4A019430451", default = true })  -- middle
hl.workspace_rule({ workspace = "2", monitor = "desc:BNQ BenQ RL2455 V3D00100SL0",       default = true })  -- left
hl.workspace_rule({ workspace = "3", monitor = "desc:BNQ BenQ G2420HD 84B01343SL0",      default = true })  -- right


-- Vesktop's exec-rule workspace target ("2 silent" below) isn't reliably
-- honored — it's been observed landing on whatever workspace happens to be
-- active at launch instead. A window_rule is evaluated directly by Hyprland's
-- Lua config load, not through the exec-bracket mechanism, so it pins
-- placement reliably regardless of what's focused when it launches.
hl.window_rule({ name = "workspace-vesktop", match = { class = "^vesktop$" }, workspace = "2 silent" })


-------------------------
---- AUTOSTART (desktop) --
-------------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("wezterm", { workspace = "3 silent" })

    -- Vesktop, Mullvad, Signal, and MEGAsync all register a tray icon at
    -- launch with no retry — wait_for_tray() (common.lua) blocks each one
    -- until quickshell/DMS's StatusNotifierWatcher actually exists on the
    -- bus, rather than guessing a fixed delay (a 2.5s timer still lost the
    -- race on a real cold boot). Mullvad and Signal rely on their own
    -- persisted "start minimized to tray" settings (live app config, not
    -- Nix-managed: ~/.config/Mullvad VPN/gui_settings.json:startMinimized,
    -- ~/.config/Signal/ephemeral.json:system-tray-setting) to start hidden;
    -- MEGAsync is sent straight to the scratchpad since it always opens a
    -- window regardless of its own settings.
    hl.exec_cmd(wait_for_tray("vesktop"),       { workspace = "2 silent" })
    hl.exec_cmd(wait_for_tray("mullvad-vpn"),   { workspace = "special silent" })
    hl.exec_cmd(wait_for_tray("signal-desktop"),{ workspace = "2 silent" })
    hl.exec_cmd(wait_for_tray("megasync"),      { workspace = "special silent" })

    -- workspace_rule's default = true doesn't reliably win the race for which
    -- workspace is *active* on each monitor at boot — force it explicitly.
    -- End on 1 (middle/main monitor) so keyboard focus lands there.
    hl.dispatch(hl.dsp.focus({ workspace = 2 }))
    hl.dispatch(hl.dsp.focus({ workspace = 3 }))
    hl.dispatch(hl.dsp.focus({ workspace = 1 }))
end)
