#!/usr/bin/env bash
# Follow XFCE's screen saver lock state and swap the desktop backdrop.
set -Eeuo pipefail

wallpaper_command="${HOME}/.local/bin/hypaurora-xfce-wallpaper"
command -v dbus-monitor >/dev/null || exit 0
[[ -x "$wallpaper_command" ]] || exit 0
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/hypaurora-xfce-wallpaper-lock-watch.lock"
flock -n 9 || exit 0

if command -v xfce4-screensaver-command >/dev/null; then
    status="$(xfce4-screensaver-command --query 2>/dev/null || true)"
    if [[ "$status" == *"is active"* ]]; then
        "$wallpaper_command" lock || true
    fi
fi

while true; do
    dbus-monitor --session "type='signal',member='ActiveChanged'" 2>/dev/null |
        while IFS= read -r line; do
            if [[ "$line" == *"interface=org.xfce.ScreenSaver"* ||
                  "$line" == *"interface=org.freedesktop.ScreenSaver"* ]]; then
                read -r value_line || break
                case "$value_line" in
                    *"boolean true"*) "$wallpaper_command" lock || true ;;
                    *"boolean false"*) "$wallpaper_command" unlock || true ;;
                esac
            fi
        done
    sleep 1
done
