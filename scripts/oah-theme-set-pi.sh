#!/bin/bash
BASE_DIR="$(dirname "$0")/.."
PI_SOURCE_PATH="$BASE_DIR/configs/pi/pi.json"
PI_AGENT_DIR="$HOME/.pi/agent"
PI_THEME_DIR="$PI_AGENT_DIR/themes"
PI_THEME_PATH="$PI_THEME_DIR/oah-system.json"
PI_SETTINGS_PATH="$PI_AGENT_DIR/settings.json"

if [[ ! -f $PI_SOURCE_PATH ]]; then
  exit 0
fi

if [[ ! -d $PI_AGENT_DIR ]]; then
  exit 0
fi

write_setting_theme() {
  local tmp
  if [[ -f $PI_SETTINGS_PATH ]]; then
    tmp=$(mktemp "$PI_SETTINGS_PATH.XXXXXX")
    jq '.theme = "oah-system"' "$PI_SETTINGS_PATH" >"$tmp"
    mv "$tmp" "$PI_SETTINGS_PATH"
  else
    cat >"$PI_SETTINGS_PATH" <<JSON
{
  "theme": "oah-system"
}
JSON
  fi
}

mkdir -p "$PI_THEME_DIR"
tmp=$(mktemp "$PI_THEME_PATH.XXXXXX")
cp "$PI_SOURCE_PATH" "$tmp"
mv "$tmp" "$PI_THEME_PATH"

write_setting_theme
