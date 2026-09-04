#!/bin/bash
if ! command -v bspc >/dev/null 2>&1; then
    exit 0
fi

THEME_NAME=$(cat "$HOME/.local/state/oah/current/theme.name" 2>/dev/null)
if [[ -z "$THEME_NAME" ]]; then
    exit 1
fi

BASE_DIR="$(dirname "$0")/.."
COLORS_TOML="$BASE_DIR/themes/$THEME_NAME/colors.toml"
if [[ ! -f "$COLORS_TOML" ]]; then
    exit 0
fi

declare -A COLORS
while IFS='=' read -r key value; do
    key=$(echo "$key" | tr -d ' "')
    value=$(echo "$value" | tr -d ' "')
    [[ -n "$key" && -n "$value" ]] && COLORS[$key]="$value"
done < "$COLORS_TOML"

ACTIVE_COLOR="${COLORS[accent]:-}"
INACTIVE_COLOR="${COLORS[darker_background]:-}"
URGENT_COLOR="${COLORS[red]:-}"

if [[ -n "$ACTIVE_COLOR" ]]; then
    bspc config focused_border_color "$ACTIVE_COLOR"
fi
if [[ -n "$INACTIVE_COLOR" ]]; then
    bspc config normal_border_color "$INACTIVE_COLOR"
    bspc config active_border_color "$INACTIVE_COLOR"
fi
if [[ -n "$URGENT_COLOR" ]]; then
    bspc config urgent_border_color "$URGENT_COLOR"
    bspc config presel_feedback_color "$URGENT_COLOR"
fi
