#!/bin/sh
set -eu
renderer=$(command -v swaybg 2>/dev/null || true)
if [ -z "$renderer" ] && [ -x "$HOME/.local/bin/swaybg" ]; then
    renderer="$HOME/.local/bin/swaybg"
fi
if [ -z "$renderer" ]; then
    printf 'Install swaybg to display the wallpaper.\n' >&2
    exit 1
fi
exec "$renderer" -i "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/wallpapers/lavender-dunes.png" -m fill
