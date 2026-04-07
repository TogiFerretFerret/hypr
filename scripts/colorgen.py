#!/usr/bin/env python3
"""
Heavy wallpaper color extractor.
Uses k-means in CIELAB space for perceptually uniform clustering,
then builds a full dark-theme palette with contrast guarantees.

Outputs ~/.cache/wal/colors.json compatible with quickshell FileView.
Precomputes and caches per wallpaper (by content hash).
"""

import json
import hashlib
import os
import sys
from pathlib import Path
from colorsys import rgb_to_hls, hls_to_rgb

import numpy as np
from PIL import Image
from sklearn.cluster import KMeans


CACHE_DIR = Path.home() / ".cache" / "colorgen"
OUTPUT = Path.home() / ".cache" / "wal" / "colors.json"


def img_hash(path: str) -> str:
    h = hashlib.md5()
    with open(path, "rb") as f:
        while chunk := f.read(8192):
            h.update(chunk)
    return h.hexdigest()[:12]


def rgb_to_lab(rgb: np.ndarray) -> np.ndarray:
    """Convert sRGB [0-255] to CIELAB. Vectorized."""
    rgb_lin = np.where(
        rgb / 255.0 > 0.04045,
        ((rgb / 255.0 + 0.055) / 1.055) ** 2.4,
        rgb / 255.0 / 12.92,
    )
    # sRGB -> XYZ (D65)
    mat = np.array([
        [0.4124564, 0.3575761, 0.1804375],
        [0.2126729, 0.7151522, 0.0721750],
        [0.0193339, 0.1191920, 0.9503041],
    ])
    xyz = rgb_lin @ mat.T
    # Normalize to D65 white point
    xyz /= np.array([0.95047, 1.0, 1.08883])
    # XYZ -> Lab
    delta = 6 / 29
    xyz_f = np.where(
        xyz > delta ** 3,
        np.cbrt(xyz),
        xyz / (3 * delta ** 2) + 4 / 29,
    )
    L = 116 * xyz_f[:, 1] - 16
    a = 500 * (xyz_f[:, 0] - xyz_f[:, 1])
    b = 200 * (xyz_f[:, 1] - xyz_f[:, 2])
    return np.column_stack([L, a, b])


def lab_to_rgb(lab: np.ndarray) -> np.ndarray:
    """Convert CIELAB to sRGB [0-255]."""
    L, a, b = lab[0], lab[1], lab[2]
    fy = (L + 16) / 116
    fx = a / 500 + fy
    fz = fy - b / 200
    delta = 6 / 29
    xyz = np.array([
        fx ** 3 if fx > delta else (fx - 4 / 29) * 3 * delta ** 2,
        fy ** 3 if fy > delta else (fy - 4 / 29) * 3 * delta ** 2,
        fz ** 3 if fz > delta else (fz - 4 / 29) * 3 * delta ** 2,
    ])
    xyz *= np.array([0.95047, 1.0, 1.08883])
    mat_inv = np.array([
        [3.2404542, -1.5371385, -0.4985314],
        [-0.9692660, 1.8760108, 0.0415560],
        [0.0556434, -0.2040259, 1.0572252],
    ])
    rgb_lin = xyz @ mat_inv.T
    rgb = np.where(
        rgb_lin > 0.0031308,
        1.055 * np.power(np.clip(rgb_lin, 0, None), 1 / 2.4) - 0.055,
        12.92 * rgb_lin,
    )
    return np.clip(rgb * 255, 0, 255).astype(int)


def hex_color(r, g, b):
    return f"#{int(r):02x}{int(g):02x}{int(b):02x}"


def hsl(r, g, b):
    return rgb_to_hls(r / 255, g / 255, b / 255)


def adjust(r, g, b, lightness=0.0, saturation=0.0):
    h, l, s = rgb_to_hls(r / 255, g / 255, b / 255)
    l = max(0, min(1, l + lightness))
    s = max(0, min(1, s + saturation))
    nr, ng, nb = hls_to_rgb(h, l, s)
    return int(nr * 255), int(ng * 255), int(nb * 255)


def contrast_ratio(c1, c2):
    """WCAG contrast ratio between two (r,g,b) tuples."""
    def lum(c):
        vals = []
        for v in c:
            v = v / 255
            vals.append(v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4)
        return 0.2126 * vals[0] + 0.7152 * vals[1] + 0.0722 * vals[2]
    l1, l2 = lum(c1), lum(c2)
    if l1 < l2:
        l1, l2 = l2, l1
    return (l1 + 0.05) / (l2 + 0.05)


def ensure_contrast(fg_rgb, bg_rgb, min_ratio=4.5):
    """Lighten fg until it has min_ratio contrast against bg, preserving hue."""
    r, g, b = fg_rgb
    h, l, s = rgb_to_hls(r / 255, g / 255, b / 255)
    for _ in range(50):
        if contrast_ratio((r, g, b), bg_rgb) >= min_ratio:
            return (r, g, b)
        # Only increase lightness, keep hue and saturation locked
        l = min(l + 0.02, 0.9)
        nr, ng, nb = hls_to_rgb(h, l, s)
        r, g, b = int(nr * 255), int(ng * 255), int(nb * 255)
    return (r, g, b)


