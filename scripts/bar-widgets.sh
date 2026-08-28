#!/usr/bin/env bash

# Helper script to fetch data for the custom Ewwii bar widgets

case "$1" in
    media)
        # Check if playerctl is available
        if command -v playerctl >/dev/null; then
            STATUS=$(playerctl status 2>/dev/null)
            if [ "$STATUS" = "Playing" ] || [ "$STATUS" = "Paused" ]; then
                # Output format:  Artist - Title
                ICON=""
                TEXT=$(playerctl metadata --format '{{ artist }} - {{ title }}' | cut -c 1-40)
                echo "$ICON  $TEXT"
            else
                echo ""
            fi
        else
            echo ""
        fi
        ;;
        
    weather)
        # Fetch weather from wttr.in
        WEATHER=$(curl -s "wttr.in/?format=%c+%t" 2>/dev/null)
        if [ -n "$WEATHER" ] && ! echo "$WEATHER" | grep -q "Unknown"; then
            echo "$WEATHER"
        else
            echo "  --°"
        fi
        ;;
        
    battery)
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
        ;;
        
    audio)
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
        ;;
        
    network)
        if command -v nmcli >/dev/null; then
            WIFI=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)
            if [ -n "$WIFI" ]; then
                echo "  $WIFI"
            else
                # Check for ethernet
                ETH=$(ip link show eth0 2>/dev/null | grep "state UP")
                if [ -n "$ETH" ]; then
                    echo "  Wired"
                else
                    echo "  Offline"
                fi
            fi
        else
            echo "  --"
        fi
        ;;
        
    bluetooth)
        if command -v bluetoothctl >/dev/null; then
            POWER=$(bluetoothctl show 2>/dev/null | grep "Powered: yes")
            if [ -n "$POWER" ]; then
                # Check if connected
                CONNECTED=$(bluetoothctl info 2>/dev/null | grep "Connected: yes")
                if [ -n "$CONNECTED" ]; then
                    # Get device name
                    NAME=$(bluetoothctl info 2>/dev/null | grep "Name:" | cut -d' ' -f2-)
                    echo "  $NAME"
                else
                    echo "  On"
                fi
            else
                echo "  Off"
            fi
        else
            echo "  --"
        fi
        ;;
        
    *)
        echo ""
        ;;
esac
