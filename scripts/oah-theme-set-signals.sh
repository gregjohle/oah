#!/bin/bash
BASE_DIR="$(dirname "$0")/.."

# Btop
if [[ -f "$BASE_DIR/configs/btop/btop.theme" ]]; then
    mkdir -p ~/.config/btop/themes
    cp "$BASE_DIR/configs/btop/btop.theme" ~/.config/btop/themes/oah.theme
    # Update btop config to use oah.theme if not already
    if [[ -f ~/.config/btop/btop.conf ]]; then
        sed -i 's/^color_theme = .*/color_theme = "oah"/' ~/.config/btop/btop.conf
    fi
    pkill -SIGUSR2 btop 2>/dev/null || true
fi

# Helix
if [[ -f "$BASE_DIR/configs/helix/helix.toml" ]]; then
    mkdir -p ~/.config/helix/themes
    cp "$BASE_DIR/configs/helix/helix.toml" ~/.config/helix/themes/oah.toml
    pkill -USR1 helix 2>/dev/null || true
fi

# Opencode
killall -SIGUSR2 opencode 2>/dev/null || true

# Neovim & Gum & Shell
# These usually read the generated config on startup or source it, 
# so we just ensure they exist in ~/.local/state/oah/current/theme/
# for backward compatibility with Omarchy scripts.
mkdir -p "$HOME/.local/state/oah/current/theme"
[[ -f "$BASE_DIR/configs/neovim/neovim.lua" ]] && cp "$BASE_DIR/configs/neovim/neovim.lua" "$HOME/.local/state/oah/current/theme/neovim.lua"
[[ -f "$BASE_DIR/configs/gum/gum_env.lua" ]] && cp "$BASE_DIR/configs/gum/gum_env.lua" "$HOME/.local/state/oah/current/theme/gum_env.lua"
[[ -f "$BASE_DIR/configs/shell/shell.toml" ]] && cp "$BASE_DIR/configs/shell/shell.toml" "$HOME/.local/state/oah/current/theme/shell.toml"
