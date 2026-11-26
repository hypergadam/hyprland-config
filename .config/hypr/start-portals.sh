#!/bin/sh
# Publish the live compositor environment before starting desktop portals.
set -eu

# xdg-desktop-portal-kde is D-Bus activated, so it inherits the D-Bus/systemd
# activation environment rather than anything Hyprland's hl.env() sets.
# Theme vars must be exported here or the file dialog renders unstyled.
QT_QPA_PLATFORMTHEME=kde
XCURSOR_THEME=breeze_cursors
XCURSOR_SIZE=24
export QT_QPA_PLATFORMTHEME XCURSOR_THEME XCURSOR_SIZE

dbus-update-activation-environment --systemd \
    WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE \
    QT_QPA_PLATFORMTHEME XCURSOR_THEME XCURSOR_SIZE

systemctl --user start hyprland-session.target
systemctl --user start xdg-desktop-portal.service

# PolicyKit authentication agent. polkitd runs as a system service but it only
# prompts through a session agent, and nothing was starting one -- so every GUI
# privilege request (Dolphin mounting a disk, a firmware or package update)
# had nowhere to ask and just failed or hung.
#
# polkit-kde ships this unit; it is PartOf=graphical-session.target, so it stops
# with the session. Its After=plasma-core.target is inert here -- ordering
# against a target that never activates is simply ignored.
systemctl --user start plasma-polkit-agent.service
