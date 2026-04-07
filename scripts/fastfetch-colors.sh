#!/usr/bin/env bash
# Updates fastfetch config colors from current Material You palette
# Only changes color codes, preserves the entire layout

COLORS_JSON="$HOME/.cache/wal/colors.json"
FF_CONFIG="$HOME/.config/fastfetch/config.jsonc"

[ ! -f "$COLORS_JSON" ] && exit 1

# Read colors
eval "$(python3 -c "
import json
d = json.load(open('$COLORS_JSON'))
c = d['colors']
print(f'C_BORDER={c[\"color4\"]}')    # primary - box borders
print(f'C_HEADER={c[\"color5\"]}')    # secondary - section headers
print(f'C_TEXT={c[\"color8\"]}')      # dim - normal text
print(f'C_ASCII={c[\"color4\"]}')     # primary - ASCII art
print(f'C_ACCENT={c[\"color6\"]}')    # tertiary - accent labels
print(f'C_FG={d[\"special\"][\"foreground\"]}')
")"

[ -z "$C_BORDER" ] && exit 1

# Strip # prefix for fastfetch {##hex} format
B="${C_BORDER#\#}"
H="${C_HEADER#\#}"
T="${C_TEXT#\#}"
A="${C_ASCII#\#}"
AC="${C_ACCENT#\#}"
F="${C_FG#\#}"

# Replace ANSI color codes with hex equivalents
# {#35} -> border, {#36} -> header, {#37} -> text, {#@46} -> ascii art, {#@220} -> accent, {#@35} -> border
sed -i \
    -e "s/{#35}/{##$B}/g" \
    -e "s/{#36}/{##$H}/g" \
    -e "s/{#37}/{##$F}/g" \
    -e "s/{#@46}/{##$A}/g" \
    -e "s/{#@220}/{##$AC}/g" \
    -e "s/{#@37}/{##$F}/g" \
    -e "s/{#@35}/{##$B}/g" \
    "$FF_CONFIG"

echo "Fastfetch colors updated: border=$C_BORDER header=$C_HEADER"
