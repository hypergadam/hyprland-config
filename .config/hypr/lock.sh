#!/bin/sh
# Lock the session (Super+L).
#
# Goes through loginctl rather than calling hyprlock directly, so the systemd
# session is marked locked and hypridle runs its lock_cmd. That keeps Super+L,
# lock-before-suspend and any idle timeout on one code path. Falls back to
# hyprlock if hypridle is not running.
#
# This script deliberately does NOT blank the displays any more. It used to,
# and that was the bug: blanking here left the restore unpaired, so nothing
# ever explicitly turned the panels back on and the laptop screen kept getting
# stranded dark while the external monitor came back. Blanking and restoring
# now both live in screen-blank.sh, driven by the hypridle listener, so they
# cannot get out of step. hyprlock covers the screen instantly either way.
set -eu

if pgrep -x hypridle >/dev/null 2>&1; then
    loginctl lock-session
elif ! pidof hyprlock >/dev/null 2>&1; then
    hyprlock &
fi
