#!/usr/bin/env bash
# Watches for wallpaper changes (from any source) and syncs colors
# Polls swww every 2 seconds for current wallpaper

COLORS_JSON="$HOME/.cache/wal/colors.json"
LAST=""

while true; do
    CURRENT=$(swww query 2>/dev/null | grep -oP 'image: \K.*')

    if [ -n "$CURRENT" ] && [ "$CURRENT" != "$LAST" ]; then
        LAST="$CURRENT"
        echo "[color-daemon] Wallpaper changed: $(basename "$CURRENT")"

        # Save current
        echo "$CURRENT" > "$HOME/.cache/wallpaper-colors/current"

        # Run matugen
        MATUGEN_JSON=$(matugen -t scheme-content image "$CURRENT" --json hex --prefer saturation 2>/dev/null)

        if [ -n "$MATUGEN_JSON" ]; then
            python3 -c "
import re, json

raw = '''$MATUGEN_JSON'''

colors = {}
for m in re.finditer(r'\"(\w+)\":\s*\{[^}]*\"dark\":\s*\{[^}]*\"color\":\s*\"(#[0-9a-fA-F]{6})\"', raw):
    colors[m.group(1)] = m.group(2)

palette = {
    'special': {
        'background': colors.get('surface', '#111318'),
        'foreground': colors.get('on_surface', '#e1e2e9'),
        'cursor': colors.get('on_surface', '#e1e2e9'),
    },
    'colors': {
        'color0': colors.get('surface', '#111318'),
        'color1': colors.get('primary_container', '#5093e3'),
        'color2': colors.get('secondary_container', '#3c4758'),
        'color3': colors.get('tertiary_container', '#9f5db1'),
        'color4': colors.get('primary_container', '#5093e3'),
        'color5': colors.get('tertiary_container', '#9f5db1'),
        'color6': colors.get('tertiary', '#d9bde3'),
        'color7': colors.get('on_surface', '#e1e2e9'),
        'color8': colors.get('on_surface_variant', '#c1c7ce'),
        'color9': colors.get('primary', '#a3c9ff'),
        'color10': colors.get('secondary', '#bcc7db'),
        'color11': colors.get('tertiary', '#d9bde3'),
        'color12': colors.get('primary_container', '#5093e3'),
        'color13': colors.get('tertiary_container', '#9f5db1'),
        'color14': colors.get('on_primary_container', '#d2e4ff'),
        'color15': colors.get('on_surface', '#e1e2e9'),
    },
}
json.dump(palette, open('$COLORS_JSON', 'w'), indent=4)

# Hyprland borders
c4 = colors.get('primary_container', '#5093e3').lstrip('#')
c5 = colors.get('tertiary', '#d9bde3').lstrip('#')
c8 = colors.get('primary_container', '#5093e3').lstrip('#')
print(f'{c4} {c5} {c8}')
" | read C4 C5 C8

            if [ -n "$C4" ]; then
                sed -i \
                    -e "s/col\.active_border = .*/col.active_border = rgba(${C4}ee) rgba(${C5}ee) 45deg/" \
                    -e "s/col\.inactive_border = .*/col.inactive_border = rgba(${C8}aa)/" \
                    "$HOME/.config/hypr/modules/graphics.conf"
                hyprctl reload 2>/dev/null
            fi

            echo "[color-daemon] Colors updated"
        fi
    fi

    sleep 2
done
