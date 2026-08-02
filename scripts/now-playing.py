#!/usr/bin/env python3
import subprocess
import time
import os
import sys

# Configuration
NOW_PLAYING_FILE = os.path.expanduser("~/now-playing.txt")
CLEAR_ON_PAUSE = False  # If True, clears the file when paused or stopped

def romanize(text):
    if not text:
        return ""
    try:
        process = subprocess.run(
            ["kakasi", "-Ka", "-Ha", "-Ja", "-Ea", "-s"],
            input=text,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True
        )
        return process.stdout.strip()
    except Exception:
        return text

def clear_file():
    try:
        with open(NOW_PLAYING_FILE, "w") as f:
            f.write("\n")
    except Exception as e:
        print(f"Error clearing file: {e}", file=sys.stderr)

def write_track(status, artist, title):
    try:
        status_clean = status.strip().lower()
        if status_clean == "playing" or not CLEAR_ON_PAUSE:
            # Format and romanize text
            artist_rom = romanize(artist.strip())
            title_rom = romanize(title.strip())
            
            if artist_rom and title_rom:
                text = f"Now Playing: {artist_rom} - {title_rom}\n"
            elif title_rom:
                text = f"Now Playing: {title_rom}\n"
            else:
                text = "Now Playing: Unknown Track\n"
        else:
            text = "\n"

        with open(NOW_PLAYING_FILE, "w") as f:
            f.write(text)
    except Exception as e:
        print(f"Error writing to file: {e}", file=sys.stderr)

def main():
    # Start with a clean state
    clear_file()

    while True:
        try:
            # We use playerctl -F metadata to monitor playback changes.
            # Using ' ||| ' as a delimiter to safely split status, artist, and title.
            process = subprocess.Popen(
                ["playerctl", "-F", "metadata", "--format", "{{status}} ||| {{artist}} ||| {{title}}"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1
            )
            
            # Read stdout line by line
            while True:
                line = process.stdout.readline()
                if not line:
                    break
                
                parts = line.strip().split(" ||| ", 2)
                status = parts[0] if len(parts) > 0 else ""
                artist = parts[1] if len(parts) > 1 else ""
                title = parts[2] if len(parts) > 2 else ""
                
                write_track(status, artist, title)

            # If the process exited (e.g. no active players), clear file and wait to restart.
            process.wait()
            clear_file()
            
        except FileNotFoundError:
            print("playerctl command not found. Please install playerctl.", file=sys.stderr)
            time.sleep(10)
            continue
        except Exception as e:
            print(f"Error in playerctl monitor loop: {e}", file=sys.stderr)
            clear_file()
        
        # Sleep for a bit before trying to restart playerctl
        time.sleep(2)

if __name__ == "__main__":
    main()
