#!/usr/bin/env bash

# ============================================================================
# OAH Master Session Wrapper
# ============================================================================

# 1. Environment Variables
export XDG_CURRENT_DESKTOP="bspwm"
export XDG_SESSION_DESKTOP="bspwm"
export XDG_SESSION_TYPE="x11"

# 2. X11 Resources (Legacy color injection placeholder)
if [ -f "$HOME/.Xresources" ]; then
    xrdb -merge "$HOME/.Xresources"
fi

# 3. Core Daemons
# Start the compositor for blur and rounded corners
picom --config "$(dirname "$0")/../configs/picom/picom.conf" -b

# Start the polkit authentication agent (Polkit-Gnome)
if [ -x "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1" ]; then
    /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
elif [ -x "/usr/libexec/polkit-gnome-authentication-agent-1" ]; then
    /usr/libexec/polkit-gnome-authentication-agent-1 &
fi

# 4. Background & Theme Daemon (Timewall)
# timewall & # (Placeholder for Phase 4)

# 5. UI Shell (Ewwii)
# ewwii daemon & # (Placeholder for Phase 2)

# 6. Window Manager
# Finally, hand over the session to bspwm
exec bspwm -c "$(dirname "$0")/../configs/bspwm/bspwmrc"
