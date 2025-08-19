#!/bin/bash


pkill swaybg;
niri msg action focus-workspace 255 &
pactl set-sink-mute @DEFAULT_SINK@ true &

swaybg -i ~/.config/fallback --mode fill
~/Documents/hypaurora/code/nvim.sh
