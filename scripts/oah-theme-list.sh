#!/bin/bash
BASE_DIR="$(dirname "$0")/.."
{
  if [[ -d "$HOME/.config/omarchy/themes" ]]; then
    find "$HOME/.config/omarchy/themes/" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) -printf '%f\n' 2>/dev/null
  fi
  if [[ -d "$BASE_DIR/themes" ]]; then
    find "$BASE_DIR/themes/" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null
  fi
  if [[ -d "/usr/share/omarchy/themes" ]]; then
    find "/usr/share/omarchy/themes/" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null
  fi
} | sort -u
