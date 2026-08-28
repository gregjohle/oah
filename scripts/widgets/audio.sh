#!/usr/bin/env bash

if command -v wpctl >/dev/null; then
    VOL_STR=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
    VOL=$(echo "$VOL_STR" | awk '{print int($2 * 100)}')
    MUTED=$(echo "$VOL_STR" | grep -i "MUTED")
    
    if [ -n "$MUTED" ]; then
        echo "  Muted"
    elif [ "$VOL" -ge 70 ]; then
        echo "  ${VOL}%"
    elif [ "$VOL" -ge 30 ]; then
        echo "  ${VOL}%"
    else
        echo "  ${VOL}%"
    fi
else
    echo "  --"
fi
