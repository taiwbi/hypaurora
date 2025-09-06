#!/bin/bash

if pgrep -x swaylock >/dev/null ; then
  echo "swaylock is already running"
  exit 1
fi

swaylock \
  --image ~/.config/lockscreen \
  --scaling fill \
  --indicator-radius 60 \
  --ring-color 2d3748 \
  --inside-color 1a202c \
  --text-color e2e8f0 \
  --ring-ver-color 4299e1 \
  --inside-ver-color 2b6cb0 \
  --font "DM Mono" &
