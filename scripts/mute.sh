#!/bin/bash
# instead of mute, we will toggle volume between 0 and MEMORY_VOLUME (stored in a txt file at /home/river/.config/hypr/scripts/volume_memory.txt)
# obviously before setting to mute, we need to store the current volume in that file
MEMORY_FILE="/home/river/.config/hypr/scripts/volume_memory.txt"
CURRENT_VOLUME=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1 | tr -d '%')
if [ "$CURRENT_VOLUME" -eq 0 ]; then
	# Unmute: read the stored volume and set it
	if [ -f "$MEMORY_FILE" ]; then
		MEMORY_VOLUME=$(cat "$MEMORY_FILE")
		pactl set-sink-volume @DEFAULT_SINK@ "${MEMORY_VOLUME}%"
	else
		# If no memory file exists, set to a default volume (e.g., 50%)
		pactl set-sink-volume @DEFAULT_SINK@ 50%
	fi
else
	# Mute: store the current volume and set volume to 0
	echo "$CURRENT_VOLUME" > "$MEMORY_FILE"
	pactl set-sink-volume @DEFAULT_SINK@ 0%
fi

