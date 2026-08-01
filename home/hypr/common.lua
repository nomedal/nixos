-- Shared Hyprland Lua config (both laptop and desktop)
-- Host-specific files (laptop.lua / desktop.lua) require() this.


-----------------------------
---- ENVIRONMENT VARIABLES --
-----------------------------

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("XCURSOR_THEME",                "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE",                 "24")
hl.env("QT_QPA_PLATFORMTHEME",         "kde")


----------------
---- AUTOSTART --
----------------

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemctl --user start hyprland-session.target")
end)


-- Mullvad, Signal, Vesktop, and MEGAsync all register a StatusNotifierItem
-- tray icon exactly once, at launch, with no retry. quickshell/DMS owns the
-- StatusNotifierWatcher these register against, and its own startup
-- (triggered above via hyprland-session.target) is not instant — on a cold
-- boot it can easily lose a race against a fixed-length delay. Confirmed
-- live: apps that lost the race end up with neither a window nor a tray
-- icon, unrecoverable short of restarting them. Wrap any tray-dependent
-- launch in this so it blocks until the watcher actually exists on the bus,
-- instead of guessing a timeout.
function wait_for_tray(cmd)
    return "sh -c 'while ! busctl --user list 2>/dev/null | grep -q org.kde.StatusNotifierWatcher; do sleep 0.2; done; exec " .. cmd .. "'"
end


-----------------
---- LOOK & FEEL
-----------------

hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = 5,
        border_size = 2,
        layout      = "dwindle",
    },

    decoration = {
        rounding         = 12,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled      = true,
            range        = 30,
            render_power = 5,
            offset       = "0 5",
            color        = "rgba(00000070)",
        },
        blur = {
            enabled           = true,
            size              = 8,
            passes            = 2,
            new_optimizations = true,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        mfact = 0.5,
    },

    misc = {
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
    },
})

hl.animation({ leaf = "windowsIn",   enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "fade",        enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "border",      enabled = true, speed = 3, bezier = "default" })


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout          = "no",
        numlock_by_default = true,
    },
})


---------------------
---- KEYBINDINGS ----
---------------------

local S = "SUPER"

-- Special workspace (scratchpad)
hl.bind(S .. " + S",       hl.dsp.window.move({ workspace = "special", follow = false }))
hl.bind(S .. " + SHIFT + S", hl.dsp.workspace.toggle_special())

-- Applications
hl.bind(S .. " + T",             hl.dsp.exec_cmd("wezterm"))
hl.bind(S .. " + space",         hl.dsp.exec_cmd("dms ipc call spotlight toggle"))
hl.bind(S .. " + V",             hl.dsp.exec_cmd("dms ipc call clipboard toggle"))
hl.bind(S .. " + M",             hl.dsp.exec_cmd("dms ipc call processlist focusOrToggle"))
hl.bind(S .. " + comma",         hl.dsp.exec_cmd("dms ipc call settings focusOrToggle"))
hl.bind(S .. " + N",             hl.dsp.exec_cmd("dms ipc call notifications toggle"))
hl.bind(S .. " + SHIFT + N",     hl.dsp.exec_cmd("dms ipc call notepad toggle"))
hl.bind(S .. " + Y",             hl.dsp.exec_cmd("dms ipc call dankdash wallpaper"))
hl.bind(S .. " + TAB",           hl.dsp.exec_cmd("dms ipc call hypr toggleOverview"))
hl.bind(S .. " + X",             hl.dsp.exec_cmd("dms ipc call powermenu toggle"))
hl.bind(S .. " + SHIFT + Slash", hl.dsp.exec_cmd("dms ipc call keybinds toggle hyprland"))
hl.bind(S .. " + ALT + L",       hl.dsp.exec_cmd("dms ipc call lock lock"))
hl.bind(S .. " + E",             hl.dsp.exec_cmd("dolphin"))
hl.bind(S .. " + SHIFT + E",     hl.dsp.exit())
hl.bind("CTRL + ALT + Delete",   hl.dsp.exec_cmd("dms ipc call processlist focusOrToggle"))

