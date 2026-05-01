-- =====================================================================================
--                                  RIVER'S HYPRLAND
--                                  EVA-00 // ASAHI
-- =====================================================================================

-- Shared variables (used across modules)
MainMod     = "SUPER"
Terminal    = "ghostty"
FileManager = "nautilus --new-window"
Menu        = "rofi -show drun"

-- 1. Hardware & Monitors
require("modules.hardware")

-- 2. Environment Variables
require("modules.envvars")

-- 3. Autostart
require("modules.autostart")

-- 4. Look and Feel
require("modules.graphics")

-- 5. Plugins
require("modules.plugins")

-- 6. Keybindings
require("modules.binds")

-- 7. Rules
require("modules.rules")
