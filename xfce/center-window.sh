#!/usr/bin/env bash
set -Eeuo pipefail

window="$(xdotool getactivewindow)"
geometry="$(xdotool getwindowgeometry --shell "$window")"
width=0
height=0
while IFS='=' read -r key value; do
  case "$key" in
    WIDTH) width="$value" ;;
    HEIGHT) height="$value" ;;
  esac
done <<< "$geometry"
read -r screen_width screen_height < <(xdotool getdisplaygeometry)

[[ "$width" =~ ^[0-9]+$ && "$height" =~ ^[0-9]+$ ]]
[[ "$screen_width" =~ ^[0-9]+$ && "$screen_height" =~ ^[0-9]+$ ]]

xdotool windowmove "$window" \
  "$(( (screen_width - width) / 2 ))" \
  "$(( (screen_height - height) / 2 ))"
