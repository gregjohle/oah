#!/bin/bash
THEME_NAME=$(cat "$HOME/.local/state/oah/current/theme.name" 2>/dev/null)
if [[ -n "$THEME_NAME" ]]; then
    "$(dirname "$0")/oah-theme-set.sh" "$THEME_NAME"
fi
