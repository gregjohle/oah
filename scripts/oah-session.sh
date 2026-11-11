#!/usr/bin/env bash
# ============================================================================
# OAH X11 session: what Hyprland + upstream's default/hypr/autostart.lua do for
# an Omarchy session, on X11 with bspwm.
#
#   1. Build the OMARCHY_PATH runtime tree and put its commands on PATH.
#   2. Seed $HOME on first login the way Omarchy's installer does, and
#      generate this user's keybindings.
#   3. Export the session environment to D-Bus/systemd activation.
#   4. Start bspwm; once it owns the root window, start the panel-stacking
#      helper, picom and the Omarchy shell (via upstream's supervisor,
#      omarchy-launch-shell), plus upstream's other autostart items.
#   5. The session ends when bspwm exits; everything it started is stopped.
#
# Logs: ${XDG_STATE_HOME:-~/.local/state}/oah/session/*.log
# ============================================================================

set -uo pipefail

OAH_ROOT=$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P)
LOGS="${XDG_STATE_HOME:-$HOME/.local/state}/oah/session"
mkdir -p "$LOGS"
exec >>"$LOGS/session.log" 2>&1
echo "=== OAH session starting $(date -Is) on ${DISPLAY:-?}"

# --- 1. Environment ---------------------------------------------------------
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=bspwm
export XDG_SESSION_DESKTOP=bspwm
export QT_QPA_PLATFORM=xcb
unset WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE

OMARCHY_PATH=$("$OAH_ROOT/tools/oah-runtime" --print) || {
  echo "oah-session: could not build the runtime tree; see above"
  exit 1
}
export OMARCHY_PATH
export PATH="$OMARCHY_PATH/bin:$PATH"

# --- 2. First login: seed $HOME like an Omarchy install -------------------------
# Shipped configs, fontconfig defaults, default font and theme; anything the
# user already has is left alone.
"$OAH_ROOT/tools/oah-seed-home" || echo "oah-session: seeding \$HOME failed; continuing"

if [[ -f $HOME/.Xresources ]]; then
  xrdb -merge "$HOME/.Xresources"
fi

# Keybindings for this user and machine: upstream decides some bindings from
# installed tools (dictation, Docker), the keyboard (JIS) and removed
# preinstalls, so generate them at login. bspwmrc prefers this output and
# falls back to the committed defaults if generation fails.
"$OAH_ROOT/tools/oah-gen-keybindings" --user ||
  echo "oah-session: generating per-user keybindings failed; using the defaults"

# --- 3. Activation environment ------------------------------------------------
dbus-update-activation-environment --systemd --all 2>/dev/null ||
  dbus-update-activation-environment --all

# --- 4. Window manager, then the desktop around it -----------------------------
children=()
cleanup() {
  local pid
  for pid in "${children[@]}"; do kill -TERM "$pid" 2>/dev/null; done
  echo "=== OAH session ended $(date -Is)"
}
trap cleanup EXIT

bspwm -c "$OAH_ROOT/configs/bspwm/bspwmrc" >>"$LOGS/bspwm.log" 2>&1 &
wm=$!

# Wait until bspwm answers on its socket (xprop exits 0 even while the WM
# property is still missing, so it can't be used for this); give up if
# bspwm died.
for _ in {1..200}; do
  bspc wm -g >/dev/null 2>&1 && break
  kill -0 "$wm" 2>/dev/null || { echo "oah-session: bspwm exited during startup"; exit 1; }
  sleep 0.05
done

start() {
  local name=$1; shift
  "$@" >>"$LOGS/$name.log" 2>&1 &
  children+=($!)
}

# The shell's panels are unmanaged dock windows; keep them in their layers.
start stacking oah-x11-stacking
# The shell draws transparent panels and needs a compositor. picom's GLX
# backend needs working GL; without it (VMs, some drivers) picom exits at once,
# so fall back to the xrender backend.
# OAH_PICOM_BACKEND=xrender forces the fallback up front (VMs whose software
# GL starts but renders wrong, which the exit check can't detect).
start_picom() {
  picom --config "$OAH_ROOT/configs/picom/picom.conf" ${OAH_PICOM_BACKEND:+--backend "$OAH_PICOM_BACKEND"} \
    >>"$LOGS/picom.log" 2>&1 &
  local pid=$!
  sleep 1.5
  if ! kill -0 "$pid" 2>/dev/null; then
    echo "oah-session: picom (glx) exited; retrying with the xrender backend"
    picom --config "$OAH_ROOT/configs/picom/picom.conf" --backend xrender >>"$LOGS/picom.log" 2>&1 &
    pid=$!
  fi
  children+=("$pid")
}
start_picom
# GTK apps on X11 take their theme from an XSETTINGS manager, not gsettings.
oah-xsettings-sync
# -c: without it xsettingsd prefers a legacy ~/.xsettingsd over this file.
command -v xsettingsd >/dev/null &&
  start xsettingsd xsettingsd -c "${XDG_CONFIG_HOME:-$HOME/.config}/xsettingsd/xsettingsd.conf"
# Upstream's shell supervisor: relaunches the shell if it dies.
start shell omarchy-launch-shell

# Upstream autostart items (default/hypr/autostart.lua) that work unchanged on
# X11. Not started yet: omarchy-provision-first-run (first-run setup, comes
# with the installer), omarchy-hyprland-monitor-watch (Hyprland monitor
# events; Deferred until the X11 hotplug port) and `herdr server`.
command -v udiskie >/dev/null && start udiskie udiskie --automount --no-notify --no-tray
command -v omarchy-powerprofiles-init >/dev/null && start powerprofiles omarchy-powerprofiles-init
(sleep 2 && omarchy-hook post-boot) >>"$LOGS/hooks.log" 2>&1 &

# --- 5. Run until bspwm exits -------------------------------------------------
wait "$wm"
