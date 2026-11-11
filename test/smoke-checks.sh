#!/bin/bash
# Checks run inside a live dev session by test/smoke (via oah-dev --check).
# Each check appends "<name> pass|fail <detail>" to $SMOKE_RESULTS. This script
# always exits 0; test/smoke decides what's a regression.

set -uo pipefail

: "${SMOKE_RESULTS:?}" "${DEV_LOGS:?}" "${OMARCHY_PATH:?}"
log=$DEV_LOGS/shell.log

record() { printf '%s %s %s\n' "$1" "$2" "${3:-}" >>"$SMOKE_RESULTS"; }
check() {
  local name=$1; shift
  local detail
  if detail=$("$@" 2>&1); then record "$name" pass; else record "$name" fail "$(head -c 300 <<<"$detail" | tr '\n' ' ')"; fi
}

# Every top-level window on the display.
toplevels() { xwininfo -root -children 2>/dev/null | grep -oE '^\s+0x[0-9a-f]+' | tr -d ' '; }

shell_running() { pgrep -f "quickshell -n -p $OMARCHY_PATH/shell" >/dev/null || { echo "quickshell exited"; tail -5 "$log"; return 1; }; }

shell_ipc() { timeout 5 omarchy-shell shell ping; }

no_qml_load_errors() {
  local errors
  errors=$(grep -E 'Component is not ready|Could not create attached properties object|createObject returned null|is not a type|module ".*" is not installed' "$log" | sort | uniq -c | sort -rn | head -5)
  [[ -z $errors ]] || { echo "$errors"; return 1; }
}

# The bar: a mapped dock window across the full width of the top edge, with
# a bar-like height. (Every Quickshell panel on X11 is dock-typed, so the type
# alone proves nothing; the geometry is what shows the bar was laid out.)
bar_geometry() {
  local w geo root_w width height x y
  root_w=$(xwininfo -root | awk '/Width:/ { print $2 }')
  for w in $(toplevels); do
    xprop -id "$w" _NET_WM_WINDOW_TYPE 2>/dev/null | grep -q _NET_WM_WINDOW_TYPE_DOCK || continue
    geo=$(xwininfo -id "$w" 2>/dev/null)
    grep -q 'IsViewable' <<<"$geo" || continue
    width=$(awk '/Width:/ { print $2 }' <<<"$geo")
    height=$(awk '/Height:/ { print $2 }' <<<"$geo")
    x=$(awk '/Absolute upper-left X:/ { print $4 }' <<<"$geo")
    y=$(awk '/Absolute upper-left Y:/ { print $4 }' <<<"$geo")
    (( x == 0 && y == 0 && width == root_w && height > 0 && height <= 100 )) && return 0
  done
  echo "no mapped dock window at the top edge spanning ${root_w}px with a bar-like height"
  return 1
}

# The bar reserves screen space so tiled windows don't cover it.
bar_strut() {
  local w strut
  for w in $(toplevels); do
    strut=$(xprop -id "$w" _NET_WM_STRUT_PARTIAL 2>/dev/null | grep -oE '= .*' | tr -d '= ')
    [[ -n $strut ]] || continue
    IFS=, read -r _left _right top _bottom _ <<<"$strut"
    (( top > 0 )) && return 0
  done
  echo "no window reserves space at the top (_NET_WM_STRUT_PARTIAL)"
  return 1
}

# bspwm must not manage (tile) any of the shell's own windows. Quickshell
# windows carry no WM_CLASS, so they're identified by _NET_WM_PID.
no_tiled_shell_windows() {
  local w pid shell_pids tiled=()
  shell_pids=" $(pgrep -d ' ' -f "quickshell -n -p $OMARCHY_PATH/shell") "
  [[ $shell_pids != "  " ]] || { echo "quickshell isn't running"; return 1; }
  for w in $(bspc query -N -n .window 2>/dev/null); do
    pid=$(xprop -id "$w" _NET_WM_PID 2>/dev/null | grep -oE '[0-9]+$')
    [[ -n $pid && $shell_pids == *" $pid "* ]] && tiled+=("$w")
  done
  (( ${#tiled[@]} == 0 )) || { echo "bspwm manages ${#tiled[@]} shell window(s): ${tiled[*]}"; return 1; }
}

check shell-running shell_running
check shell-ipc shell_ipc
check no-qml-load-errors no_qml_load_errors
check bar-geometry bar_geometry
check bar-strut bar_strut
check no-tiled-shell-windows no_tiled_shell_windows
exit 0
