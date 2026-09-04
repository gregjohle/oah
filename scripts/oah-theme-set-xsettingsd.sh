#!/bin/bash
BASE_DIR="$(dirname "$0")/.."
XSETTINGS_CONF="$BASE_DIR/configs/xsettingsd/xsettingsd.conf"

if [[ -f $XSETTINGS_CONF ]]; then
    mkdir -p ~/.config/xsettingsd
    cp "$XSETTINGS_CONF" ~/.config/xsettingsd/xsettingsd.conf
    if pgrep -x xsettingsd >/dev/null; then
        killall -HUP xsettingsd
    fi
fi
