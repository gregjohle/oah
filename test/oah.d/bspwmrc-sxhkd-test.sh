#!/bin/bash
# configs/bspwm/bspwmrc must replace only the sxhkd it started for its own
# display: a bspwm reload (`bspc wm -r`) swaps it, and sxhkd on any other
# display (e.g. the host desktop's) is never touched.

set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../lib" && pwd)/base.sh"

require_command bspwm
require_command sxhkd
require_command xprop
scratch="" && new_scratch scratch

# The "host" sxhkd: runs before our display exists, on a display of its own.
start_xvfb
host_display=$DISPLAY
: >"$scratch/empty-sxhkdrc"
sxhkd -c "$scratch/empty-sxhkdrc" >/dev/null 2>&1 &
host_sxhkd=$!
host_xvfb=$TEST_XVFB_PID

# Our session's display.
start_xvfb
export XDG_RUNTIME_DIR=$scratch/run
mkdir -p "$XDG_RUNTIME_DIR"
pidfile=$XDG_RUNTIME_DIR/oah-sxhkd-${DISPLAY//[^0-9.]/}.pid

bspwm -c "$OAH_ROOT/configs/bspwm/bspwmrc" >"$scratch/bspwm.log" 2>&1 &
bspwm_pid=$!
# Processes may already be gone by exit (an Xvfb taking its clients with it),
# so nothing in the trap may fail: set -e applies inside traps too.
on_exit() {
  [[ -f $pidfile ]] && kill "$(cat "$pidfile")" 2>/dev/null || true
  kill "$bspwm_pid" "$host_sxhkd" "$host_xvfb" "$TEST_XVFB_PID" 2>/dev/null || true
  test_cleanup
}
trap on_exit EXIT

for _ in {1..50}; do [[ -s $pidfile ]] && break; sleep 0.1; done
[[ -s $pidfile ]] || fail "bspwmrc records its sxhkd in a per-display pidfile" "$(cat "$scratch/bspwm.log")"
first=$(cat "$pidfile")
[[ $(ps -o comm= -p "$first") == sxhkd ]] || fail "the recorded pid is a running sxhkd"
pass "bspwmrc starts sxhkd and records it per display"

bspc wm -r
for _ in {1..50}; do
  [[ -s $pidfile && $(cat "$pidfile") != "$first" ]] && break
  sleep 0.1
done
second=$(cat "$pidfile")
[[ $second != "$first" ]] || fail "a bspwm reload starts a new sxhkd"
# Give the old one a moment to exit after the kill.
for _ in {1..30}; do kill -0 "$first" 2>/dev/null || break; sleep 0.1; done
kill -0 "$first" 2>/dev/null && fail "a bspwm reload replaces the previous sxhkd"
kill -0 "$second" 2>/dev/null || fail "the new sxhkd is running"
pass "a bspwm reload replaces this display's sxhkd"

kill -0 "$host_sxhkd" 2>/dev/null || fail "sxhkd on another display ($host_display) survives"
pass "sxhkd on another display survives"
