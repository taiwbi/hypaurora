#!/bin/bash


pkill hyprpaper;
niri msg action focus-workspace 255 &
pactl set-sink-mute @DEFAULT_SINK@ true &

~/Documents/hypaurora/code/nvim.sh
