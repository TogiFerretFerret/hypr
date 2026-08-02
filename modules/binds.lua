-- -------------------------------------------------------------------------------------
-- 6. KEYBINDINGS
-- -------------------------------------------------------------------------------------

local mainMod = MainMod

-- ── Core ──
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(Terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("ghostty -e yazi ~"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(Menu))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))

-- ── Clipboard (quickshell) — uses global shortcut ──
hl.bind(mainMod .. " + V", hl.dsp.global("quickshell:clipboard"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("rofi -modi emoji -show emoji"))

-- ── Random Useful Binds ──
hl.bind("ALT + SHIFT + S", hl.dsp.exec_cmd("/home/river/go/bin/spofi"))
hl.bind("ALT + SHIFT + D", hl.dsp.global("quickshell:notif-dnd"))
hl.bind("ALT + SHIFT + E", hl.dsp.global("quickshell:notif-dismiss"))
hl.bind("ALT + SHIFT + C", hl.dsp.global("quickshell:notif-clear"))
hl.bind("CTRL + SHIFT + 5", hl.dsp.exec_cmd("hyprshot --mode region"))

-- ── Pseudotiling / Dwindle ──
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- ── Movement: Resize ──
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { locked = true, repeating = true })
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.resize({ x = 0, y = 30, relative = true }),  { locked = true, repeating = true })
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { locked = true, repeating = true })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.resize({ x = 30, y = 0, relative = true }),  { locked = true, repeating = true })

-- ── Movement: Mouse ──
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ── Keyboard Mouse Emulation (warpd) ──
hl.bind(mainMod .. " + G",         hl.dsp.exec_cmd("/home/river/.local/bin/warpd --grid"))
hl.bind(mainMod .. " + X",         hl.dsp.exec_cmd("/home/river/.local/bin/warpd --hint"))
hl.bind(mainMod .. " + Z",         hl.dsp.exec_cmd("/home/river/.local/bin/warpd --normal"))
hl.bind("CTRL + SHIFT + 4",        hl.dsp.exec_cmd("/home/river/.local/bin/warpd --screenshot"))

-- ── Mouse movement submap (CTRL+SPACE to enter, ESC/CTRL+SPACE to exit) ──
hl.bind("CTRL + SPACE", hl.dsp.submap("mousemove"))

hl.define_submap("mousemove", "escape", function()
    hl.bind("CTRL + SPACE",  hl.dsp.submap("reset"))
    hl.bind("H", hl.dsp.exec_cmd("ydotool mousemove -- -20 0"), { repeating = true })
    hl.bind("J", hl.dsp.exec_cmd("ydotool mousemove -- 0 20"),  { repeating = true })
    hl.bind("K", hl.dsp.exec_cmd("ydotool mousemove -- 0 -20"), { repeating = true })
    hl.bind("L", hl.dsp.exec_cmd("ydotool mousemove -- 20 0"),  { repeating = true })
    hl.bind("SHIFT + H", hl.dsp.exec_cmd("ydotool mousemove -- -5 0"), { repeating = true })
    hl.bind("SHIFT + J", hl.dsp.exec_cmd("ydotool mousemove -- 0 5"),  { repeating = true })
    hl.bind("SHIFT + K", hl.dsp.exec_cmd("ydotool mousemove -- 0 -5"), { repeating = true })
    hl.bind("SHIFT + L", hl.dsp.exec_cmd("ydotool mousemove -- 5 0"),  { repeating = true })
    hl.bind("M", hl.dsp.exec_cmd("ydotool click 0xC0"))
end)


-- ── Movement: Move Window (keycodes for [ and ]) ──
hl.bind(mainMod .. " + code:34",           hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + code:35",           hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + code:34",   hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + code:35",   hl.dsp.window.move({ direction = "d" }))

-- ── Movement: Focus ──
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- ── Workspaces ──
for i = 1, 10 do
    local key = i % 10
    -- Switch to workspace
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i }))
    -- Move window silently (stay on current workspace)
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i, follow = false }))
    -- Move window AND switch
    hl.bind("ALT + SHIFT + " .. key,             hl.dsp.window.move({ workspace = i, follow = true }))
end
-- NOTE: movetoworkspacesilent { silent = true } is inferred — verify on 0.55

-- ── Special Workspaces ──
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + M",         hl.dsp.workspace.toggle_special("music"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.window.move({ workspace = "special:music" }))

hl.bind(mainMod .. " + D",         hl.dsp.workspace.toggle_special("chat"))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.window.move({ workspace = "special:chat" }))

-- ── Wallpaper ──
hl.bind(mainMod .. " + W",         hl.dsp.global("quickshell:wallpaper"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/wallpaper.sh"))

-- ── Karaoke mode ──
hl.bind(mainMod .. " + K", hl.dsp.global("quickshell:karaoke"))

-- ── VPN picker ──
hl.bind(mainMod .. " + N", hl.dsp.global("quickshell:vpn"))

-- ── Multimedia ──
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),               { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),                     { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("bash /home/river/.config/hypr/scripts/mute.sh"),                 { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),                 { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                                { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                                { locked = true, repeating = true })
hl.bind("XF86LaunchA",           hl.dsp.exec_cmd("bash /home/river/.config/hypr/scripts/backlight.sh"),            { locked = true, repeating = true })
hl.bind("XF86Search",            hl.dsp.exec_cmd("/home/river/go/bin/spofi"))

-- Playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
