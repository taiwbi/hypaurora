#!/bin/bash

niri msg action close-window
niri msg action focus-workspace-previous
pactl set-sink-mute @DEFAULT_SINK@ false
hyprpaper
