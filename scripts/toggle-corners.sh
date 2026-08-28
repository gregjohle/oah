#!/usr/bin/env bash

# Paths
PICOM_CONF="$(dirname "$0")/../configs/picom/picom.conf"

# Check if the config exists
if [ ! -f "$PICOM_CONF" ]; then
    echo "Error: picom.conf not found at $PICOM_CONF"
    exit 1
fi

# Determine current state by reading the config
if grep -q "corner-radius = 0;" "$PICOM_CONF"; then
    # Currently sharp, switch to rounded
    sed -i 's/corner-radius = 0;/corner-radius = 12;/g' "$PICOM_CONF"
    STATE="Rounded"
else
    # Currently rounded, switch to sharp
    sed -i 's/corner-radius = [0-9]\+;/corner-radius = 0;/g' "$PICOM_CONF"
    STATE="Sharp"
fi

# Reload picom gracefully using SIGUSR1
if pgrep -x picom > /dev/null; then
    killall -USR1 picom
fi

# Optional: Trigger an OSD notification using our future Ewwii OSD
# ewwii update osd_message="Corners: $STATE"
echo "Corners set to $STATE"
