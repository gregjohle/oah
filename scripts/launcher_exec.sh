#!/bin/bash
# launcher_exec.sh
# Execute the user input command and close the launcher

COMMAND="$1"

if [ -n "$COMMAND" ]; then
    # Run detached from the launcher process tree and suppress output
    setsid sh -c "$COMMAND" >/dev/null 2>&1 &
fi

# Hide the Ewwii launcher after execution
ewwii close launcher
