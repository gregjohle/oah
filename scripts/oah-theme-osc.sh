#!/bin/bash
# Print OSC sequences for an OAH color theme
THEME_NAME=$(cat "$HOME/.local/state/oah/current/theme.name" 2>/dev/null)
if [[ -z "$THEME_NAME" ]]; then
    exit 1
fi
BASE_DIR="$(dirname "$0")/.."
THEME_DIR="$BASE_DIR/themes/$THEME_NAME"
COLORS_TOML="$THEME_DIR/colors.toml"

if [[ ! -f "$COLORS_TOML" ]]; then
    exit 0
fi

# Use grep/awk to extract key-value pairs
declare -A COLORS
while IFS='=' read -r key value; do
    key=$(echo "$key" | tr -d ' "')
    value=$(echo "$value" | tr -d ' "')
    [[ -n "$key" && -n "$value" ]] && COLORS[$key]="$value"
done < "$COLORS_TOML"

emit_osc() {
    local code="$1"
    local key="$2"
    [[ -n ${COLORS[$key]:-} ]] || return 0
    printf '\033]%s;%s\007' "$code" "${COLORS[$key]}"
}

emit_osc 10 foreground
emit_osc 11 background
emit_osc 12 accent # cursor
emit_osc 17 selection
emit_osc 19 foreground # selection_foreground

for i in {0..7}; do
    name=""
    case $i in
        0) name="background" ;;
        1) name="red" ;;
        2) name="green" ;;
        3) name="yellow" ;;
        4) name="blue" ;;
        5) name="magenta" ;;
        6) name="cyan" ;;
        7) name="foreground" ;;
    esac
    [[ -n ${COLORS[$name]:-} ]] && printf '\033]4;%d;%s\007' "$i" "${COLORS[$name]}"
done

for i in {8..15}; do
    name=""
    case $i in
        8) name="muted" ;;
        9) name="bright_red" ;;
        10) name="bright_green" ;;
        11) name="bright_yellow" ;;
        12) name="bright_blue" ;;
        13) name="bright_magenta" ;;
        14) name="bright_cyan" ;;
        15) name="bright_foreground" ;;
    esac
    [[ -n ${COLORS[$name]:-} ]] && printf '\033]4;%d;%s\007' "$i" "${COLORS[$name]}"
done
