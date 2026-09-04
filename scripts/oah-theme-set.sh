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
elif [[ -d "themes/$THEME_NAME" ]]; then
  THEME_DIR="themes/$THEME_NAME"
else
  echo "Theme '$THEME_NAME' not found."
  exit 1
fi

echo "Applying theme: $THEME_NAME"

mkdir -p "$HOME/.local/state/oah/current"
echo "$THEME_NAME" > "$HOME/.local/state/oah/current/theme.name"

# Generate templated configs
"$(dirname "$0")/oah-theme-gen.py" "$THEME_DIR/colors.toml" configs/

# Check if this theme has a .heic file for timewall
HEIC_FILE=""
if ls "$THEME_DIR"/*.heic 1> /dev/null 2>&1; then
    HEIC_FILE=$(ls "$THEME_DIR"/*.heic | head -n 1)
fi

# Kill existing timewall if running
pkill -f "timewall set -d" || true

if [[ -n "$HEIC_FILE" ]]; then
    echo "Starting Timewall for $HEIC_FILE"
    # Ensure config points setter to our sync script
    mkdir -p ~/.config/timewall
    cat << 'CFG' > ~/.config/timewall/config.toml
[setter]
command = ['/home/greg/Documents/Omarchy At Home Project/oah/scripts/theme-sync.sh', '%f']
CFG
    timewall set -d "$HEIC_FILE" &
else
    # Set static background (assuming 01-custom.jpg or similar)
    BG=$(find "$THEME_DIR/backgrounds" -type f | head -n 1)
    if [[ -n "$BG" ]]; then
        "$(dirname "$0")/theme-sync.sh" "$BG"
    fi
fi

eww reload 2>/dev/null || true

echo "Theme '$THEME_NAME' successfully applied!"

# Ghostty Spoke
if [[ -f configs/ghostty/config ]]; then
    mkdir -p ~/.config/ghostty
    cp configs/ghostty/config ~/.config/ghostty/config
fi
"$(dirname "$0")/oah-theme-set-gtk.sh"

# X11 Spoke
if [[ -f configs/x11/Xresources ]]; then
    xrdb -merge configs/x11/Xresources 2>/dev/null || true
fi
"$(dirname "$0")/oah-theme-set-vscode.sh"
