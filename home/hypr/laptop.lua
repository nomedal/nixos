-- Laptop (Intel Arc) Hyprland config

local hypr_dir = os.getenv("HOME") .. "/.config/hypr"
package.path = package.path .. ";" .. hypr_dir .. "/?.lua"
require("common")


----------------
---- MONITORS --
----------------

-- Built-in display — verify connector with: hyprctl monitors
-- If not eDP-1, change to match (common alternatives: eDP-2, LVDS-1)
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })
hl.monitor({ output = "",      mode = "preferred", position = "auto", scale = 1 })  -- fallback external


-------------------------------------
---- LAPTOP-ONLY KEYS (brightness) --
-------------------------------------

hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("dms ipc call brightness increment 5 \"\""), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("dms ipc call brightness decrement 5 \"\""), { locked = true, repeating = true })


-------------------------
---- AUTOSTART (laptop) --
-------------------------

hl.on("hyprland.start", function()
    hl.exec_cmd(wait_for_tray("mullvad-vpn"), { workspace = "special silent" })
end)
