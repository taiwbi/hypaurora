#!/bin/bash

while true; do
  current_hour=$(date +%H)
  if [ "$current_hour" -ge 20 ] || [ "$current_hour" -lt 5 ]; then
    if ! pgrep -x "wl-gammarelay-rs" > /dev/null; then
      wl-gammarelay-rs &
      busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Temperature q 2300
    fi
  else
    if pgrep -x "wl-gammarelay-rs" > /dev/null; then
        pkill wl-gammarelay-rs
    fi
  fi
  sleep 180
done
