#!/bin/bash

hyprctl hyprpaper wallpaper "eDP-1,~/.config/lockscreen"
hyprctl hyprpaper wallpaper "HDMI-A-1,~/.config/lockscreen"
hyprctl dispatch workspace 12
pactl set-sink-mute @DEFAULT_SINK@ true
