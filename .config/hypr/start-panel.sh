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

start_waybar() (
    # Keep one supervisor per desktop session, including across config reloads.
    flock -n 9 || exit 0
    display_socket="${XDG_RUNTIME_DIR:?}/${WAYLAND_DISPLAY:?}"
    while [ -S "$display_socket" ]; do
        if pgrep -u "$(id -u)" -x waybar >/dev/null; then
            sleep 2
            continue
        fi
        printf '\nStarting Waybar: %s\n' "$(date -Is)"
        waybar
        printf 'Waybar exited with status %s; retrying in 2 seconds\n' "$?"
        sleep 2
    done
) 9>"$panel_state/waybar-supervisor.lock"

start_panel_app swaync
# Prefer a system renderer; a user-local Fedora package also works.
wallpaper_renderer=$(command -v swaybg 2>/dev/null || true)
if [ -z "$wallpaper_renderer" ] && [ -x "$HOME/.local/bin/swaybg" ]; then
    wallpaper_renderer="$HOME/.local/bin/swaybg"
fi
if [ -n "$wallpaper_renderer" ] && ! pgrep -u "$(id -u)" -x swaybg >/dev/null; then
    "$wallpaper_renderer" -i "$HOME/.config/hypr/wallpapers/material-you.jpg" -m fill \
        >>"$panel_state/wallpaper.log" 2>&1 &
fi
python3 "$HOME/.config/waybar/workspace-status.py" --init >>"$panel_state/workspaces.log" 2>&1
python3 "$HOME/.config/waybar/workspace-status.py" >>"$panel_state/workspaces.log" 2>&1 &
start_waybar >>"$panel_state/waybar.log" 2>&1 &
start_panel_app nm-applet --indicator
start_panel_app blueman-applet
