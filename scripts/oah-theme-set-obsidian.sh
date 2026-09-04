#!/bin/bash
THEME_NAME=$(cat "$HOME/.local/state/oah/current/theme.name" 2>/dev/null)
BASE_DIR="$(dirname "$0")/.."
CURRENT_THEME_DIR="$BASE_DIR/configs/obsidian"

[[ -f $CURRENT_THEME_DIR/obsidian.css ]] || exit 0

jq -r '.vaults | values[].path' ~/.config/obsidian/obsidian.json 2>/dev/null | while read -r vault_path; do
  [[ -d $vault_path/.obsidian ]] || continue

  theme_dir="$vault_path/.obsidian/themes/OAH"
  mkdir -p "$theme_dir"

  [[ -f $theme_dir/manifest.json ]] || cat >"$theme_dir/manifest.json" <<'MANIFEST'
{
  "name": "OAH Theme",
  "version": "1.0.0",
  "minAppVersion": "0.16.0",
  "description": "Automatically syncs with your OAH system theme",
  "author": "OAH"
}
MANIFEST

  cp "$CURRENT_THEME_DIR/obsidian.css" "$theme_dir/theme.css"
done
