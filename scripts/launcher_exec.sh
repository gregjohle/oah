#!/bin/bash
# launcher_exec.sh
# Execute the user input command and close the launcher

COMMAND="$1"

if [ -n "$COMMAND" ]; then
    # Run the command detached
    eval "$COMMAND" &
fi

# Hide the Ewwii launcher after execution
ewwii close launcher
