#!/usr/bin/env python3
import os
import json
import requests
import sys
import argparse
import subprocess

WALLDIR = os.path.expanduser("~/Pictures/Wallpapers")
COLLECTIONDIR = os.path.join(WALLDIR, "Online")
THUMBDIR = os.path.expanduser("~/.cache/wallpaper-thumbs")
API_KEY = "QDjvjvXCL5w1Q4GcLSJ0Fw3SXazVPS5n"
WALLHAVEN_URL = "https://wallhaven.cc/api/v1/search"

def get_walls_from_dir(directory, source_name):
    if not os.path.exists(THUMBDIR):
        os.makedirs(THUMBDIR)

    walls = []
    if not os.path.exists(directory):
        return walls
    
    for f in os.listdir(directory):
        if f.lower().endswith(('.png', '.jpg', '.jpeg')):
            path = os.path.join(directory, f)
            if os.path.isdir(path): continue # Skip subdirs

            thumb_path = os.path.join(THUMBDIR, f)
            
            if not os.path.exists(thumb_path) or os.path.getmtime(path) > os.path.getmtime(thumb_path):
                try:
                    subprocess.run([
                        "magick", path, "-resize", "300x200^", "-gravity", "center", 
                        "-extent", "300x200", "-quality", "85", thumb_path
                    ], check=True, capture_output=True)
                except Exception as e:
                    thumb_path = path

            walls.append({
                "name": f,
                "path": path,
                "thumb": "file://" + thumb_path,
                "source": source_name,
                "full": path
            })
    return sorted(walls, key=lambda x: x["name"])

def get_local_wallpapers():
    return get_walls_from_dir(WALLDIR, "local")

def get_collection_wallpapers():
    return get_walls_from_dir(COLLECTIONDIR, "collection")

def get_wallhaven_wallpapers(query="citlali"):
    params = {
        "q": query,
        "categories": "110",
        "purity": "111",
        "atleast": "1920x1200",
        "ratios": "landscape",
        "sorting": "relevance",
        "order": "desc",
        "apikey": API_KEY
    }
    
    try:
        r = requests.get(WALLHAVEN_URL, params=params, timeout=10)
        r.raise_for_status()
        data = r.json()
        
        walls = []
        for item in data.get("data", []):
            walls.append({
                "name": f"wallhaven-{item['id']}",
                "path": item["path"],
                "thumb": item["thumbs"]["large"],
                "source": "wallhaven",
                "full": item["path"],
                "id": item["id"]
            })
        return walls
    except Exception as e:
        return []

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--local-only", action="store_true")
    parser.add_argument("--online-only", action="store_true")
    parser.add_argument("--collection-only", action="store_true")
    parser.add_argument("--query", type=str, default="citlali")
    args = parser.parse_args()

    if args.local_only:
        print(json.dumps(get_local_wallpapers()))
    elif args.collection_only:
        print(json.dumps(get_collection_wallpapers()))
    elif args.online_only:
        print(json.dumps(get_wallhaven_wallpapers(args.query)))
    else:
        # Default behavior: combine all
        local_walls = get_local_wallpapers()
        coll_walls = get_collection_wallpapers()
        remote_walls = get_wallhaven_wallpapers(args.query)
        print(json.dumps(local_walls + coll_walls + remote_walls))
