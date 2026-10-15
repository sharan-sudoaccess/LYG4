#!/usr/bin/env bash
# (Re)start polybar on every connected monitor.
killall -q polybar
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.2; done

if command -v xrandr >/dev/null; then
    for m in $(polybar --list-monitors | cut -d: -f1); do
        MONITOR=$m polybar --reload main >/dev/null 2>&1 &
    done
else
    polybar --reload main >/dev/null 2>&1 &
fi
