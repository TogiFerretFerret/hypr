#!/usr/bin/env python3
import json
import os
import re

# Paths
CACHE_FILE = os.path.expanduser("~/.cache/wal/colors.json")
FF_DIR = os.path.expanduser("~/.config/fastfetch")
TEMPLATES = ["config.jsonc.template", "wide.jsonc.template"]

def hex_to_rgb_ansi(hex_color):
    hex_color = hex_color.lstrip('#')
    if len(hex_color) == 6:
        r = int(hex_color[0:2], 16)
        g = int(hex_color[2:4], 16)
        b = int(hex_color[4:6], 16)
        return f"\\u001b[38;2;{r};{g};{b}m"
    return ""

def main():
    if not os.path.exists(CACHE_FILE):
        return

    with open(CACHE_FILE, "r") as f:
        wal = json.load(f)

    colors = wal.get("colors", {})
    special = wal.get("special", {})

    # Map fastfetch template tokens to ANSI RGB escapes
    # {#35}  = Primary borders (Magenta in template) -> mapped to color5
    # {#36}  = Secondary borders (Cyan in template) -> mapped to color4
    # {#37}  = Main text (White in template) -> mapped to foreground
    # {#@37} = Dim borders (Bright Black in template) -> mapped to color8
    # {#@46} = MAGI ASCII / Accents (Bright Cyan in template) -> mapped to color6
    # {#@220}= Warning text (Yellow in template) -> mapped to color3
    # {#@35} = Secret text (Greenish in template) -> mapped to color1
    # {#@45} = UI elements (Blue in template) -> mapped to color2
    
    replacements = {
        "{#35}": hex_to_rgb_ansi(colors.get("color5", "#ff00ff")),
        "{#36}": hex_to_rgb_ansi(colors.get("color4", "#00ffff")),
        "{#37}": hex_to_rgb_ansi(special.get("foreground", "#ffffff")),
        "{#@37}": hex_to_rgb_ansi(colors.get("color8", "#888888")),
        "{#@46}": hex_to_rgb_ansi(colors.get("color6", "#00ffff")),
        "{#@220}": hex_to_rgb_ansi(colors.get("color3", "#ffff00")),
        "{#@35}": hex_to_rgb_ansi(colors.get("color1", "#ff0000")),
        "{#@45}": hex_to_rgb_ansi(colors.get("color2", "#00ff00")),
        # Reset color code
        "{#0}": "\\u001b[0m"
    }

    for tpl in TEMPLATES:
        tpl_path = os.path.join(FF_DIR, tpl)
        out_path = os.path.join(FF_DIR, tpl.replace(".template", ""))
        
        if not os.path.exists(tpl_path):
            continue
            
        with open(tpl_path, "r") as f:
            content = f.read()
            
        for key, value in replacements.items():
            content = content.replace(key, value)
            
        with open(out_path, "w") as f:
            f.write(content)

if __name__ == "__main__":
    main()
