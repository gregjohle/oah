#!/bin/bash

# VSCode Spoke
THEME_NAME=$(cat "$HOME/.local/state/oah/current/theme.name" 2>/dev/null)
if [[ -z "$THEME_NAME" ]]; then
    exit 1
fi

BASE_DIR="$(dirname "$0")/.."
THEME_DIR="$BASE_DIR/themes/$THEME_NAME"
if [[ ! -d "$THEME_DIR" ]]; then
    if [[ -d "$HOME/.config/omarchy/themes/$THEME_NAME" ]]; then
        THEME_DIR="$HOME/.config/omarchy/themes/$THEME_NAME"
    elif [[ -d "/usr/share/omarchy/themes/$THEME_NAME" ]]; then
        THEME_DIR="/usr/share/omarchy/themes/$THEME_NAME"
    fi
fi

VS_CODE_THEME_DESCRIPTOR="$BASE_DIR/configs/vscode/vscode.json"
GENERATED_THEME="$BASE_DIR/configs/vscode/vscode-theme.json"

if [[ ! -f "$GENERATED_THEME" ]]; then
    exit 0
fi

GENERATED_EXTENSION_NAME="oah-theme"
GENERATED_EXTENSION_ID="local.$GENERATED_EXTENSION_NAME"
GENERATED_EXTENSION_VERSION="1.0.0"

register_generated_extension() {
  local ext_dir="$1"
  local ext_base extensions_file obsolete_file relative tmp

  ext_base=$(dirname "$ext_dir")
  extensions_file="$ext_base/extensions.json"
  obsolete_file="$ext_base/.obsolete"
  relative=$(basename "$ext_dir")

  if [[ -f $obsolete_file ]]; then
    tmp=$(mktemp)
    if jq --arg key "$GENERATED_EXTENSION_ID-$GENERATED_EXTENSION_VERSION" 'del(.[$key])' "$obsolete_file" >"$tmp"; then
      mv "$tmp" "$obsolete_file"
      [[ $(jq 'length' "$obsolete_file") == "0" ]] && rm -f "$obsolete_file"
    else
      rm -f "$tmp"
    fi
  fi

  [[ -f $extensions_file ]] || printf '[]\n' >"$extensions_file"

  tmp=$(mktemp)
  if jq \
    --arg id "$GENERATED_EXTENSION_ID" \
    --arg version "$GENERATED_EXTENSION_VERSION" \
    --arg fs_path "$ext_dir" \
    --arg external "file://$ext_dir" \
    --arg relative "$relative" \
    'map(select(.identifier.id != $id)) + [{
      identifier: { id: $id },
      version: $version,
      location: {
        "$mid": 1,
        fsPath: $fs_path,
        external: $external,
        path: $fs_path,
        scheme: "file"
      },
      relativeLocation: $relative
    }]' \
    "$extensions_file" >"$tmp"; then
    mv "$tmp" "$extensions_file"
  else
    rm -f "$tmp"
  fi
}

install_generated_extension() {
  local ext_dir="$1"
  local theme_type ui_theme

  theme_type=$(jq -r '.type // "dark"' "$GENERATED_THEME")
  if [[ $theme_type == "light" ]]; then
    ui_theme="vs"
  else
    ui_theme="vs-dark"
  fi

  mkdir -p "$ext_dir/themes"
  ln -sfn "$GENERATED_THEME" "$ext_dir/themes/oah-color-theme.json"

  cat > "$ext_dir/package.json" <<PKG
{
    "name": "$GENERATED_EXTENSION_NAME",
    "displayName": "OAH Theme",
    "description": "OAH color theme",
    "publisher": "local",
    "version": "$GENERATED_EXTENSION_VERSION",
    "engines": { "vscode": "^1.70.0" },
    "categories": ["Themes"],
    "contributes": {
        "themes": [{
            "label": "OAH Theme",
            "uiTheme": "$ui_theme",
            "path": "./themes/oah-color-theme.json"
        }]
    }
}
PKG

  register_generated_extension "$ext_dir"
}

set_theme() {
  local editor_cmd="$1"
  local settings_path="$2"
  local ext_base="$3"

  command -v "$editor_cmd" >/dev/null 2>&1 || return 0

  local theme_name=""

  if [[ -f "$VS_CODE_THEME_DESCRIPTOR" ]]; then
    local extension
    theme_name=$(jq -r '.name // empty' "$VS_CODE_THEME_DESCRIPTOR")
    extension=$(jq -r '.extension // empty' "$VS_CODE_THEME_DESCRIPTOR")

    [[ $theme_name =~ ^[^[:cntrl:]\"\\]+$ ]] || theme_name=""

    if [[ $extension =~ ^[a-zA-Z0-9._-]+$ ]] &&
      ! "$editor_cmd" --list-extensions 2>/dev/null | grep -Fxq "$extension"; then
      "$editor_cmd" --install-extension "$extension" >/dev/null 2>&1
    fi
  elif [[ -f "$GENERATED_THEME" ]]; then
    install_generated_extension "$ext_base/$GENERATED_EXTENSION_NAME"
    theme_name="OAH Theme"
  fi

  if [[ -n "$theme_name" ]]; then
    mkdir -p "$(dirname "$settings_path")"
    [[ -f $settings_path ]] || printf '{\n}\n' >"$settings_path"

    local escaped=${theme_name//&/\\&}
    escaped=${escaped//|/\\|}

    if ! grep -q '"workbench.colorTheme"' "$settings_path"; then
      sed -i --follow-symlinks -E '0,/\{/{s/\{/{\ "workbench.colorTheme": "",/}' "$settings_path"
    fi

    sed -i --follow-symlinks -E \
      "s|(\"workbench.colorTheme\"[[:space:]]*:[[:space:]]*\")[^\"]*(\")|\1$escaped\2|" \
      "$settings_path"
  elif [[ -f $settings_path ]]; then
    sed -i --follow-symlinks -E 's/\"workbench\.colorTheme\"[[:space:]]*:[^,}]*,?//' "$settings_path"
  fi
}

set_theme "code" "$HOME/.config/Code/User/settings.json" "$HOME/.vscode/extensions"
set_theme "codium" "$HOME/.config/VSCodium/User/settings.json" "$HOME/.vscode-oss/extensions"
set_theme "cursor" "$HOME/.config/Cursor/User/settings.json" "$HOME/.cursor/extensions"

