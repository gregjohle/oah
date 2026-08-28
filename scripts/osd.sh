#!/usr/bin/env bash

# Usage: ./osd.sh <icon> <value> <message> [show_progress]
# Example: ./osd.sh "" 75 "75%" "true"

ICON=$1
VALUE=$2
MESSAGE=$3
SHOW_PROGRESS=${4:-"true"}

# Update Ewwii variables
ewwii update osd_icon="$ICON"
ewwii update osd_value="$VALUE"
ewwii update osd_message="$MESSAGE"
ewwii update osd_show_progress="$SHOW_PROGRESS"

# Open the OSD
ewwii open osd

# Kill any existing hide timer
pkill -f "sleep 1.2.*ewwii close osd" || true

# Start a new hide timer in the background
(
  sleep 1.2
  ewwii close osd
) &
