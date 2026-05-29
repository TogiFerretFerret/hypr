# river's hyprland dots — EVA-00 // ASAHI

a hyprland config built on an apple silicon machine running asahi linux, with a focus on custom tooling, dynamic color theming, and a fully QML-based UI stack. most of the actual shell/bar/overlay work lives in a separate quickshell repo — this repo is the hyprland side of things.

the name EVA-00 comes from neon genesis evangelion. the color palette (blue + lavender) is loosely inspired by unit 00's prototype aesthetic.

---

## why i made this

i've been ricing linux desktops for a while, but i got frustrated with how most setups are just a mix of other people's configs glued together. i wanted to build something from scratch that i actually understood end-to-end — where i knew why every line was there.

the other motivation was running hyprland on asahi linux (apple silicon). asahi is still pretty rough around the edges, and a lot of existing configs assume x86 hardware with nvidia/amd GPUs. getting a smooth, fast desktop experience on an M-series chip required writing a bunch of custom workarounds and tooling that i haven't seen anyone else document.

the biggest thing i built custom was the color pipeline. most ricing setups use pywal, which does a decent job but uses a fairly naive color extraction algorithm and produces colors that don't always look great or have enough contrast. i wanted something that worked in perceptually uniform color space (CIELAB) so the extracted palette would look natural and consistent regardless of the wallpaper.

---

## what i learned building this

- **how hyprland's lua config works** — the lua API is relatively new and documentation is sparse. i had to read the hyprland source and experiment a lot to understand how `hl.config()`, `hl.on()`, and `hl.curve()` map to the underlying config system.
- **color science** — implementing k-means clustering in CIELAB instead of RGB taught me a lot about how human color perception works and why RGB distance is a bad proxy for visual similarity.
- **QML** — the lockscreen and parts of the quickshell UI are my first serious QML projects. QML is a weird language (declarative JS-ish) and the learning curve was steep, but it's genuinely powerful for building animated UIs.
- **linux graphics stack** — dealing with wayland, swww, sddm, hyprlock, and getting them all to play nicely together on asahi taught me a lot about how the linux display stack actually works under the hood.
- **IPC and daemons** — the stats bridge uses a unix socket to multiplex system metrics to multiple quickshell widgets. writing a small daemon in python and having QML consume it over a socket was new territory for me.

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

## installation / using this config

> **warning:** this config is built specifically for my machine (asahi linux, apple M-series, single 1080p display). you will almost certainly need to adapt it. that said, here's how to get started if you want to try it.

**dependencies:**
- hyprland (with lua support — recent versions)
- quickshell
- swww
- rofi
- ghostty (or swap `Terminal` in `hyprland.lua`)
- hypridle, hyprlock (or hyprpm)
- python 3.11+ with `numpy`, `pillow`, `scikit-learn` (for colorgen)
- clipvault
- hyprpolkitagent
- fcitx5 (optional, for CJK input)

**steps:**
1. clone this repo to `~/.config/hypr/`
2. edit `modules/hardware.lua` to match your monitor(s)
3. edit `hyprland.lua` to set your preferred terminal, file manager, and menu launcher
4. install python deps: `pip install numpy pillow scikit-learn`
5. put some wallpapers in `~/Pictures/Wallpapers/`
6. launch hyprland

for the lockscreen, copy the `lockscreen/` folder to wherever your sddm themes directory is (usually `/usr/share/sddm/themes/`) and set it in `/etc/sddm.conf`.

---

## screenshots

*(coming soon — i keep meaning to take proper ones)*

---

all dots are spread across repos — this one is just hyprland. a master repo links everything together.
