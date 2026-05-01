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

-- ── Clipvault ──
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("clipvault list | rofi -dmenu -display-columns 2 -theme ~/.config/rofi/clipboard.rasi -eh 2 | clipvault get | wl-copy"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("rofi -modi emoji -show emoji"))

-- ── Random Useful Binds ──
hl.bind("ALT + SHIFT + S", hl.dsp.exec_cmd("/home/river/go/bin/spofi"))
hl.bind("ALT + SHIFT + D", hl.dsp.exec_cmd("swaync-client --toggle-dnd"))
hl.bind("ALT + SHIFT + E", hl.dsp.exec_cmd("swaync-client --close-latest"))
hl.bind("ALT + SHIFT + C", hl.dsp.exec_cmd("swaync-client --close-all"))
hl.bind("CTRL + SHIFT + 5", hl.dsp.exec_cmd("hyprshot --mode region"))

-- ── Pseudotiling / Dwindle ──
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- ── Movement: Resize ──
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.exec_cmd("hyprctl dispatch resizeactive -30 0"), { locked = true, repeating = true })
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 30"),  { locked = true, repeating = true })
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -30"), { locked = true, repeating = true })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 30 0"),  { locked = true, repeating = true })
-- NOTE: resizeactive may have a proper hl.dsp.window.resize() form — using hyprctl fallback for now

-- ── Movement: Mouse ──
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ── Movement: Move Window (keycodes for [ and ]) ──
hl.bind(mainMod .. " + code:34",           hl.dsp.exec_cmd("hyprctl dispatch movewindow l"))
hl.bind(mainMod .. " + code:35",           hl.dsp.exec_cmd("hyprctl dispatch movewindow r"))
hl.bind(mainMod .. " + SHIFT + code:34",   hl.dsp.exec_cmd("hyprctl dispatch movewindow u"))
hl.bind(mainMod .. " + SHIFT + code:35",   hl.dsp.exec_cmd("hyprctl dispatch movewindow d"))
-- NOTE: may have a proper hl.dsp.window.move({ direction = "l" }) form

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
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i, silent = true }))
    -- Move window AND switch
    hl.bind("ALT + SHIFT + " .. key,             hl.dsp.window.move({ workspace = i }))
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
hl.bind(mainMod .. " + W",         hl.dsp.exec_cmd("touch /tmp/qs-wallpaper-picker"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/wallpaper.sh"))

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
