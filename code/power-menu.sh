#!/usr/bin/env bash

# Show a small power menu through the already-installed Hyprlauncher dmenu
# interface. Leaving the selection empty (Escape) simply closes the menu.

set -Eeuo pipefail

lock_before_sleep() {
    hyprctl switchxkblayout current 0

    # Ask logind/hypridle to mark the session locked, then start hyprlock
    # directly as a fallback. The explicit wait avoids suspending during the
    # short window before the lock surface has been created.
    loginctl lock-session || true
    if ! pidof hyprlock >/dev/null; then
        hyprlock >/dev/null 2>&1 &
    fi

    for _ in {1..20}; do
        if pidof hyprlock >/dev/null; then
            sleep 0.5
            return 0
        fi
        sleep 0.05
    done

    printf '%s\n' 'Unable to start hyprlock; refusing to suspend.' >&2
    return 1
}

selected="$(printf '%s\n' \
    'Lock screen' \
    'Suspend' \
    'Hibernate' \
    'Log out' \
    'Reboot' \
    'Shut down' \
    | hyprlauncher --dmenu --quiet)"

case "$selected" in
    'Lock screen')
        hyprctl switchxkblayout current 0
        exec hyprlock
        ;;
    'Suspend')
        lock_before_sleep && systemctl suspend
        ;;
    'Hibernate')
        lock_before_sleep && systemctl hibernate
        ;;
    'Log out')
        exec hyprshutdown
        ;;
    'Reboot')
        systemctl reboot
        ;;
    'Shut down')
        systemctl poweroff
        ;;
esac
