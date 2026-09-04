#!/bin/bash
IMAGE_PATH=$1

if [[ -z "$IMAGE_PATH" ]]; then
    exit 1
fi

THEME_NAME=$(cat "$HOME/.local/state/oah/current/theme.name" 2>/dev/null)
if [[ -z "$THEME_NAME" ]]; then
    exit 1
fi

BASE_DIR="$(dirname "$0")/.."
THEME_DIR="$BASE_DIR/themes/$THEME_NAME"
if [[ ! -d "$THEME_DIR" ]]; then
    # Fallback paths
    if [[ -d "$HOME/.config/omarchy/themes/$THEME_NAME" ]]; then
        THEME_DIR="$HOME/.config/omarchy/themes/$THEME_NAME"
    elif [[ -d "/usr/share/omarchy/themes/$THEME_NAME" ]]; then
        THEME_DIR="/usr/share/omarchy/themes/$THEME_NAME"
    fi
fi

# Try to match the colors.toml for this specific image if unpacked by timewall
BASENAME=$(basename "$IMAGE_PATH")
FILENAME_NOEXT="${BASENAME%.*}"

COLORS_TOML="$THEME_DIR/colors-$FILENAME_NOEXT.toml"
if [[ ! -f "$COLORS_TOML" ]]; then
    COLORS_TOML="$THEME_DIR/colors.toml"
fi

if [[ -f "$COLORS_TOML" ]]; then
    # Generate the theme UI
    "$BASE_DIR/scripts/oah-theme-gen.py" "$COLORS_TOML" "$BASE_DIR/configs/" ~/.config/oah/templates
    
    # Reload Ewwii to apply CSS changes
    eww reload 2>/dev/null || true
fi

# Set the background image
# Depending on the DE/WM, this might use feh, xwallpaper, or gsettings.
if command -v feh >/dev/null 2>&1; then
    feh --bg-fill "$IMAGE_PATH"
elif command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.background picture-uri "file://$IMAGE_PATH"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$IMAGE_PATH"
else
    echo "No background setter found. Please install feh."
fi

# Save current background path for reference
ln -sf "$IMAGE_PATH" "$HOME/.local/state/oah/current/background"

# Ghostty Spoke
if [[ -f "$BASE_DIR/configs/ghostty/config" ]]; then
    mkdir -p ~/.config/ghostty
    cp "$BASE_DIR/configs/ghostty/config" ~/.config/ghostty/config
fi
"$BASE_DIR/scripts/oah-theme-set-gtk.sh"

# X11 Spoke
if [[ -f "$BASE_DIR/configs/x11/Xresources" ]]; then
    xrdb -merge "$BASE_DIR/configs/x11/Xresources" 2>/dev/null || true
fi
"$BASE_DIR/scripts/oah-theme-set-vscode.sh"
"$BASE_DIR/scripts/oah-theme-set-foot.sh"
"$BASE_DIR/scripts/oah-theme-set-tmux.sh"
"$BASE_DIR/scripts/oah-theme-set-obsidian.sh"
"$BASE_DIR/scripts/oah-theme-set-claude.sh"
"$BASE_DIR/scripts/oah-theme-set-pi.sh"
"$BASE_DIR/scripts/oah-theme-set-keyboard.sh"
"$BASE_DIR/scripts/oah-theme-set-browser.sh"
"$BASE_DIR/scripts/oah-theme-set-xsettingsd.sh"
"$BASE_DIR/scripts/oah-theme-set-bspwm.sh"
"$BASE_DIR/scripts/oah-theme-set-rofi-dunst.sh"
