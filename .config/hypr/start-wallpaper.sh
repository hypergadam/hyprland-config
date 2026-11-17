#!/bin/sh
# The wallpaper is part of the theme: palette.toml names it and `theme-apply`
# writes the resolved path to hypr/theme-wallpaper. Falls back to a default if
# the theme declares none.
set -eu

renderer=$(command -v swaybg 2>/dev/null || true)
if [ -z "$renderer" ] && [ -x "$HOME/.local/bin/swaybg" ]; then
    renderer="$HOME/.local/bin/swaybg"
fi
if [ -z "$renderer" ]; then
    printf 'Install swaybg to display the wallpaper.\n' >&2
    exit 1
fi

conf="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/theme-wallpaper"
wallpaper=""
if [ -r "$conf" ]; then
    wallpaper=$(grep -v '^#' "$conf" | grep -v '^[[:space:]]*$' | head -1)
fi
if [ -z "$wallpaper" ] || [ ! -r "$wallpaper" ]; then
    wallpaper="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/wallpapers/lavender-dunes.png"
fi

exec "$renderer" -i "$wallpaper" -m fill
