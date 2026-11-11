# Omarchy At Home

A 1:1 port of [Omarchy](https://github.com/basecamp/omarchy)'s desktop (its Quickshell shell, theming, keybindings and `omarchy-*` commands) to any Linux distro running X11 or XLibre, with bspwm as the window manager.

OAH doesn't rewrite Omarchy. It runs Omarchy's own code, pinned to a formal release (see [`UPSTREAM`](UPSTREAM)), and overrides only what depends on Hyprland or Wayland.

## Layout

| Path | Purpose |
|---|---|
| `UPSTREAM` | The Omarchy release OAH is pinned to |
| `tools/oah-runtime` | Builds the `OMARCHY_PATH` tree: upstream + OAH overrides |
| `tools/oah-dev` | Runs the desktop in a nested, isolated X session for development |
| `bin/` | X11 replacements for upstream `omarchy-*` commands (override same-named upstream commands) |
| `shell/` | OAH's ported copy of upstream's Quickshell shell (once the port starts) |
| `configs/` | bspwm, sxhkd, picom configs |

## Development

You need an Omarchy checkout at the pinned release. The default location is `../omarchy` next to this repo; set `OAH_UPSTREAM` to use another.

```bash
git clone https://github.com/basecamp/omarchy ../omarchy
git -C ../omarchy checkout "$(cat UPSTREAM)"
```

Dependencies (Arch): `quickshell bspwm sxhkd xorg-server-xephyr xorg-xprop imagemagick ttf-jetbrains-mono-nerd`; `xorg-server-xvfb` for `--headless`.

```bash
tools/oah-dev                                  # desktop in a Xephyr window; close it to stop
tools/oah-dev --screenshot shot.png --after 8  # start, capture, stop
tools/oah-dev --headless --screenshot shot.png # same, without a window (Xvfb)
tools/oah-dev --fresh --theme "Gruvbox"        # reset the dev home with another theme
```

The dev session is isolated from your real desktop: its own X display, its own `HOME` (`~/.cache/oah/dev-home`, seeded like a fresh Omarchy install), its own D-Bus session and its own runtime tree (`~/.cache/oah/dev-runtime`, so it never repoints an installed OAH desktop at checkout code). Logs go to `~/.local/state/oah/dev/`.
