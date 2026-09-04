#!/bin/bash
BASE_DIR="$(dirname "$0")/.."
CHROMIUM_THEME="$BASE_DIR/configs/browser/chromium.theme"
THEME_HEX_COLOR="202124" # Default fallback

if [[ -f $CHROMIUM_THEME ]]; then
  THEME_HEX_COLOR=$(cat "$CHROMIUM_THEME")
fi

refresh_running_browser() {
  local process="$1"
  local command="$2"
  local pgrep_args="${3:-}"

  if command -v "$command" >/dev/null && pgrep $pgrep_args "$process" >/dev/null; then
    "$command" --refresh-platform-policy --no-startup-window &>/dev/null
  fi
}

failed=0
"$BASE_DIR/scripts/oah-theme-set-browser-policy.sh" "${THEME_HEX_COLOR#\#}" || failed=1

refresh_running_browser chromium chromium -x
refresh_running_browser chrome google-chrome-stable -x || refresh_running_browser chrome google-chrome -x
refresh_running_browser msedge microsoft-edge-stable -x
refresh_running_browser brave brave -x
refresh_running_browser /opt/brave-origin-bin/ brave-origin -f

exit "$failed"
