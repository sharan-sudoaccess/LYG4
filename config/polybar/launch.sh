#!/usr/bin/env bash
# (Re)start polybar on every connected monitor.
# A lock makes sure two launches at the same time can't fight each other.
exec 9> "${XDG_RUNTIME_DIR:-/tmp}/polybar-launch.$UID.lock"
flock -w 5 9 || exit 1

pkill -u "$UID" -x polybar
for _ in {1..25}; do                       # wait up to 5s for the old bars to exit
    pgrep -u "$UID" -x polybar >/dev/null || break
    sleep 0.2
done
pkill -9 -u "$UID" -x polybar 2>/dev/null

monitors=$(polybar --list-monitors 2>/dev/null | cut -d: -f1)
if [[ -z $monitors ]]; then
    setsid polybar main >/dev/null 2>&1 9>&- &
fi
for m in $monitors; do
    MONITOR=$m setsid polybar main >/dev/null 2>&1 9>&- &
done
