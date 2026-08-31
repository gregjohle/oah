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

# Documenting the expected I/O behavior for users:
# If you are using a tool that requires specific flags rather than standard piped input,
# you can define the entire execution template via OAH_AI_COMMAND. 
# For example: OAH_AI_COMMAND="my_agent --file \$TRACE_FILE --prompt \"\$PROMPT\""
if [ -n "$OAH_AI_COMMAND" ]; then
    EXEC_CMD="$OAH_AI_COMMAND"
else
    EXEC_CMD='cat "$TRACE_FILE" | $AI_AGENT "$PROMPT"'
fi

# Open Ghostty and launch the AI agent securely.
export PROCESS_NAME AI_AGENT TRACE_FILE PROMPT EXEC_CMD
ghostty -e bash -c 'echo "Analyzing crash for $PROCESS_NAME..."; eval "$EXEC_CMD"; echo ""; echo "Press any key to exit..."; read -n 1' &
