# Omarchy At Home

A 1:1 port of [Omarchy](https://github.com/basecamp/omarchy)'s desktop (its Quickshell shell, theming, keybindings and `omarchy-*` commands) to any Linux distro running X11 or XLibre, with bspwm as the window manager.

OAH doesn't rewrite Omarchy. It ships Omarchy's own code, in Omarchy's own layout and pinned to a formal release (see [`UPSTREAM`](UPSTREAM)), and changes only what depends on Hyprland or Wayland. OAH is standalone: it needs no Omarchy checkout to run or install.

## Layout

| Path | Purpose |
|---|---|
| `UPSTREAM` | The Omarchy release OAH is pinned to |
| `tools/oah-import-upstream` | Copies the pinned release's files into this repo (re-run on each upgrade) |
| `tools/oah-dev` | Runs the desktop in a nested, isolated X session for development |
| `bin/` | Omarchy's commands, OAH's X11 changes made in place (marked `OAH(x11)`), and OAH's own commands |
| `shell/` | Omarchy's Quickshell shell, ported to X11 (`tools/oah-import-shell` + marked hand edits) |
| `agents/` `applications/` `config/` `default/` `etc/` `install/` `migrations/` | Omarchy's files as released (`LICENSE.omarchy`) |
| `configs/` | bspwm, sxhkd, picom configs |
| `themes/` | Omarchy's themes as released |

## Development

Everything runs from this repo. The import tools download the pinned release from GitHub when an upgrade needs it (`OAH_UPSTREAM_URL` overrides the source).

Dependencies (Arch): `quickshell bspwm sxhkd xorg-server-xephyr xorg-xprop imagemagick ttf-jetbrains-mono-nerd`; `xorg-server-xvfb` for `--headless`.

```bash
tools/oah-dev                                  # desktop in a Xephyr window; close it to stop
tools/oah-dev --screenshot shot.png --after 8  # start, capture, stop
tools/oah-dev --headless --screenshot shot.png # same, without a window (Xvfb)
tools/oah-dev --fresh --theme "Gruvbox"        # reset the dev home with another theme
```

The dev session is isolated from your real desktop: its own X display, its own `HOME` (`~/.cache/oah/dev-home`, seeded like a fresh Omarchy install), its own D-Bus session, and `OMARCHY_PATH` set to this checkout (an installed OAH keeps running its own copy). Logs go to `~/.local/state/oah/dev/`.
