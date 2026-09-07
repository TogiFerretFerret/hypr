-- -------------------------------------------------------------------------------------
-- 1. HARDWARE & MONITORS
-- -------------------------------------------------------------------------------------

-- eDP-1: Built-in MacBook Screen scaling
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "0x0",
    scale    = 1.33333334,
})

-- DP-1: External LG Ultrawide Screen scaling (scaled at 1x)
hl.monitor({
    output   = "DP-1",
    mode     = "preferred",
    position = "1920x0", -- Placed to the right of eDP-1 (2560 width / 1.33333334 scale = 1920 logical pixels)
    scale    = 1.0,
})

-- Input
hl.config({
    input = {
        kb_layout  = "us",
        kb_options = "caps:escape",
        follow_mouse = 1,
		repeat_rate = 50,
        sensitivity  = 0,
        touchpad = {
            natural_scroll = false,
			disable_while_typing = true,
        },
    },
})

-- Flat accel profile for mouse & tablet
hl.device({
    name          = "razer-razer-viper-v3-hyperspeed-2",
    accel_profile = "flat",
})
hl.device({
    name          = "razer-razer-viper-v3-hyperspeed-3",
    accel_profile = "flat",
})
hl.device({
    name          = "opentabletdriver-virtual-tablet",
    accel_profile = "flat",
})
hl.device({
    name          = "wacom-co.-ltd.-ctl-472-mouse",
    accel_profile = "flat",
})

-- Lock screen on lid close
-- NOTE: Switch bind syntax is unconfirmed for Lua — may need adjustment on 0.55
hl.bind("switch:on:Apple SMC power/lid events", hl.dsp.exec_cmd("~/.config/hypr/scripts/lock.sh"), { locked = true })
