#!/bin/bash
BASE_DIR="$(dirname "$0")/.."

if [[ -f "$BASE_DIR/configs/rofi/config.rasi" ]]; then
    mkdir -p ~/.config/rofi
    cp "$BASE_DIR/configs/rofi/config.rasi" ~/.config/rofi/config.rasi
fi

if [[ -f "$BASE_DIR/configs/dunst/dunstrc" ]]; then
    mkdir -p ~/.config/dunst
    cp "$BASE_DIR/configs/dunst/dunstrc" ~/.config/dunst/dunstrc
    if pgrep -x dunst >/dev/null; then
        killall dunst
        dunst &
    fi
fi
