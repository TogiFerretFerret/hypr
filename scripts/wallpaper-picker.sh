#!/usr/bin/env bash
# Rofi wallpaper picker with image previews
# Generates thumbnails, shows in rofi grid, applies with color sync

WALLDIR="$HOME/Pictures/Wallpapers"
THUMBDIR="$HOME/.cache/wallpaper-thumbs"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COLORS_JSON="$HOME/.cache/wal/colors.json"

mkdir -p "$THUMBDIR"

# Read Material You colors for rofi theme
if [ -f "$COLORS_JSON" ]; then
    eval "$(python3 -c "
import json
d = json.load(open('$COLORS_JSON'))
c = d['colors']
s = d['special']
print(f'ROFI_BG=\"{s[\"background\"]}eb\"')
print(f'ROFI_ACCENT=\"{c[\"color4\"]}\"')
print(f'ROFI_DIM=\"{c[\"color8\"]}\"')
")"
    # Patch the rofi theme with current colors
    sed -i \
        -e "s/accent: #[0-9a-fA-F]*/accent: $ROFI_ACCENT/" \
        -e "s/bg: #[0-9a-fA-F]*/bg: $ROFI_BG/" \
        ~/.config/rofi/wallpaper.rasi
fi

# Generate thumbnails if missing
for img in "$WALLDIR"/*.{png,jpg,jpeg} ; do
    [ -f "$img" ] || continue
    name=$(basename "$img")
    thumb="$THUMBDIR/$name"
    if [ ! -f "$thumb" ] || [ "$img" -nt "$thumb" ]; then
        magick "$img" -resize 300x200^ -gravity center -extent 300x200 \
            -quality 85 "$thumb" 2>/dev/null &
    fi
done
wait

# Build rofi entries: filename\0icon\x1fthumb_path
entries=""
for img in "$WALLDIR"/*.{png,jpg,jpeg} ; do
    [ -f "$img" ] || continue
    name=$(basename "$img")
    name_no_ext="${name%.*}"
    thumb="$THUMBDIR/$name"
    entries+="${name_no_ext}\0icon\x1f${thumb}\n"
done

# Show rofi
chosen=$(echo -en "$entries" | rofi -dmenu -i \
    -theme ~/.config/rofi/wallpaper.rasi \
    -p "Wallpaper" \
    -show-icons)

[ -z "$chosen" ] && exit 0

# Find the full path
for img in "$WALLDIR"/*.{png,jpg,jpeg} ; do
    [ -f "$img" ] || continue
    name=$(basename "$img")
    name_no_ext="${name%.*}"
    if [ "$name_no_ext" = "$chosen" ]; then
        bash "$SCRIPT_DIR/wallpaper.sh" "$img"
        exit 0
    fi
done
