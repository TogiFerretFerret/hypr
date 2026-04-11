#!/usr/bin/env bash
# wallpaper.sh — switch wallpaper with swww + smart matugen color sync

WALLDIR="$HOME/Pictures/Wallpapers"
CURRENT_FILE="$HOME/.cache/wallpaper-colors/current"
COLORS_JSON="$HOME/.cache/wal/colors.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$(dirname "$CURRENT_FILE")" "$HOME/.cache/wal"

mapfile -t WALLS < <(find "$WALLDIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | sort)
[ ${#WALLS[@]} -eq 0 ] && exit 1

pick_wallpaper() {
    local current=""; [ -f "$CURRENT_FILE" ] && current=$(cat "$CURRENT_FILE")
    case "${1:-}" in
        --next) local idx=0; for i in "${!WALLS[@]}"; do [ "${WALLS[$i]}" = "$current" ] && idx=$((i+1)) && break; done
                [ $idx -ge ${#WALLS[@]} ] && idx=0; echo "${WALLS[$idx]}" ;;
        --prev) local idx=$((${#WALLS[@]}-1)); for i in "${!WALLS[@]}"; do [ "${WALLS[$i]}" = "$current" ] && idx=$((i-1)) && break; done
                [ $idx -lt 0 ] && idx=$((${#WALLS[@]}-1)); echo "${WALLS[$idx]}" ;;
        "") local pick="$current" n=0; while [ "$pick" = "$current" ] && [ $n -lt 20 ]; do
                pick="${WALLS[$((RANDOM % ${#WALLS[@]}))]}"; n=$((n+1)); done; echo "$pick" ;;
        *) echo "$1" ;;
    esac
}

WALLPAPER=$(pick_wallpaper "$1")
[ ! -f "$WALLPAPER" ] && exit 1
echo "$WALLPAPER" > "$CURRENT_FILE"

# swww
pgrep -x swww-daemon > /dev/null || swww-daemon &disown
swww img "$WALLPAPER" --transition-type grow --transition-pos 0.5,0.9 --transition-duration 2 --transition-fps 60

# Generate colors (smart matugen - picks best preference per wallpaper)
python3 "$SCRIPT_DIR/matugen-smart.py" "$WALLPAPER"

# Update hyprland borders
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

# Sync Tauon theme
bash ~/tauon/sync-theme.sh 2>/dev/null

# Sync swaync colors
bash "$SCRIPT_DIR/swaync-colors.sh" 2>/dev/null
echo "Wallpaper: $(basename "$WALLPAPER")"
