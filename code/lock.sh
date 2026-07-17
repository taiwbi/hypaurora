#!/bin/bash

if pgrep -x hyprlock >/dev/null ; then
  echo "hyprlock is already running"
  exit 1
fi

hyprctl switchxkblayout at-translated-set-2-keyboard 0
hyprlock