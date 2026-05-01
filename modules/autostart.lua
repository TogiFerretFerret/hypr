-- -------------------------------------------------------------------------------------
-- 3. AUTOSTART
-- -------------------------------------------------------------------------------------

hl.on("hyprland.start", function()
    -- Core Services
    hl.exec_cmd("hyprpm reload")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("fcitx5 &")
    hl.exec_cmd("wl-paste --watch clipvault store")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")

    -- UI Elements
    hl.exec_cmd("quickshell &")
    hl.exec_cmd("GDK_DPI_SCALE=0.85 swaync &")

    -- Wallpaper with swww (color-synced)
    hl.exec_cmd("swww-daemon &")
    hl.exec_cmd("sleep 1 && ~/.config/hypr/scripts/wallpaper.sh ~/Pictures/Wallpapers/lakeside-dock-flowers.png")

    -- Visual Fixes
    hl.exec_cmd("hyprctl setcursor Bibata-Hyprland 24")
end)

-- Safety Net (Prevents SDDM hanging on logout)
-- NOTE: exec-shutdown event name unconfirmed — may need hl.on("hyprland.shutdown", ...)
-- Fallback: create a systemd unit if this doesn't work
hl.on("hyprland.shutdown", function()
    hl.exec_cmd("sudo systemctl restart sddm")
end)
