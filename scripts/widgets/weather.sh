#!/usr/bin/env bash

# Fetch weather from wttr.in with timeout
WEATHER=$(curl -s --max-time 5 "wttr.in/?format=%c+%t" 2>/dev/null)
if [ -n "$WEATHER" ] && ! echo "$WEATHER" | grep -q "Unknown"; then
    echo "$WEATHER"
else
    echo "  --°"
fi
