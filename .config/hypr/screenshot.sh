#!/bin/sh
set -eu

if ! command -v grim >/dev/null 2>&1 || ! command -v slurp >/dev/null 2>&1; then
    notify-send "Screenshot tools missing" "Install them: sudo dnf install grim slurp"
    exit 1
fi

pictures="$(xdg-user-dir PICTURES 2>/dev/null || printf '%s/Pictures' "$HOME")"
directory="$pictures/Screenshots"
mkdir -p "$directory"
file="$directory/Screenshot-$(date +%Y-%m-%d_%H-%M-%S-%N).png"

case "${1:-region}" in
    region)
        # Escape cancels the selection without saving a screenshot.
        selection="$(slurp)" || exit 0
        if ! grim -g "$selection" "$file"; then
            notify-send "Screenshot failed" "Could not capture the selected area."
            exit 1
        fi
        ;;
    full)
        if ! grim "$file"; then
            notify-send "Screenshot failed" "Could not capture the screens."
            exit 1
        fi
        ;;
    *) exit 2 ;;
esac

if wl-copy --type image/png < "$file"; then
    notify-send "Screenshot saved and copied" "$file"
else
    notify-send "Screenshot saved" "$file (clipboard copy failed)"
fi
