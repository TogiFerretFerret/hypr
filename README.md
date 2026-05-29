# river's hyprland dots — EVA-00 // ASAHI

a hyprland config built on an apple silicon machine (asahi linux) with a focus on custom tooling, dynamic color theming, and a fully QML-based UI stack. most of the actual shell/bar/overlay work lives in a separate quickshell repo — this repo is the hyprland side of things.

---

## what's in here

```
hyprland.lua          — main entry point (lua config)
modules/
  hardware.lua        — monitor setup
  envvars.lua         — wayland/XDG environment variables
  autostart.lua       — things that launch on startup
  graphics.lua        — animations, blur, glow, borders, rounding
  colors.lua          — dynamic accent colors (overwritten by wallpaper scripts)
  plugins.lua         — hyprpm plugin config
  binds.lua           — all keybindings
  rules.lua           — window rules
scripts/              — python/shell utilities
lockscreen/           — custom QML sddm/hyprlock theme
```

---

## features

### lua config
the entire hyprland config is written in lua (not the `.conf` format). this is needed for modern hyprland and makes it much easier to share variables across modules, loop over monitor lists, and write actual logic instead of static declarations.

### dynamic wallpaper color theming
`scripts/colorgen.py` extracts a full dark-theme palette from any wallpaper using k-means clustering in CIELAB (perceptually uniform) color space, then writes a `colors.json` compatible with pywal/quickshell. `scripts/wallpaper.sh` ties everything together — set a wallpaper and the border colors, glow colors, and quickshell accent all update live without restarting anything.

the color pipeline:
1. `wallpaper.sh` picks the image and calls `colorgen.py`
2. `colorgen.py` runs k-means in CIELAB, builds contrast-checked palette, caches by content hash
3. `color-daemon.sh` pushes new colors to hyprland (`hyprctl keyword`) and triggers quickshell reload
4. `swaync-colors.sh` applies colors to the notification center stylesheet

### custom lockscreen
`lockscreen/Main.qml` is a fully custom QML SDDM theme. it features:
- a rotoscoped analog clock (took a while, worth it)
- smooth fade-in on boot
- password input with shake animation on wrong password
- accent colors matching the rest of the system palette
- session switcher popup

### quickshell UI
nearly all overlay UI (bar, notification center, wallpaper picker, system stats dashboard) is built in quickshell with QML. this repo launches it via autostart but the actual QML source lives separately.

### stats bridge
`scripts/stats-bridge.py` is a small python daemon that aggregates system stats (cpu, memory, network, etc.) over a local socket for the quickshell dashboard to consume without each widget needing its own polling loop.

### wallpaper picker
`scripts/wallpaper-picker.sh` opens a rofi grid of all wallpapers in `~/Pictures/Wallpapers/`, and selecting one runs the full color pipeline above. `scripts/wallpaper-sort.py` can sort/rank wallpapers by how much you use them.

### animations
custom bezier curves for all animation types — windows pop in with `easeOutQuint`, workspaces slide with `easeInOutCubic`, layers fade with `almostLinear`. all tuned manually so nothing feels sluggish or jarring.

### window glow
uses hyprland's `glow` decoration (added recently) alongside blur and shadow. glow color is updated dynamically with the wallpaper accent so active windows have a colored halo that matches the current theme.

---

## stack

| thing | what |
|---|---|
| compositor | hyprland (lua config) |
| shell/bar | quickshell + QML |
| wallpaper | swww |
| color gen | custom python (k-means / CIELAB) |
| lockscreen | custom QML (sddm) |
| idle | hypridle |
| notifications | quickshell NotificationServer |
| launcher | rofi |
| terminal | ghostty |
| clipboard | clipvault |
| polkit | hyprpolkitagent |

---

## notes

- built on asahi linux (apple silicon / aarch64), so some things like `no_hardware_cursors = true` are asahi-specific workarounds
- `offcase.py` handles edge cases for when certain services misbehave on logout
- the sddm safety net in autostart restarts sddm on hyprland shutdown to prevent display manager hangs

---

all dots are spread across repos — this one is just hyprland. a master repo links everything together.
