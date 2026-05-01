-- -------------------------------------------------------------------------------------
-- 1. HARDWARE & MONITORS
-- -------------------------------------------------------------------------------------

-- Asahi MacBook Screen scaling
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1.33333334,
})

-- Input
hl.config({
    input = {
        kb_layout  = "us",
        kb_options = "caps:escape",
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
})

-- Lock screen on lid close
-- NOTE: Switch bind syntax is unconfirmed for Lua — may need adjustment on 0.55
hl.bind("switch:on:Apple SMC power/lid events", hl.dsp.exec_cmd("~/.config/hypr/scripts/lock.sh"), { locked = true })
