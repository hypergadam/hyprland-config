#!/bin/sh
# Publish the live compositor environment before starting desktop portals.
set -eu
dbus-update-activation-environment --systemd \
    WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE
systemctl --user start hyprland-session.target
systemctl --user start xdg-desktop-portal.service
