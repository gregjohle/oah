#!/bin/bash
# crash-watcher.sh
# Watches for application crashes via systemd-coredump and triggers a notification

# Use line-buffered grep to catch core dumps as they happen
journalctl -n 0 -f _COMM=systemd-coredump | grep --line-buffered "dumped core" | while read -r line; do
    # Extract the process name from the log line
    # Expected format: "... systemd-coredump[123]: Process 456 (app_name) of user 1000 dumped core."
    PROCESS_NAME=$(echo "$line" | grep -oP 'Process \d+ \(\K[^)]+')
    
    if [ -z "$PROCESS_NAME" ]; then
        PROCESS_NAME="An application"
    fi

    # Trigger an interactive notification and wait for the user's action
    ACTION=$(notify-send "Crash Detected" "$PROCESS_NAME has crashed. Do you want to analyze it with AI?" \
        --action="analyze=Analyze with AI" \
        --icon=dialog-error \
        --app-name="OAH Crash Handler" \
        --wait)
        
    if [ "$ACTION" = "analyze" ]; then
        # Run the handoff script in the background
        bash "$(dirname "$0")/crash-handoff.sh" "$PROCESS_NAME" &
    fi
done
