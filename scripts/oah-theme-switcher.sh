#!/bin/bash

THEMES_DIR="$(dirname "$0")/../themes"
STATE_FILE="/tmp/oah_theme_state.txt"
PREVIEW_CACHE_DIR="/tmp/oah_theme_previews"

mkdir -p "$PREVIEW_CACHE_DIR"

# Generate list of themes and their previews
update_cache() {
    > "$STATE_FILE"
    for d in "$THEMES_DIR"/*; do
        if [[ -d "$d" ]]; then
            theme_name=$(basename "$d")
            preview=""
            for ext in png jpg jpeg webp gif bmp; do
                if [[ -f "$d/preview.$ext" ]]; then
                    preview="$d/preview.$ext"
                    break
                fi
            done
            if [[ -z "$preview" && -d "$d/backgrounds" ]]; then
                preview=$(find "$d/backgrounds" -type f | head -n 1)
            fi
            if [[ -n "$preview" ]]; then
                echo "$theme_name:$preview" >> "$STATE_FILE"
            fi
        fi
    done
}

get_themes() {
    if [[ ! -f "$STATE_FILE" ]]; then
        update_cache
    fi
    cat "$STATE_FILE"
}

get_current_index() {
    eww get oah_theme_index 2>/dev/null || echo 0
}

set_index() {
    local idx=$1
    local total=$(get_themes | wc -l)
    if (( idx < 0 )); then
        idx=$(( total - 1 ))
    elif (( idx >= total )); then
        idx=0
    fi
    
    local line=$(get_themes | sed -n "$((idx + 1))p")
    local name=$(echo "$line" | cut -d':' -f1)
    local preview=$(echo "$line" | cut -d':' -f2)
    
    eww update oah_theme_index=$idx
    eww update oah_theme_name="$name"
    eww update oah_theme_preview="$preview"
}

case "$1" in
    toggle)
        if eww active-windows | grep -q "theme_switcher"; then
            eww close theme_switcher
        else
            update_cache
            set_index 0
            eww open theme_switcher
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
        name=$(eww get oah_theme_name)
        eww close theme_switcher
        "$(dirname "$0")/oah-theme-set.sh" "$name"
        ;;
    *)
        echo "Usage: $0 {toggle|next|prev|apply}"
        ;;
esac
