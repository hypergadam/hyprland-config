#!/bin/sh
# Safe to run again from a terminal after installing the packages.
panel_state="${XDG_STATE_HOME:-$HOME/.local/state}/hypr-panel"
mkdir -p "$panel_state"

start_panel_app() {
    if ! command -v "$1" >/dev/null 2>&1; then
        printf 'Missing program: %s\n' "$1" >&2
        return
    fi
    if ! pgrep -u "$(id -u)" -x "$1" >/dev/null; then
        "$@" >>"$panel_state/$1.log" 2>&1 &
    fi
}

start_panel_app swaync
python3 "$HOME/.config/waybar/workspace-status.py" --init >>"$panel_state/workspaces.log" 2>&1
python3 "$HOME/.config/waybar/workspace-status.py" >>"$panel_state/workspaces.log" 2>&1 &
start_panel_app waybar
start_panel_app nm-applet --indicator
start_panel_app blueman-applet
