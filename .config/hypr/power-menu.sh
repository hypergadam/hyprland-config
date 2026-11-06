#!/bin/sh

choice=$(printf '%s\n' 'Sleep' 'Restart' 'Shut down' 'Cancel' |
    fuzzel --dmenu --prompt 'Power: ' --lines 4 --width 22) || exit 0

case "$choice" in
    Sleep)
        systemctl suspend
        ;;
    Restart|'Shut down')
        confirm=$(printf '%s\n' 'Cancel' 'Confirm' |
            fuzzel --dmenu --prompt "$choice? " --lines 2 --width 26) || exit 0
        [ "$confirm" = 'Confirm' ] || exit 0
        if [ "$choice" = 'Restart' ]; then
            systemctl reboot
        else
            systemctl poweroff
        fi
        ;;
esac
