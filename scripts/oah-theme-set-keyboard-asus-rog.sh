#!/bin/bash
BASE_DIR="$(dirname "$0")/.."
ASUSCTL_THEME="$BASE_DIR/configs/keyboard/keyboard.rgb"
if command -v asusctl >/dev/null 2>&1 && [[ -f $ASUSCTL_THEME ]]; then
  color=$(sed 's/^#//' "$ASUSCTL_THEME")
  [[ $color =~ ^[0-9A-Fa-f]{6}$ ]] || exit 0
  asusctl aura effect static -c "$color"
fi
