-- -------------------------------------------------------------------------------------
-- 5. PLUGINS
-- -------------------------------------------------------------------------------------

-- NOTE: Plugin Lua config support depends on the plugin author updating for 0.55+.
-- If hyprfocus doesn't support Lua config yet, this section may need to stay as
-- a separate hyprlang snippet or wait for the plugin update.

hl.config({
    plugin = {
        hyprfocus = {
            enabled                 = true,
            animate_floating        = false,
            animate_workspacechange = false,
            focus_animation         = "shrink",
        },
    },
})

-- Plugin-specific bezier curves
hl.curve("overshot",       { type = "bezier", points = { {0.05, 0.9},  {0.1, 1.05}   } })
hl.curve("smoothOut",      { type = "bezier", points = { {0.36, 0},    {0.66, -0.56}  } })
hl.curve("smoothIn",       { type = "bezier", points = { {0.25, 1},    {0.5, 1}       } })
hl.curve("realsmooth",     { type = "bezier", points = { {0.28, 0.29}, {0.69, 1.08}   } })
hl.curve("easeInOutBack",  { type = "bezier", points = { {0.68, -0.6}, {0.32, 1.6}    } })

-- NOTE: shrink sub-config (in_bezier, in_speed, out_bezier, out_speed) may need
-- to be nested under plugin.hyprfocus.shrink — exact Lua structure TBD per plugin docs
