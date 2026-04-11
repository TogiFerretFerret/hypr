#!/usr/bin/env bash
# Generate swaync style.css from template + matugen colors
COLORS="$HOME/.cache/wal/colors.json"
TEMPLATE="$HOME/.config/swaync/style.css.template"
OUTPUT="$HOME/.config/swaync/style.css"

[ -f "$COLORS" ] || exit 1
[ -f "$TEMPLATE" ] || exit 1

eval "$(python3 -c "
import json
c = json.load(open('$COLORS'))
bg = c['special']['background']
fg = c['special']['foreground']
accent = c['colors']['color6']  # accent/secondary bright
# Parse bg into r,g,b (0-255)
br, bg_val, bb = int(bg[1:3],16), int(bg[3:5],16), int(bg[5:7],16)
# Parse fg for dimmed versions
fr, fg_val, fb = int(fg[1:3],16), int(fg[3:5],16), int(fg[5:7],16)
print(f'BG=\"{bg}\"')
print(f'FG=\"{fg}\"')
print(f'ACCENT=\"{accent}\"')
print(f'BG_R=\"{br}\"')
print(f'BG_G=\"{bg_val}\"')
print(f'BG_B=\"{bb}\"')
print(f'FG_DIM=\"rgba({fr},{fg_val},{fb},0.5)\"')
print(f'FG_SOFT=\"rgba({fr},{fg_val},{fb},0.8)\"')
")"

sed -e "s|{{bg}}|$BG|g" \
    -e "s|{{fg}}|$FG|g" \
    -e "s|{{accent}}|$ACCENT|g" \
    -e "s|{{bg_r}}|$BG_R|g" \
    -e "s|{{bg_g}}|$BG_G|g" \
    -e "s|{{bg_b}}|$BG_B|g" \
    -e "s|{{fg_dim}}|$FG_DIM|g" \
    -e "s|{{fg_soft}}|$FG_SOFT|g" \
    "$TEMPLATE" > "$OUTPUT"

# Reload swaync
swaync-client -rs 2>/dev/null
