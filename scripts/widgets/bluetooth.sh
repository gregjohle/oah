#!/usr/bin/env bash

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
