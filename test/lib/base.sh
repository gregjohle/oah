#!/bin/bash
# Helpers for OAH's own tests (test/oah.d/*-test.sh). Same conventions as
# upstream's test/shell.d/base-test.sh: TAP-style "ok"/"not ok" lines, a test
# file exits at its first failure, and "# SKIP" marks a check that couldn't run.

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  echo "source test/lib/base.sh from a test; do not run it directly" >&2
  exit 1
fi

OAH_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
export OAH_ROOT

pass() { printf 'ok - %s\n' "$1"; }
skip() { printf 'ok - %s # SKIP\n' "$1"; }

fail() {
  [[ -n ${2:-} ]] && printf '%s\n' "$2" >&2
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

# Skip the rest of the file when a command it needs is missing.
require_command() {
  command -v "$1" >/dev/null 2>&1 && return 0
  skip "$1 not installed; skipping ${2:-$(basename "$0")}"
  exit 0
}

# A scratch directory removed when the test exits. Usage: new_scratch dir_var
TEST_SCRATCH_DIRS=()
# Must never fail: set -e applies inside EXIT traps, and a failing command
# there turns a passing test file into exit 1.
test_cleanup() {
  local d
  for d in "${TEST_SCRATCH_DIRS[@]}"; do rm -rf -- "$d" || true; done
  return 0
}
trap test_cleanup EXIT
new_scratch() {
  local -n _ref=$1
  _ref=$(mktemp -d)
  TEST_SCRATCH_DIRS+=("$_ref")
}

# Start Xvfb on a free display and export DISPLAY; stopped at exit.
TEST_XVFB_PID=""
start_xvfb() {
  require_command Xvfb
  local n
  for n in {120..159}; do
    [[ -e /tmp/.X11-unix/X$n || -e /tmp/.X$n-lock ]] && continue
    Xvfb ":$n" -screen 0 1280x800x24 -nolisten tcp >/dev/null 2>&1 &
    TEST_XVFB_PID=$!
    for _ in {1..50}; do
      [[ -e /tmp/.X11-unix/X$n ]] && { export DISPLAY=":$n"; trap 'kill "$TEST_XVFB_PID" 2>/dev/null || true; test_cleanup' EXIT; return 0; }
      sleep 0.1
    done
    kill "$TEST_XVFB_PID" 2>/dev/null
    fail "Xvfb started on :$n"
  done
  fail "found a free X display for Xvfb"
}
