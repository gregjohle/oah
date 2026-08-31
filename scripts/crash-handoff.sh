#!/bin/bash
# crash-handoff.sh
# Extracts the stack trace via coredumpctl and pipes it to the configured AI agent in Ghostty

PROCESS_NAME="$1"

# Determine the AI agent to use (open-ended for the user)
# Allows the user to set OAH_AI_AGENT in their environment or globally.
# Examples: "agy", "fabric", "chatgpt-cli", "gh copilot"
AI_AGENT="${OAH_AI_AGENT:-agy}" 

TRACE_FILE="/tmp/crash_trace_${PROCESS_NAME}_$(date +%s).txt"

# Extract the most recent core dump info for this process
coredumpctl info -1 "$PROCESS_NAME" > "$TRACE_FILE" 2>/dev/null

if [ ! -s "$TRACE_FILE" ]; then
    notify-send "AI Crash Handler" "Could not extract stack trace for $PROCESS_NAME." --icon=dialog-warning
    exit 1
fi

# Construct the prompt
PROMPT="The application $PROCESS_NAME just crashed. Here is the stack trace from coredumpctl. Please analyze it and explain the root cause and potential fixes."

# Open Ghostty and launch the AI agent. 
# We pipe the trace file into the agent and pass the prompt as an argument.
# Using a generic approach that works with most standard CLI AI tools.
ghostty -e bash -c "echo 'Analyzing crash for $PROCESS_NAME using $AI_AGENT...'; cat '$TRACE_FILE' | $AI_AGENT '$PROMPT'; echo ''; echo 'Press any key to exit...'; read -n 1" &
