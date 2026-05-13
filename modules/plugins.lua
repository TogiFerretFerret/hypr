-- -------------------------------------------------------------------------------------
-- 5. PLUGINS
-- -------------------------------------------------------------------------------------

hl.config({
    plugin = {
        hyprfocus = {
            mode                   = "bounce",
            only_on_monitor_change = false,
            fade_opacity           = 0.8,
            bounce_strength        = 0.98,
            slide_height           = 20,
        },
    },
})

-- Hyprfocus animations
hl.animation({ leaf = "hyprfocusIn",  enabled = true, speed = 1.5, bezier = "easeInOutBack" })
hl.animation({ leaf = "hyprfocusOut", enabled = true, speed = 3,   bezier = "easeInOutBack" })

-- Plugin-specific bezier curves
hl.curve("overshot",       { type = "bezier", points = { {0.05, 0.9},  {0.1, 1.05}   } })
hl.curve("smoothOut",      { type = "bezier", points = { {0.36, 0},    {0.66, -0.56}  } })
hl.curve("smoothIn",       { type = "bezier", points = { {0.25, 1},    {0.5, 1}       } })
hl.curve("realsmooth",     { type = "bezier", points = { {0.28, 0.29}, {0.69, 1.08}   } })
hl.curve("easeInOutBack",  { type = "bezier", points = { {0.68, -0.6}, {0.32, 1.6}    } })
