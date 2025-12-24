#!/bin/bash
# simple script: toggle kbd backlight between 0% and 100% using brightnessctl
current_level=$(brightnessctl -d 'kbd_backlight' get)
echo "Current keyboard backlight level: $current_level"
# if greater than 0, set to 0, else set to 255
if [ "$current_level" -gt 0 ]; then
	brightnessctl -d 'kbd_backlight' set 0
	echo "Keyboard backlight turned OFF"
else
	brightnessctl -d 'kbd_backlight' set 255
	echo "Keyboard backlight turned ON"
fi
