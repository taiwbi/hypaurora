#!/bin/bash

if pgrep -x hyprlock >/dev/null ; then
  pkill -USR1 hyprlock
fi

while pgrep -x hyprlock >/dev/null; do sleep 0.1; done

hyprctl switchxkblayout at-translated-set-2-keyboard 0
hyprlock
