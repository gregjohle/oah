#!/bin/bash
if ! command -v tmux >/dev/null 2>&1 || ! tmux list-sessions >/dev/null 2>&1; then
  exit 0
fi

BASE_DIR="$(dirname "$0")/.."
THEME_NAME=$(cat "$HOME/.local/state/oah/current/theme.name" 2>/dev/null)
COLORS_TOML="$BASE_DIR/themes/$THEME_NAME/colors.toml"

declare -A COLORS
while IFS='=' read -r key value; do
    key=$(echo "$key" | tr -d ' "')
    value=$(echo "$value" | tr -d ' "')
    [[ -n "$key" && -n "$value" ]] && COLORS[$key]="$value"
done < "$COLORS_TOML"

foreground="${COLORS[foreground]:-}"
background="${COLORS[background]:-}"
cursor="${COLORS[accent]:-}"

if [[ -n $foreground && -n $background ]]; then
  tmux set-option -g window-style "fg=$foreground,bg=$background" 2>/dev/null || true
  tmux set-option -g window-active-style "fg=$foreground,bg=$background" 2>/dev/null || true
  if [[ -n $cursor ]]; then
    tmux set-option -g cursor-colour "$cursor" 2>/dev/null || true
  fi
fi

theme_osc=$("$BASE_DIR/scripts/oah-theme-osc.sh")
if [[ -n $theme_osc ]]; then
  while IFS= read -r pane_tty; do
    [[ $pane_tty == /dev/pts/* ]] || continue
    printf '%b' "$theme_osc" >"$pane_tty" 2>/dev/null || true
  done < <(tmux list-panes -a -F "#{pane_tty}" 2>/dev/null | sort -u)
fi

while IFS= read -r pane_tty; do
  [[ $pane_tty == /dev/pts/* ]] || continue
  tpgid=$(ps -o tpgid= -t "${pane_tty#/dev/}" 2>/dev/null | awk 'NF && $1 > 0 { print $1; exit }')
  [[ -n $tpgid ]] || continue
  kill -WINCH "-$tpgid" 2>/dev/null || true
done < <(tmux list-panes -a -F "#{pane_tty}" 2>/dev/null | sort -u)

while IFS= read -r client; do
  [[ -n $client ]] || continue
  tmux refresh-client -t "$client" 2>/dev/null || true
done < <(tmux list-clients -F "#{client_name}" 2>/dev/null)
