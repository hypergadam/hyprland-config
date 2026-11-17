#!/bin/sh
# Lock the session and blank the displays (Super+L).
#
# Goes through loginctl rather than calling hyprlock directly, so the systemd
# session is marked locked and hypridle runs its lock_cmd. That keeps Super+L,
# lock-before-suspend and any idle timeout on one code path. Falls back to
# hyprlock if hypridle is not running.
#
# Displays come back on any input -- Hyprland re-enables DPMS on activity.
set -eu

if pgrep -x hypridle >/dev/null 2>&1; then
    loginctl lock-session
elif ! pidof hyprlock >/dev/null 2>&1; then
    hyprlock &
fi

# Let hyprlock map its surface before blanking, otherwise the unlock screen
# can flash the desktop for a frame when the displays wake.
sleep 1

# Lua form: this config uses Hyprland's Lua API, where the bare
# `hyprctl dispatch dpms off` syntax is parsed as Lua and errors.
hyprctl dispatch 'hl.dsp.dpms("off")'