def extract_palette(image_path: str) -> dict:
    img = Image.open(image_path).convert("RGB")
    # Resize to 300px wide for speed (keeps aspect)
    w, h = img.size
    scale = 300 / w
    img = img.resize((300, int(h * scale)), Image.LANCZOS)

    pixels = np.array(img).reshape(-1, 3).astype(float)

    # Remove near-black and near-white pixels (noise)
    brightness = pixels.sum(axis=1) / 3
    mask = (brightness > 15) & (brightness < 240)
    filtered = pixels[mask]
    if len(filtered) < 100:
        filtered = pixels

    # K-means in CIELAB space (perceptually uniform)
    lab_pixels = rgb_to_lab(filtered)

    n_clusters = 24  # More clusters = finer color discrimination
    kmeans = KMeans(n_clusters=n_clusters, n_init=3, max_iter=100, random_state=42)
    kmeans.fit(lab_pixels)

    # Get cluster centers and sizes
    centers_lab = kmeans.cluster_centers_
    labels = kmeans.labels_
    counts = np.bincount(labels, minlength=n_clusters)

    # Convert centers back to RGB
    centers_rgb = []
    for lab in centers_lab:
        rgb = lab_to_rgb(lab)
        centers_rgb.append(tuple(rgb))

    # Score each cluster: saturation * sqrt(count) * lightness_bonus
    scored = []
    for i, (rgb, count) in enumerate(zip(centers_rgb, counts)):
        r, g, b = rgb
        h, l, s = hsl(r, g, b)
        # Penalize very dark (l < 0.15) and very light (l > 0.85)
        l_bonus = 1.0 if 0.2 < l < 0.75 else 0.2
        # Kill desaturated colors hard
        s_bonus = s if s > 0.35 else s * 0.05
        score = s_bonus * l_bonus * np.sqrt(count / len(labels))
        scored.append((score, i, rgb, s, l, count))

    scored.sort(reverse=True, key=lambda x: x[0])

    # ── Build the palette ──

    # Background: darkest cluster, tinted (not pure black)
    darkest = min(centers_rgb, key=lambda c: sum(c) / 3)
    bg_h, bg_l, bg_s = hsl(*darkest)
    # Clamp lightness to 0.03-0.08 range (very dark but tinted)
    target_l = max(0.03, min(0.08, bg_l))
    bg = adjust(*darkest, lightness=target_l - bg_l)

    bg_rgb = bg

    # Pick 6 accent colors: most scored, with hue diversity
    accents = []
    used_hues = []
    for score, idx, rgb, s, l, count in scored:
        if len(accents) >= 6:
            break
        # Skip very grey colors
        if s < 0.15:
            continue
        h_val, _, _ = hsl(*rgb)
        # Prefer hue diversity but don't be too strict
        too_close = any(min(abs(h_val - uh), 1 - abs(h_val - uh)) < 0.04 for uh in used_hues)
        if too_close and len(accents) >= 3:
            continue
        # Ensure contrast against bg
        rgb = ensure_contrast(rgb, bg_rgb, min_ratio=4.0)
        accents.append(rgb)
        used_hues.append(hsl(*rgb)[0])

    # Pad if we didn't find 6
    while len(accents) < 6:
        accents.append(accents[-1] if accents else (100, 150, 200))

    # Sort accents by luminosity (dark to light)
    accents.sort(key=lambda c: hsl(*c)[1])

    # Surface colors
    surface0 = adjust(*bg, lightness=0.04)
    surface1 = adjust(*bg, lightness=0.08)
    surface2 = adjust(*bg, lightness=0.14)

    # Foreground
    fg = adjust(*accents[-1], lightness=0.3, saturation=-0.4)
    _, fg_l, _ = hsl(*fg)
    if fg_l < 0.8:
        fg = adjust(*fg, lightness=0.8 - fg_l)

    # Dim (muted accent)
    dim = adjust(*accents[2], lightness=0.0, saturation=-0.15)
    dim = ensure_contrast(dim, bg_rgb, min_ratio=2.5)

    # ── Format as pywal-compatible colors.json ──
    colors = {
        "color0": hex_color(*bg),
        "color1": hex_color(*accents[0]),
        "color2": hex_color(*accents[1]),
        "color3": hex_color(*accents[2]),
        "color4": hex_color(*accents[3]),
        "color5": hex_color(*accents[4]),
        "color6": hex_color(*accents[5]),
        "color7": hex_color(*fg),
        "color8": hex_color(*dim),
        # Bright variants: same but boosted
        "color9": hex_color(*ensure_contrast(accents[0], bg_rgb, 5.0)),
        "color10": hex_color(*ensure_contrast(accents[1], bg_rgb, 5.0)),
        "color11": hex_color(*ensure_contrast(accents[2], bg_rgb, 5.0)),
        "color12": hex_color(*ensure_contrast(accents[3], bg_rgb, 5.0)),
        "color13": hex_color(*ensure_contrast(accents[4], bg_rgb, 5.0)),
        "color14": hex_color(*ensure_contrast(accents[5], bg_rgb, 5.0)),
        "color15": hex_color(*fg),
    }

    return {
        "special": {
            "background": hex_color(*bg),
            "foreground": hex_color(*fg),
            "cursor": hex_color(*fg),
        },
        "colors": colors,
    }


def main():
    if len(sys.argv) < 2:
        print("Usage: colorgen.py <image_path>", file=sys.stderr)
        sys.exit(1)

    image_path = sys.argv[1]
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    # Check cache
    h = img_hash(image_path)
    cache_file = CACHE_DIR / f"{h}.json"

    if cache_file.exists():
        palette = json.loads(cache_file.read_text())
    else:
        palette = extract_palette(image_path)
        cache_file.write_text(json.dumps(palette, indent=4))

    # Write output
    OUTPUT.write_text(json.dumps(palette, indent=4))

    # Print summary
    c = palette["colors"]
    print(f"bg={palette['special']['background']} "
          f"primary={c['color4']} "
          f"secondary={c['color5']} "
          f"accent={c['color6']}")


if __name__ == "__main__":
    main()
