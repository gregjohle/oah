#!/usr/bin/env bash

if [ -d /sys/class/power_supply/BAT0 ]; then
    CAPACITY=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
    STATUS=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)
    ICON=""
    if [ "$STATUS" = "Charging" ]; then
        ICON=""
    elif [ "$CAPACITY" -le 20 ]; then
        ICON=""
    elif [ "$CAPACITY" -le 50 ]; then
        ICON=""
    fi
    echo "$ICON  ${CAPACITY}%"
else
    echo "  AC"
fi
