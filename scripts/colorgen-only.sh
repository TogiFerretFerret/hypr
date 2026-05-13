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

[ -n "$C4" ] && {
    echo "hl.config({ general = { col = { active_border = { colors = {\"rgba(${C4}ee)\", \"rgba(${C5}ee)\"}, angle = 45 }, inactive_border = \"rgba(${C8}aa)\" } } })" > "$HOME/.config/hypr/modules/colors.lua"
    hyprctl reload 2>/dev/null
}
bash ~/tauon/sync-theme.sh 2>/dev/null
# swaync replaced by quickshell — colors sync automatically via pywal FileView
