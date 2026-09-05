#!/bin/bash
QUERY="$1"
# Ensure we don't crash if jq is missing, just fallback, but we use jq in onaccept anyway.
DIR="$(dirname "$0")"
RES=$("$DIR/oah-menu-daemon.py" "$QUERY")
ewwii update oah_menu_results="$RES"
