#!/bin/bash
BASE_DIR="$(dirname "$0")/.."
CLAUDE_SOURCE_PATH="$BASE_DIR/configs/claude/claude.json"
CLAUDE_CONFIG_DIR="$HOME/.claude"
CLAUDE_THEME_PATH="$CLAUDE_CONFIG_DIR/themes/oah.json"
CLAUDE_SETTINGS_PATH="$CLAUDE_CONFIG_DIR/settings.json"

if [[ ! -f $CLAUDE_SOURCE_PATH ]]; then
  exit 0
fi

if [[ ! -d $CLAUDE_CONFIG_DIR ]]; then
  exit 0
fi

write_setting_theme() {
  local tmp
  if [[ -f $CLAUDE_SETTINGS_PATH ]]; then
    tmp=$(mktemp "$CLAUDE_SETTINGS_PATH.XXXXXX")
    jq '.theme = "custom:oah"' "$CLAUDE_SETTINGS_PATH" >"$tmp"
    mv "$tmp" "$CLAUDE_SETTINGS_PATH"
  else
    cat >"$CLAUDE_SETTINGS_PATH" <<JSON
{
  "theme": "custom:oah"
}
JSON
  fi
}

mkdir -p "$(dirname "$CLAUDE_THEME_PATH")"
tmp=$(mktemp "$CLAUDE_THEME_PATH.XXXXXX")
cp "$CLAUDE_SOURCE_PATH" "$tmp"
mv "$tmp" "$CLAUDE_THEME_PATH"

write_setting_theme
