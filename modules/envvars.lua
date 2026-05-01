-- -------------------------------------------------------------------------------------
-- 2. ENVIRONMENT VARIABLES
-- -------------------------------------------------------------------------------------

-- Cursors
hl.env("XCURSOR_THEME", "Bibata-Hyprland")
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_PATH", "~/.local/share/icons/")

-- Input Method (Fcitx5)
hl.env("GTK_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")

-- Theming (QT5 gets qt5ct, QT6/QML gets forced Desktop Style)
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("QT_QUICK_CONTROLS_STYLE", "org.kde.desktop")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
