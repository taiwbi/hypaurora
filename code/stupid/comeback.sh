#!/bin/bash

hyprctl dispatch workspace previous
pactl set-sink-mute @DEFAULT_SINK@ false
hyprpaper
