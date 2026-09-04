#!/bin/bash

# GTK Spoke
THEME_NAME=$(cat "$HOME/.local/state/oah/current/theme.name" 2>/dev/null)
if [[ -z "$THEME_NAME" ]]; then
    exit 1
fi

BASE_DIR="$(dirname "$0")/.."
THEME_DIR="$BASE_DIR/themes/$THEME_NAME"
if [[ ! -d "$THEME_DIR" ]]; then
    if [[ -d "$HOME/.config/omarchy/themes/$THEME_NAME" ]]; then
        THEME_DIR="$HOME/.config/omarchy/themes/$THEME_NAME"
    elif [[ -d "/usr/share/omarchy/themes/$THEME_NAME" ]]; then
        THEME_DIR="/usr/share/omarchy/themes/$THEME_NAME"
    fi
fi

COLORS_TOML="$THEME_DIR/colors.toml"
if [[ ! -f "$COLORS_TOML" ]]; then
    exit 0
fi

# Extract mode
MODE=$(grep 'mode *=' "$COLORS_TOML" | head -n 1 | awk -F'"' '{print $2}')
if [[ -z "$MODE" ]]; then
    MODE="dark" # fallback
fi

if command -v gsettings >/dev/null 2>&1; then
    if [[ "$MODE" == "light" ]]; then
        gsettings set org.gnome.desktop.interface color-scheme "prefer-light"
        gsettings set org.gnome.desktop.interface gtk-theme "Adwaita"
    else
        gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
        gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
    fi
fi


# Electron / Dconf Spoke
if command -v dconf >/dev/null 2>&1; then
    if [[ "$MODE" == "light" ]]; then
        dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'"
    else
        dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
    fi
fi

# Change gnome icon theme color
GNOME_ICONS_THEME="$THEME_DIR/icons.theme"
ICON_THEME="Adwaita"
if [[ -f "$GNOME_ICONS_THEME" ]]; then
  ICON_THEME=$(cat "$GNOME_ICONS_THEME")
fi

if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
fi
