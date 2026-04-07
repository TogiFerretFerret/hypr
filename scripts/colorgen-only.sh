#!/usr/bin/env bash
# Color-only update (no wallpaper change). Used by waypaper post_command.
WALLPAPER="$1"
COLORS_JSON="$HOME/.cache/wal/colors.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

[ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ] && exit 1
echo "$WALLPAPER" > "$HOME/.cache/wallpaper-colors/current"

python3 "$SCRIPT_DIR/matugen-smart.py" "$WALLPAPER"

eval "$(python3 -c "
import json
d = json.load(open('$COLORS_JSON'))
c = d['colors']
print(f'C4={c[\"color4\"].lstrip(\"#\")}')
print(f'C5={c[\"color6\"].lstrip(\"#\")}')
print(f'C8={c[\"color1\"].lstrip(\"#\")}')
")"

[ -n "$C4" ] && sed -i \
    -e "s/col\.active_border = .*/col.active_border = rgba(${C4}ee) rgba(${C5}ee) 45deg/" \
    -e "s/col\.inactive_border = .*/col.inactive_border = rgba(${C8}aa)/" \
    "$HOME/.config/hypr/modules/graphics.conf"

hyprctl reload 2>/dev/null
