#!/usr/bin/env bash

if command -v nmcli >/dev/null; then
    WIFI=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)
    if [ -n "$WIFI" ]; then
        echo "  $WIFI"
    else
        # Dynamic check for default interface
        DEFAULT_IFACE=$(ip route show default 2>/dev/null | awk '/default/ {print $5}' | head -n 1)
        if [ -n "$DEFAULT_IFACE" ]; then
            ETH=$(ip link show "$DEFAULT_IFACE" 2>/dev/null | grep "state UP")
            if [ -n "$ETH" ]; then
                echo "  Wired"
            else
                echo "  Offline"
            fi
        else
            echo "  Offline"
        fi
    fi
else
    echo "  --"
fi
