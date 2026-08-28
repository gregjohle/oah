#!/usr/bin/env bash

# Usage: ./osd.sh <icon> <value> <message> [show_progress]
# Example: ./osd.sh "" 75 "75%" "true"

ICON=$1
VALUE=$2
MESSAGE=$3
SHOW_PROGRESS=${4:-"true"}
PID_FILE="/tmp/oah_osd_timer.pid"

# Update Ewwii variables in a single IPC call
ewwii update osd_icon="$ICON" osd_value="$VALUE" osd_message="$MESSAGE" osd_show_progress="$SHOW_PROGRESS"

# Open the OSD
ewwii open osd

# Kill any existing hide timer
if [ -f "$PID_FILE" ]; then
    kill $(cat "$PID_FILE") 2>/dev/null || true
fi

# Start a new hide timer in the background
(
  sleep 1.2
  ewwii close osd
) &
echo $! > "$PID_FILE"
