#!/usr/bin/env python3
import os
import json
import time
import sys
import glob

def get_audio_stats():
    # Find all playback hw_params files
    hw_params_files = glob.glob("/proc/asound/card*/pcm*p/sub*/hw_params")
    
    active_file = None
    for f in hw_params_files:
        try:
            with open(f, "r") as file:
                content = file.read()
                if "closed" not in content:
                    active_file = f
                    break
        except:
            continue

    if not active_file:
        return {"active": False, "rate": "OFF", "format": "--", "type": "Idle", "color": "#5d6172"}
    
    try:
        with open(active_file, "r") as f:
            lines = f.readlines()
            
            stats = {}
            for line in lines:
                parts = line.strip().split(": ")
                if len(parts) == 2:
                    stats[parts[0]] = parts[1]
            
            rate_raw = int(stats.get("rate", "0").split()[0])
            fmt = stats.get("format", "S32_LE")
            
            # MoonDrop Dawn Pro LED Logic / Generic Hi-Res Logic:
            rate_str = f"{rate_raw/1000:g}kHz"
            if "dsd" in fmt.lower() or rate_raw > 768000:
                type_name = "DSD"
                color = "#ffffff" # White
            elif rate_raw >= 352800:
                type_name = "Hi-Res PCM"
                color = "#94e2d5" # Cyan
            elif rate_raw >= 88200:
                type_name = "Hi-Res PCM"
                color = "#f9e2af" # Yellow
            else:
                type_name = "PCM"
                color = "#f38ba8" # Red
                
            return {
                "active": True,
                "rate": rate_str,
                "format": fmt,
                "type": type_name,
                "color": color,
                "raw_rate": rate_raw
            }
    except Exception as e:
        return {"active": False, "rate": "ERR", "format": "--", "type": "Idle", "color": "#5d6172"}

if __name__ == "__main__":
    while True:
        print(json.dumps(get_audio_stats()))
        sys.stdout.flush()
        time.sleep(1)
