#!/bin/sh
# Native Wayland keeps Apidog and its GTK file dialogs sharp on mixed-DPI screens.
set -eu
apidog_image="$HOME/.local/bin/Apidog.AppImage"
if [ ! -x "$apidog_image" ]; then
    printf 'Apidog AppImage not found or not executable: %s\n' "$apidog_image" >&2
    exit 1
fi
exec env GDK_BACKEND=wayland "$apidog_image" --ozone-platform=wayland "$@"
