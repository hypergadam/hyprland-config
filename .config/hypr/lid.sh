#!/bin/sh
# Lid open/close handling for the laptop panel.
#
# Only the DOCKED case needs us. Undocked, logind already does the right thing
# (HandleLidSwitch=suspend), and we must not interfere. Docked, logind's
# HandleLidSwitchDocked=ignore leaves eDP-1 powered and composited behind a
# shut lid -- wasted power, and the pointer can wander onto a screen you
# cannot see.
#
# Why the flag file, same reasoning as screen-blank.sh: dpms-on forces a full
# modeset on this amdgpu that takes ~25s to settle and briefly drops outputs
# from `hyprctl monitors`. So "open" is a no-op unless we were the ones who
# turned the panel off.
set -eu

PANEL="eDP-1"
FLAG="${XDG_RUNTIME_DIR:-/tmp}/hypr-lid-panel-off"

dpms() { hyprctl dispatch "hl.dsp.dpms({ action = \"$1\", monitor = \"$PANEL\" })" >/dev/null; }

# Count currently enabled outputs that are not the laptop panel.
external_count() {
    hyprctl monitors -j | python3 -c '
import json, sys
mons = json.load(sys.stdin)
print(sum(1 for m in mons if m.get("name") != "'"$PANEL"'"))'
}

case "${1:-}" in
close)
    # Undocked: do nothing and let logind suspend. Turning the only output off
    # here would just leave a running, invisible session if suspend is masked.
    [ "$(external_count)" -gt 0 ] || exit 0
    : > "$FLAG"
    dpms off
    ;;
open)
    [ -e "$FLAG" ] || exit 0
    rm -f "$FLAG"
    dpms on
    ;;
*)
    echo "usage: ${0##*/} close|open" >&2
    exit 2
    ;;
esac
