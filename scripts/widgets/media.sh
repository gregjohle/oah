#!/usr/bin/env bash

# Use deflisten for media
while true; do
    playerctl metadata --format '{{status}} {{artist}} - {{title}}' --follow 2>/dev/null | while read -r line; do
        STATUS=$(echo "$line" | awk '{print $1}')
        TEXT=$(echo "$line" | cut -d' ' -f2- | cut -c 1-40)
        if [ "$STATUS" = "Playing" ] || [ "$STATUS" = "Paused" ]; then
            echo "  $TEXT"
        else
            echo ""
        fi
    done
    sleep 2
done
