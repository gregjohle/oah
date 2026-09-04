#!/bin/bash
BASE_DIR="$(dirname "$0")/.."
F16_THEME="$BASE_DIR/configs/keyboard/keyboard.rgb"
if command -v framework_tool >/dev/null 2>&1 && [[ -f $F16_THEME ]]; then
  color=$(sed 's/^#//' "$F16_THEME")
  [[ $color =~ ^[0-9A-Fa-f]{6}$ ]] || exit 0
  # We assume framework_tool supports this flag; omitting it if not installed is safe.
  framework_tool --macropad-backlight-color "$color" 2>/dev/null || true
fi
