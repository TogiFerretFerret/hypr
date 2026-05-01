-- -------------------------------------------------------------------------------------
-- 7. RULES
-- -------------------------------------------------------------------------------------

-- Portal rules
hl.window_rule({
    name  = "float-portal-gtk",
    match = { class = "^(xdg%-desktop%-portal%-gtk)$" },
    float = true,
})

-- Ignore maximize requests
hl.window_rule({
    name  = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Zathura xray
hl.window_rule({
    name  = "zathura-xray",
    match = { class = "^(org%.pwmt%.zathura)$" },
    xray  = 0,
})

-- Glass Effect
hl.window_rule({
    name    = "glass-arianna",
    match   = { class = "^(org%.kde%.arianna)$" },
    opacity = { active = 0.85, inactive = 0.85 },
})

hl.window_rule({
    name    = "glass-nautilus",
    match   = { class = "^(org%.gnome%.Nautilus)$" },
    opacity = { active = 0.78 },
})
