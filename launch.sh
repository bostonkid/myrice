#!/usr/bin/env bash
# ~/.config/polybar/launch.sh
# Starts one bar per connected monitor. The tray goes on the primary monitor.
# Detects the sensors, battery, backlight and network interfaces present,
# so the same config works on a desktop and a laptop.
# Logs: $XDG_RUNTIME_DIR/polybar/<monitor>.log

set -u

CONFIG="$HOME/.config/polybar/config.ini"
BAR="main"
RUN_DIR="${XDG_RUNTIME_DIR:-/tmp}/polybar"
mkdir -p "$RUN_DIR"

# Only one launch at a time (i3 restart + wal reload can fire together).
exec 9>"$RUN_DIR/launch.lock"
flock -w 10 9 || exit 1

# ---- stop running bars -------------------------------------------------
polybar-msg cmd quit >/dev/null 2>&1 || true
for _ in $(seq 1 25); do
    pgrep -u "$UID" -x polybar >/dev/null || break
    sleep 0.2
done
pkill -u "$UID" -x polybar 2>/dev/null || true

# ---- detect hardware ---------------------------------------------------
# CPU temperature sensor
unset POLYBAR_HWMON
for d in /sys/class/hwmon/hwmon*; do
    case "$(cat "$d/name" 2>/dev/null)" in
        coretemp|k10temp|zenpower)
            [ -r "$d/temp1_input" ] && export POLYBAR_HWMON="$d/temp1_input" && break ;;
    esac
done

# Battery + AC adapter (skip peripheral batteries like mice: scope=Device)
battery="" adapter=""
for p in /sys/class/power_supply/*; do
    [ -e "$p/type" ] || continue
    case "$(cat "$p/type")" in
        Battery)
            [ "$(cat "$p/scope" 2>/dev/null)" = "Device" ] && continue
            [ -z "$battery" ] && battery=$(basename "$p") ;;
        Mains)
            [ -z "$adapter" ] && adapter=$(basename "$p") ;;
    esac
done
[ -n "$battery" ] && export POLYBAR_BATTERY="$battery"
[ -n "$adapter" ] && export POLYBAR_ADAPTER="$adapter"

# Backlight
backlight=""
for b in /sys/class/backlight/*; do
    [ -e "$b" ] && backlight=$(basename "$b") && break
done
[ -n "$backlight" ] && export POLYBAR_BACKLIGHT="$backlight"

# Physical network interfaces
has_wifi=0 has_eth=0
for n in /sys/class/net/*; do
    [ -e "$n/device" ] || continue          # skip lo, docker, veth, tun...
    if [ -d "$n/wireless" ] || [ -e "$n/phy80211" ]; then
        has_wifi=1
    else
        has_eth=1
    fi
done

# ---- build module list -------------------------------------------------
right="filesystem pulseaudio memory cpu"
if [ -n "${POLYBAR_HWMON:-}" ] || [ -e /sys/class/thermal/thermal_zone0/temp ]; then
    right+=" temperature"
fi
[ "$has_wifi" = 1 ] && right+=" wlan"
[ "$has_eth" = 1 ]  && right+=" eth"
[ -n "$backlight" ] && right+=" backlight"
[ -n "$battery" ]   && right+=" battery"

# ---- launch per monitor ------------------------------------------------
mapfile -t monitors < <(polybar --list-monitors 2>/dev/null | cut -d: -f1)
primary=$(polybar --list-monitors 2>/dev/null | awk -F: '/\(primary\)/{print $1; exit}')
[ ${#monitors[@]} -eq 0 ] && monitors=("")
[ -z "$primary" ] && primary="${monitors[0]}"

for m in "${monitors[@]}"; do
    mods="$right"
    [ "$m" = "$primary" ] && mods+=" tray"
    mods+=" powermenu"
    MONITOR="$m" POLYBAR_MODULES_RIGHT="$mods" \
        setsid -f polybar --reload "$BAR" -c "$CONFIG" \
        >"$RUN_DIR/${m:-default}.log" 2>&1
done
