#!/bin/bash
if ! pgrep -x foot >/dev/null; then
  exit 0
fi

BASE_DIR="$(dirname "$0")/.."
foot_osc=$("$BASE_DIR/scripts/oah-theme-osc.sh")
[[ -n $foot_osc ]] || exit 0

for foot_pid in $(pgrep -x foot); do
  for child_pid in $(pgrep -P "$foot_pid"); do
    tty=$(readlink "/proc/$child_pid/fd/1" 2>/dev/null)
    [[ $tty == /dev/pts/* ]] && printf '%b' "$foot_osc" >"$tty"
  done
done
