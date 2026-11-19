#!/bin/sh
# Brightness for every display Hyprland drives: the internal panel through
# brightnessctl, external monitors that answer DDC/CI through ddcutil.
# Acts on the focused monitor by default, so the keys follow your eyes.
#
#   brightness.sh up|down [step]           adjust the focused monitor (step: 5)
#   brightness.sh set <percent>            set the focused monitor
#   brightness.sh all up|down|set [arg]    same, across every connected display
#   brightness.sh on <connector> up|...    same, against one named output
#   brightness.sh get [connector]          print the percent, for Waybar
#   brightness.sh rescan                   re-probe DDC after plugging a monitor

set -eu

step_default=5
floor=5                 # never let a panel go all the way dark
waybar_signal=9

state="${XDG_RUNTIME_DIR:-/tmp}/hypr-brightness"
ddc_cache="$state/ddc-buses"
mkdir -p "$state"

# Connector -> sysfs backlight device, e.g. "eDP-1 amdgpu_bl1".
panel_devices() {
    for dev in /sys/class/backlight/*; do
        [ -e "$dev" ] || continue
        parent=$(basename "$(dirname "$(readlink -f "$dev")")")
        case $parent in
            card*-*) printf '%s %s\n' "${parent#*-}" "$(basename "$dev")" ;;
        esac
    done
}

# Connector -> I2C bus for each monitor that answers DDC/CI. Blocks headed
# "Invalid display" are the panels ddcutil cannot drive; they are skipped.
probe_ddc() {
    ddcutil detect 2>/dev/null | awk '
        BEGIN { RS = ""; FS = "\n" }
        /^Display [0-9]/ {
            bus = ""; conn = ""
            for (i = 1; i <= NF; i++) {
                if ($i ~ /I2C bus:/) {
                    bus = $i; sub(/.*\/dev\/i2c-/, "", bus); gsub(/[^0-9]/, "", bus)
                }
                if ($i ~ /DRM[ _]connector:/) {
                    conn = $i; sub(/.*DRM[ _]connector:[ 	]*/, "", conn)
                    sub(/^card[0-9]+-/, "", conn); gsub(/[ \t\r]/, "", conn)
                }
            }
            if (bus != "" && conn != "") print conn, bus
        }'
}

# Cache the bus map plus each monitor'\''s max VCP value, so a key press costs
# one ddcutil round trip instead of three.
build_cache() {
    probe_ddc | while read -r conn bus; do
        max=$(ddcutil --bus "$bus" getvcp 10 --brief 2>/dev/null | awk '{ print $5; exit }')
        case ${max:-} in ''|*[!0-9]*) max=100 ;; esac
        printf '%s %s %s\n' "$conn" "$bus" "$max"
    done
}

# Echoes "panel <device>" or "ddc <bus> <max>"; non-zero when neither applies.
backend_for() {
    _conn=$1
    _hit=$(panel_devices | awk -v c="$_conn" '$1 == c { print $2; exit }')
    if [ -n "$_hit" ]; then
        printf 'panel %s\n' "$_hit"
        return 0
    fi
    [ -s "$ddc_cache" ] || build_cache >"$ddc_cache"
    _hit=$(awk -v c="$_conn" '$1 == c { print $2, $3; exit }' "$ddc_cache")
    if [ -z "$_hit" ]; then     # unknown connector: likely hotplugged since the probe
        build_cache >"$ddc_cache"
        _hit=$(awk -v c="$_conn" '$1 == c { print $2, $3; exit }' "$ddc_cache")
    fi
    [ -n "$_hit" ] || return 1
    printf 'ddc %s\n' "$_hit"
}

read_pct() {
    _backend=$(backend_for "$1") || return 1
    set -- $_backend
    case $1 in
        panel) brightnessctl -m -d "$2" | cut -d, -f4 | tr -d '%' ;;
        ddc)   ddcutil --bus "$2" getvcp 10 --brief 2>/dev/null |
                   awk '$5 + 0 > 0 { printf "%d\n", ($4 * 100 + $5 / 2) / $5; exit }' ;;
    esac
}

write_pct() {
    _conn=$1
    _pct=$2
    _backend=$(backend_for "$_conn") || return 1
    set -- $_backend
    case $1 in
        panel) brightnessctl -q -d "$2" set "${_pct}%" ;;
        ddc)   ddcutil --bus "$2" --noverify setvcp 10 "$((_pct * $3 / 100))" >/dev/null 2>&1 ;;
    esac
}

clamp() {
    if   [ "$1" -lt "$floor" ]; then printf '%s\n' "$floor"
    elif [ "$1" -gt 100 ];      then printf '100\n'
    else printf '%s\n' "$1"
    fi
}

focused_monitor() { hyprctl monitors -j | jq -r '[.[] | select(.focused)][0].name // empty'; }
all_monitors()    { hyprctl monitors -j | jq -r '.[].name'; }

announce() {
    notify-send -a brightness -u low -t 1500 \
        -h string:x-canonical-private-synchronous:brightness \
        -h "int:value:$2" -i display-brightness-symbolic \
        "Brightness" "$1 — ${2}%" 2>/dev/null || true
    pkill -RTMIN+"$waybar_signal" waybar 2>/dev/null || true
}

case ${1:-} in
    rescan) build_cache >"$ddc_cache"; cat "$ddc_cache"; exit 0 ;;
    get)    read_pct "${2:-$(focused_monitor)}" 2>/dev/null || true; exit 0 ;;
esac

scope=focused
only=
case ${1:-} in
    all) scope=all; shift ;;
    on)  scope=one; only=${2:?on needs a connector}; shift 2 ;;
esac

action=${1:-}
case $action in
    up|down) arg=${2:-$step_default} ;;
    set)     arg=${2:?set needs a percent} ;;
    *) printf 'usage: %s [all|on <connector>] up|down [step] | set <pct> | get [connector] | rescan\n' "$0" >&2
       exit 2 ;;
esac

# Serialise against key repeat, so queued steps never read a stale value.
exec 9>"$state/lock"
flock -w 2 9 || exit 0

case $scope in
    all) targets=$(all_monitors) ;;
    one) targets=$only ;;
    *)   targets=$(focused_monitor) ;;
esac

last_conn=
last_pct=
for conn in $targets; do
    cur=$(read_pct "$conn" 2>/dev/null) || continue
    [ -n "$cur" ] || continue
    case $action in
        up)   next=$((cur + arg)) ;;
        down) next=$((cur - arg)) ;;
        set)  next=$arg ;;
    esac
    next=$(clamp "$next")
    write_pct "$conn" "$next" 2>/dev/null || continue
    last_conn=$conn
    last_pct=$next
done

if [ -n "$last_conn" ]; then
    if [ "$scope" = all ]; then announce "All displays" "$last_pct"
    else announce "$last_conn" "$last_pct"
    fi
fi
