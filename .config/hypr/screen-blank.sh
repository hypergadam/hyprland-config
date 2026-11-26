#!/bin/sh
# Blank / restore the displays for the lock screen.
#
# Called only by hypridle's listener (see hypridle.conf). Splitting this out
# of lock.sh is what makes the wake reliable: blanking and restoring are now
# always paired on the same code path, instead of lock.sh blanking and
# nothing ever explicitly turning the panels back on.
#
# Why the flag file: dpms-on is not free on this machine. It triggers a full
# modeset on amdgpu that takes ~25s to settle and briefly drops outputs from
# `hyprctl monitors` entirely. Running it on every keypress would flicker the
# desktop constantly, so "on" is a no-op unless we were the ones who blanked.
set -eu

FLAG="${XDG_RUNTIME_DIR:-/tmp}/hypr-screens-blanked"

dpms() { hyprctl dispatch "hl.dsp.dpms({ action = \"$1\" })" >/dev/null; }

# Names of outputs currently reporting dpmsStatus: 0.
dark_outputs() {
    hyprctl monitors all | awk '
        /^Monitor /     { name = $2 }
        /dpmsStatus: 0/ { print name }'
}

case "${1:-}" in
off)
    # Blank only while the lock screen is actually up, so an idle but
    # unlocked desktop never goes dark on you mid-read.
    #
    # "off wait" additionally waits a few seconds for hyprlock to appear, for
    # the caller that locks and blanks in one breath (the idle auto-lock
    # listener). `loginctl lock-session` returns before hyprlock has mapped,
    # so an unguarded check there would always lose the race and never blank.
    # The plain "off" path must NOT wait: it runs on every 3s of idle, and
    # lingering there would leave a sleeping process behind constantly.
    if [ "${2:-}" = "wait" ]; then
        i=0
        while [ "$i" -lt 10 ]; do
            pidof hyprlock >/dev/null 2>&1 && break
            sleep 0.5
            i=$((i + 1))
        done
    fi
    pidof hyprlock >/dev/null 2>&1 || exit 0
    : > "$FLAG"
    dpms off
    ;;
on)
    [ -e "$FLAG" ] || exit 0
    rm -f "$FLAG"
    dpms on

    # Retry any output still dark. This is the laptop-panel fix: the external
    # HDMI connector drops and reconnects on this machine, and the monitor
    # reconfigure that the reconnect triggers restores HDMI while leaving
    # eDP-1 stranded at dpmsStatus 0 (hyprland.log: "Connector eDP-1
    # enabledState changed true -> false" with no matching restore).
    i=0
    while [ "$i" -lt 6 ]; do
        sleep 5
        dark=$(dark_outputs)
        [ -z "$dark" ] && exit 0
        for m in $dark; do
            hyprctl dispatch "hl.dsp.dpms({ action = \"on\", monitor = \"$m\" })" >/dev/null
        done
        i=$((i + 1))
    done
    ;;
*)
    echo "usage: ${0##*/} off [wait]|on" >&2
    exit 2
    ;;
esac
