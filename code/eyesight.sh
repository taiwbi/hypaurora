#!/usr/bin/env bash
# eyesight-reminder.sh
# Sends a dunst notification; middle-click action "dim" fades screen down,
# waits RESTORE_AFTER seconds, then fades back to the original brightness.

# ---- CONFIG ----
INTERVAL=1200         # seconds between reminders (20 min)
STEPS=25              # number of steps for fade (higher = smoother)
DELAY=0.025           # delay (seconds) between steps
MIN_TARGET=10         # don't go below this percent
MAX_TARGET=15         # don't go above this percent
RESTORE_AFTER=20      # seconds to wait before restoring (20 secs)
# -----------------

# helper: get current brightness as integer percent
get_current_pct() {
    local cur max
    cur=$(brightnessctl get 2>/dev/null) || { echo 0; return; }
    max=$(brightnessctl max 2>/dev/null) || { echo 100; return; }
    printf "%d" $(( cur * 100 / max ))
}

# fade from current to target (absolute percent)
fade_to() {
    local target=$1
    local steps=${2:-$STEPS}
    local delay=${3:-$DELAY}
    local start diff dir absdiff step i new

    start=$(get_current_pct)
    diff=$(( target - start ))
    if [ "$diff" -eq 0 ]; then
        return 0
    fi

    dir=1
    if [ $diff -lt 0 ]; then dir=-1; fi
    absdiff=$(( diff * dir ))
    step=$(( absdiff / steps ))
    if [ $step -eq 0 ]; then step=1; fi

    for ((i=1;i<=steps;i++)); do
        new=$(( start + dir * step * i ))
        # clamp to not overshoot
        if [ $dir -gt 0 ] && [ $new -gt $target ]; then new=$target; fi
        if [ $dir -lt 0 ] && [ $new -lt $target ]; then new=$target; fi

        brightnessctl set "${new}%" >/dev/null 2>&1 || true
        sleep "$delay"

        # stop early if we've hit the target
        if [ "$new" -eq "$target" ]; then break; fi
    done

    # ensure exact final value
    brightnessctl set "${target}%" >/dev/null 2>&1 || true
}

# main loop
while true; do
    sleep "$INTERVAL"

    action=$(notify-send \
               --urgency=normal \
               --action="dim=Dim Screen" \
               --icon="org.gnome.Settings-wellbeing-symbolic" \
               --app-name="Well Being" \
               "Eyesight Reminder" "Rest your eyes!\nMiddle-click to dim the screen gradually." | tail -n 1)

    if [ "$action" = "dim" ]; then
        original=$(get_current_pct)

        # if already at or below MAX_TARGET, skip dimming
        if [ "$original" -le "$MAX_TARGET" ]; then
            echo "Already at or below ${MAX_TARGET}% — skipping dim."
            continue
        fi

        # pick a random reduction between 40% and 75%
        reduction=$(( RANDOM % (75 - 40 + 1) + 40 ))  # 40..75
        tentative=$(( original * (100 - reduction) / 100 ))

        # clamp to MIN_TARGET..MAX_TARGET
        if [ "$tentative" -lt "$MIN_TARGET" ]; then
            target=$MIN_TARGET
        elif [ "$tentative" -gt "$MAX_TARGET" ]; then
            target=$MAX_TARGET
        else
            target=$tentative
        fi

        echo "Dimming to ${target}% (reduction ${reduction}%)."

        fade_to "$target"

        # wait, then fade back
        sleep "$RESTORE_AFTER"

        echo "Restoring brightness to ${original}%."
        fade_to "$original"
    fi
done
