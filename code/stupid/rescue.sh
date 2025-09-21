#!/bin/bash


pkill hyprpaper;
hyprctl dispatch workspace 12
pactl set-sink-mute @DEFAULT_SINK@ true
