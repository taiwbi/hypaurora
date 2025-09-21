#!/bin/bash

hyprctl dispatch killactives
hyprctl dispatch movetoworkspace previous
pactl set-sink-mute @DEFAULT_SINK@ false
hyprpaper