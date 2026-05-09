#!/usr/bin/env python3
"""
Wallpaper sorter — swipe through images, keep or skip.
Uses swww for fullscreen preview + terminal overlay for controls.

Controls:
  y / Enter / Right  — keep (copy to destination)
  n / Backspace / Left — skip
  u — undo last decision
  q / Esc — quit
  s — star (keep + copy to starred subfolder)
"""

import os
import sys
import shutil
import subprocess
import tty
import termios
import signal
import json
from pathlib import Path

EXTENSIONS = {'.png', '.jpg', '.jpeg', '.webp', '.bmp'}

def get_images(src_dir):
    imgs = []
    for root, dirs, files in os.walk(src_dir):
        dirs.sort()
        for f in sorted(files):
            if Path(f).suffix.lower() in EXTENSIONS:
                imgs.append(os.path.join(root, f))
    return imgs

def show_swww(path):
    subprocess.run(
        ["swww", "img", path,
         "--transition-type", "fade",
         "--transition-duration", "0.3",
         "--transition-fps", "60"],
        capture_output=True
    )

def get_key():
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        ch = sys.stdin.read(1)
        if ch == '\x1b':
            ch2 = sys.stdin.read(1)
            if ch2 == '[':
                ch3 = sys.stdin.read(1)
                if ch3 == 'C': return 'right'
                if ch3 == 'D': return 'left'
                if ch3 == 'A': return 'up'
                if ch3 == 'B': return 'down'
            return 'esc'
        return ch
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)

def clear_line():
    sys.stdout.write('\r\033[K')
    sys.stdout.flush()

def main():
    import argparse
    parser = argparse.ArgumentParser(description='Sort wallpapers interactively')
    parser.add_argument('source', help='Source directory to sort from')
    parser.add_argument('dest', help='Destination directory for kept wallpapers')
    parser.add_argument('--starred', help='Subfolder for starred wallpapers (default: Starred)', default='Starred')
    parser.add_argument('--resume', help='Resume file to continue where you left off', default=None)
    args = parser.parse_args()

    src = os.path.expanduser(args.source)
    dest = os.path.expanduser(args.dest)
    starred_dir = os.path.join(dest, args.starred)
    os.makedirs(dest, exist_ok=True)
    os.makedirs(starred_dir, exist_ok=True)

    imgs = get_images(src)
    if not imgs:
        print("No images found.")
        return

    # Resume support
    resume_file = args.resume or os.path.join(src, '.sort-progress.json')
    decisions = {}  # path -> 'keep' | 'skip' | 'star'
    start_idx = 0
    if os.path.exists(resume_file):
        with open(resume_file) as f:
            data = json.load(f)
            decisions = data.get('decisions', {})
            start_idx = data.get('index', 0)
        print(f"\033[33mResuming from #{start_idx + 1}/{len(imgs)} ({len(decisions)} already sorted)\033[0m")

    history = []  # stack of (index, decision) for undo
    idx = start_idx

    def save_progress():
        with open(resume_file, 'w') as f:
            json.dump({'decisions': decisions, 'index': idx}, f)

    def status_bar():
        kept = sum(1 for v in decisions.values() if v in ('keep', 'star'))
        skipped = sum(1 for v in decisions.values() if v == 'skip')
        starred = sum(1 for v in decisions.values() if v == 'star')
        rel = os.path.relpath(imgs[idx], src)
        w = os.get_terminal_size().columns

        bar = f" [{idx+1}/{len(imgs)}]  \033[32m{kept} kept\033[0m  \033[35m{starred} starred\033[0m  \033[31m{skipped} skip\033[0m  │  {rel}"
        clear_line()
        sys.stdout.write(bar[:w])
        sys.stdout.flush()

    def show_help():
        print("\n\033[36m  y/Enter/→ keep  │  n/Bksp/← skip  │  s star  │  u undo  │  q quit\033[0m")

    print(f"\033[1mSorting {len(imgs)} wallpapers\033[0m")
    print(f"  From: \033[34m{src}\033[0m")
    print(f"  Keep: \033[32m{dest}\033[0m")
    print(f"  Star: \033[35m{starred_dir}\033[0m")
    show_help()

    # Show first image
    show_swww(imgs[idx])
    status_bar()

    while True:
        key = get_key()

        if key in ('q', '\x03', 'esc'):  # q, Ctrl-C, Esc
            clear_line()
            save_progress()
            print(f"\n\033[33mSaved progress at #{idx+1}. Run again to resume.\033[0m")
            kept = sum(1 for v in decisions.values() if v in ('keep', 'star'))
            print(f"\033[32m{kept} wallpapers kept.\033[0m")
            break

        elif key in ('y', '\r', '\n', 'right'):  # keep
            decisions[imgs[idx]] = 'keep'
            dst = os.path.join(dest, os.path.basename(imgs[idx]))
            if not os.path.exists(dst):
                shutil.copy2(imgs[idx], dst)
            history.append((idx, 'keep'))
            idx += 1

        elif key in ('n', '\x7f', 'left'):  # skip (backspace = \x7f)
            decisions[imgs[idx]] = 'skip'
            history.append((idx, 'skip'))
            idx += 1

        elif key == 's':  # star
            decisions[imgs[idx]] = 'star'
            dst = os.path.join(starred_dir, os.path.basename(imgs[idx]))
            if not os.path.exists(dst):
                shutil.copy2(imgs[idx], dst)
            # Also copy to main dest
            dst2 = os.path.join(dest, os.path.basename(imgs[idx]))
            if not os.path.exists(dst2):
                shutil.copy2(imgs[idx], dst2)
            history.append((idx, 'star'))
            idx += 1

        elif key == 'u':  # undo
            if history:
                prev_idx, prev_decision = history.pop()
                prev_path = imgs[prev_idx]
                # Remove copied file if it was kept/starred
                if prev_decision in ('keep', 'star'):
                    dst = os.path.join(dest, os.path.basename(prev_path))
                    if os.path.exists(dst):
                        os.remove(dst)
                if prev_decision == 'star':
                    dst = os.path.join(starred_dir, os.path.basename(prev_path))
                    if os.path.exists(dst):
                        os.remove(dst)
                del decisions[prev_path]
                idx = prev_idx
            else:
                continue

        elif key == '?':
            show_help()
            continue

        else:
            continue

        # Check bounds
        if idx >= len(imgs):
            clear_line()
            save_progress()
            kept = sum(1 for v in decisions.values() if v in ('keep', 'star'))
            print(f"\n\033[1;32mDone! {kept}/{len(imgs)} wallpapers kept.\033[0m")
            break

        # Show next image and update status
        show_swww(imgs[idx])
        status_bar()
        save_progress()

if __name__ == '__main__':
    main()
