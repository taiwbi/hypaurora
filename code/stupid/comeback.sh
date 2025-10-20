#!/bin/bash

hyprctl dispatch workspace previous
pactl set-sink-mute @DEFAULT_SINK@ false
hyprctl hyprpaper wallpaper "eDP-1,~/.config/background"
hyprctl hyprpaper wallpaper "HDMI-A-1,~/.config/background"
