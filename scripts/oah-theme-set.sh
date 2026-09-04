#!/bin/bash

if [[ -z $1 ]]; then
  echo "Usage: oah-theme-set.sh <theme-name>"
  exit 1
fi

THEME_NAME=$(echo "$1" | sed -E 's/<[^>]+>//g' | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
THEME_DIR=""

if [[ -d "../omarchy/themes/$THEME_NAME" ]]; then
  THEME_DIR="../omarchy/themes/$THEME_NAME"
elif [[ -d "$HOME/.config/omarchy/themes/$THEME_NAME" ]]; then
  THEME_DIR="$HOME/.config/omarchy/themes/$THEME_NAME"
elif [[ -d "/usr/share/omarchy/themes/$THEME_NAME" ]]; then
  THEME_DIR="/usr/share/omarchy/themes/$THEME_NAME"
else
  echo "Theme '$THEME_NAME' not found."
  exit 1
fi

echo "Applying theme: $THEME_NAME"

# Generate templated configs
./scripts/oah-theme-gen.py "$THEME_DIR/colors.toml" configs/ewwii/

# Reload Ewwii (or relevant UI shell components)
# For Ewwii, this forces re-evaluation of SCSS and variables
eww reload 2>/dev/null || echo "Ewwii not running or eww not found."

echo "Theme '$THEME_NAME' successfully applied!"
