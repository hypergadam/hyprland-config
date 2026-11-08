#!/bin/sh
# Copy the live desktop configuration into this repository.
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
config_dir=${XDG_CONFIG_HOME:-$HOME/.config}
set -- \
    hypr/hyprland.lua \
    hypr/hyprlock.conf \
    hypr/start-panel.sh \
    hypr/connections.py \
    hypr/launch-apidog.sh \
    hypr/power-menu.sh \
    hypr/screenshot.sh \
    hypr/wallpapers/orbital-ring.png \
    waybar/config.jsonc \
    waybar/style.css \
    waybar/workspace-status.py \
    fuzzel/fuzzel.ini
for relative in "$@"
do
    if [ ! -f "$config_dir/$relative" ]; then
        printf 'Missing configuration: %s\n' "$config_dir/$relative" >&2
        exit 1
    fi
done
apidog_desktop="${XDG_DATA_HOME:-$HOME/.local/share}/applications/apidog.desktop"
if [ ! -f "$apidog_desktop" ]; then
    printf 'Missing application launcher: %s\n' "$apidog_desktop" >&2
    exit 1
fi
for relative in "$@"
do
    mkdir -p "$repo_dir/.config/$(dirname -- "$relative")"
    cp -p -- "$config_dir/$relative" "$repo_dir/.config/$relative"
done
mkdir -p "$repo_dir/.local/share/applications"
cp -p -- "$apidog_desktop" "$repo_dir/.local/share/applications/apidog.desktop"
printf 'Copied %s current configuration files into %s\n' "$#" "$repo_dir"