-- Window management
hl.bind(S .. " + Q",         hl.dsp.window.close())
hl.bind(S .. " + F",         hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(S .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(S .. " + SHIFT + T", hl.dsp.window.float())
hl.bind(S .. " + W",         hl.dsp.group.toggle())
hl.bind(S .. " + SHIFT + W", hl.dsp.exec_cmd("dms ipc call window-rules toggle"))

-- Focus
hl.bind(S .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(S .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(S .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(S .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(S .. " + H",     hl.dsp.focus({ direction = "left" }))
hl.bind(S .. " + J",     hl.dsp.focus({ direction = "down" }))
hl.bind(S .. " + K",     hl.dsp.focus({ direction = "up" }))
hl.bind(S .. " + L",     hl.dsp.focus({ direction = "right" }))

-- Move window (directional)
hl.bind(S .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(S .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))
hl.bind(S .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(S .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(S .. " + SHIFT + H",     hl.dsp.window.move({ direction = "left" }))
hl.bind(S .. " + SHIFT + J",     hl.dsp.window.move({ direction = "down" }))
hl.bind(S .. " + SHIFT + K",     hl.dsp.window.move({ direction = "up" }))
hl.bind(S .. " + SHIFT + L",     hl.dsp.window.move({ direction = "right" }))

-- Focus first/last window
hl.bind(S .. " + Home", hl.dsp.focus({ window = "first" }))
hl.bind(S .. " + End",  hl.dsp.focus({ window = "last" }))

-- Focus monitor
hl.bind(S .. " + CTRL + left",  hl.dsp.focus({ monitor = "left" }))
hl.bind(S .. " + CTRL + right", hl.dsp.focus({ monitor = "right" }))
hl.bind(S .. " + CTRL + H",     hl.dsp.focus({ monitor = "left" }))
hl.bind(S .. " + CTRL + J",     hl.dsp.focus({ monitor = "down" }))
hl.bind(S .. " + CTRL + K",     hl.dsp.focus({ monitor = "up" }))
hl.bind(S .. " + CTRL + L",     hl.dsp.focus({ monitor = "right" }))

-- Move window to monitor
hl.bind(S .. " + SHIFT + CTRL + left",  hl.dsp.window.move({ monitor = "left" }))
hl.bind(S .. " + SHIFT + CTRL + down",  hl.dsp.window.move({ monitor = "down" }))
hl.bind(S .. " + SHIFT + CTRL + up",    hl.dsp.window.move({ monitor = "up" }))
hl.bind(S .. " + SHIFT + CTRL + right", hl.dsp.window.move({ monitor = "right" }))
hl.bind(S .. " + SHIFT + CTRL + H",     hl.dsp.window.move({ monitor = "left" }))
hl.bind(S .. " + SHIFT + CTRL + J",     hl.dsp.window.move({ monitor = "down" }))
hl.bind(S .. " + SHIFT + CTRL + K",     hl.dsp.window.move({ monitor = "up" }))
hl.bind(S .. " + SHIFT + CTRL + L",     hl.dsp.window.move({ monitor = "right" }))

-- Workspace navigation
hl.bind(S .. " + Page_Down",       hl.dsp.focus({ workspace = "e+1" }))
hl.bind(S .. " + Page_Up",         hl.dsp.focus({ workspace = "e-1" }))
hl.bind(S .. " + U",               hl.dsp.focus({ workspace = "e+1" }))
hl.bind(S .. " + I",               hl.dsp.focus({ workspace = "e-1" }))
hl.bind(S .. " + CTRL + down",     hl.dsp.window.move({ workspace = "e+1" }))
hl.bind(S .. " + CTRL + up",       hl.dsp.window.move({ workspace = "e-1" }))
hl.bind(S .. " + CTRL + U",        hl.dsp.window.move({ workspace = "e+1" }))
hl.bind(S .. " + CTRL + I",        hl.dsp.window.move({ workspace = "e-1" }))
hl.bind(S .. " + SHIFT + Page_Down", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind(S .. " + SHIFT + Page_Up",   hl.dsp.window.move({ workspace = "e-1" }))
hl.bind(S .. " + SHIFT + U",         hl.dsp.window.move({ workspace = "e+1" }))
hl.bind(S .. " + SHIFT + I",         hl.dsp.window.move({ workspace = "e-1" }))

hl.bind(S .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(S .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(S .. " + CTRL + mouse_down", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind(S .. " + CTRL + mouse_up",   hl.dsp.window.move({ workspace = "e-1" }))

for i = 1, 9 do
    hl.bind(S .. " + " .. i,             hl.dsp.focus({ workspace = i }))
    hl.bind(S .. " + SHIFT + " .. i,     hl.dsp.window.move({ workspace = i }))
end

-- Layout
hl.bind(S .. " + R", hl.dsp.layout("togglesplit"))

-- Workspace rename (via DMS IPC)
hl.bind("CTRL + SHIFT + R", hl.dsp.exec_cmd("dms ipc call workspace-rename open"))

-- Resize (repeating)
hl.bind(S .. " + minus",         hl.dsp.exec_cmd("hyprctl dispatch resizeactive -10% 0"),  { repeating = true })
hl.bind(S .. " + equal",         hl.dsp.exec_cmd("hyprctl dispatch resizeactive 10% 0"),   { repeating = true })
hl.bind(S .. " + SHIFT + minus", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -10%"),  { repeating = true })
hl.bind(S .. " + SHIFT + equal", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 10%"),   { repeating = true })

-- Resize by 100px via keycode (=/-) — bindd equivalent, description dropped
hl.bind(S .. " + code:20", hl.dsp.exec_cmd("hyprctl dispatch resizeactive -100 0"))
hl.bind(S .. " + code:21", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 100 0"))

-- Mouse drag/resize
hl.bind(S .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(S .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Screenshots
hl.bind("Print",             hl.dsp.exec_cmd("dms screenshot"))
hl.bind("CTRL + Print",      hl.dsp.exec_cmd("dms screenshot full"))
hl.bind("ALT + Print",       hl.dsp.exec_cmd("dms screenshot window"))

-- Display power
hl.bind(S .. " + SHIFT + P", hl.dsp.dpms({ state = "toggle" }))

-- Audio (locked + repeating)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("dms ipc call audio increment 3"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("dms ipc call audio decrement 3"), { locked = true, repeating = true })
hl.bind("CTRL + XF86AudioRaiseVolume", hl.dsp.exec_cmd("dms ipc call mpris increment 3"), { locked = true, repeating = true })
hl.bind("CTRL + XF86AudioLowerVolume", hl.dsp.exec_cmd("dms ipc call mpris decrement 3"), { locked = true, repeating = true })

-- Audio (locked)
hl.bind("XF86AudioMute",    hl.dsp.exec_cmd("dms ipc call audio mute"),       { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("dms ipc call audio micmute"),    { locked = true })
hl.bind("XF86AudioPause",   hl.dsp.exec_cmd("dms ipc call mpris playPause"),  { locked = true })
hl.bind("XF86AudioPlay",    hl.dsp.exec_cmd("dms ipc call mpris playPause"),  { locked = true })
hl.bind("XF86AudioPrev",    hl.dsp.exec_cmd("dms ipc call mpris previous"),   { locked = true })
hl.bind("XF86AudioNext",    hl.dsp.exec_cmd("dms ipc call mpris next"),       { locked = true })

-- Power management from lock screen (keyboard shortcuts; mouse clicks via hyprlock onclick)
hl.bind("SUPER + CTRL + r", hl.dsp.exec_cmd("systemctl reboot"),          { locked = true })
hl.bind("SUPER + CTRL + p", hl.dsp.exec_cmd("systemctl poweroff"),        { locked = true })
hl.bind("SUPER + CTRL + h", hl.dsp.exec_cmd("systemctl hibernate"),       { locked = true })
hl.bind("SUPER + CTRL + z", hl.dsp.exec_cmd("systemctl suspend"),         { locked = true })
hl.bind("SUPER + CTRL + q", hl.dsp.exec_cmd("hyprctl dispatch exit 0"),   { locked = true })


----------------------------
---- WINDOW & LAYER RULES --
----------------------------

hl.window_rule({ name = "tile-wezterm",       match = { class = "^org\\.wezfurlong\\.wezterm$" }, float = false })
hl.window_rule({ name = "round-gnome",        match = { class = "^org\\.gnome\\." },              rounding = 12 })
hl.window_rule({ name = "tile-gnome-cc",      match = { class = "^gnome-control-center$" },       float = false })
hl.window_rule({ name = "tile-pavucontrol",   match = { class = "^pavucontrol$" },                float = false })
hl.window_rule({ name = "tile-nm-editor",     match = { class = "^nm-connection-editor$" },       float = false })
hl.window_rule({ name = "float-gcalculator",  match = { class = "^org\\.gnome\\.Calculator$" },   float = true })
hl.window_rule({ name = "float-gnome-calc",   match = { class = "^gnome-calculator$" },           float = true })
hl.window_rule({ name = "float-galculator",   match = { class = "^galculator$" },                 float = true })
hl.window_rule({ name = "float-blueman",      match = { class = "^blueman-manager$" },            float = true })
hl.window_rule({ name = "float-nautilus",     match = { class = "^org\\.gnome\\.Nautilus$" },     float = true })
hl.window_rule({ name = "float-xdg-portal",  match = { class = "^xdg-desktop-portal$" },         float = true })
hl.window_rule({ name = "float-firefox-pip", match = { class = "^firefox$", title = "^Picture-in-Picture$" }, float = true })
hl.window_rule({ name = "float-zoom",        match = { class = "^zoom$" },                        float = true })

hl.window_rule({
    name  = "steam-toast-no-focus",
    match = { class = "^steam$", title = "^notificationtoasts" },
    no_initial_focus = true,
    pin = true,
})

-- EasyEffects is launched headless via `--hide-window --service-mode`
-- (systemd.user.services.easyeffects, home/profiles/contexts/workstation) —
-- its own supported way to start hidden-with-tray. No window ever opens at
-- startup, so there's no window_rule/hook needed here. Do NOT force-close its
-- window if one ever appears (e.g. via clicking the tray icon) — that would
-- make the tray icon useless for reopening the UI. (Also note: its window
-- class changed upstream from the old GTK com.github.wwmm.easyeffects to
-- org.kde.easyeffects, Kirigami/QML rewrite — irrelevant now but easy to trip
-- over if a class-matched rule is ever added back for it.)

hl.layer_rule({ name = "no-anim-quickshell", match = { namespace = "^quickshell$" }, no_anim = true })
hl.layer_rule({ name = "no-anim-dms",        match = { namespace = "^dms:.*" },      no_anim = true })
