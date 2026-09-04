#!/bin/bash

STATE_FILE="/tmp/oah_bg_state.txt"
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

# Generate list of backgrounds
update_cache() {
    > "$STATE_FILE"
    if [[ -d "$THEME_DIR/backgrounds" ]]; then
        for img in "$THEME_DIR/backgrounds"/*; do
            if [[ -f "$img" ]]; then
                name=$(basename "$img")
                echo "$name:$img" >> "$STATE_FILE"
            fi
        done
    fi
}

get_bgs() {
    if [[ ! -f "$STATE_FILE" ]]; then
        update_cache
    fi
    cat "$STATE_FILE"
}

get_current_index() {
    eww get oah_bg_index 2>/dev/null || echo 0
}

set_index() {
    local idx=$1
    local total=$(get_bgs | wc -l)
    if (( total == 0 )); then
        return
    fi
    if (( idx < 0 )); then
        idx=$(( total - 1 ))
    elif (( idx >= total )); then
        idx=0
    fi
    
    local line=$(get_bgs | sed -n "$((idx + 1))p")
    local name=$(echo "$line" | cut -d':' -f1)
    local img=$(echo "$line" | cut -d':' -f2)
    
    eww update oah_bg_index=$idx
    eww update oah_bg_name="$name"
    eww update oah_bg_path="$img"
}

case "$1" in
    toggle)
        if eww active-windows | grep -q "bg_switcher"; then
            eww close bg_switcher
        else
            update_cache
            set_index 0
            eww open bg_switcher
        fi
        ;;
    next)
        idx=$(get_current_index)
        set_index $((idx + 1))
        ;;
    prev)
        idx=$(get_current_index)
        set_index $((idx - 1))
        ;;
    apply)
        img=$(eww get oah_bg_path)
        eww close bg_switcher
        if [[ -n "$img" && -f "$img" ]]; then
            "$(dirname "$0")/theme-sync.sh" "$img"
        fi
        ;;
    *)
        echo "Usage: $0 {toggle|next|prev|apply}"
        ;;
esac
