#!/bin/bash

swayidle -w \
  timeout 60 'brightnessctl -s set 0' \
    resume 'brightnessctl -r' \
  timeout 60 'brightnessctl -sd asus::kbd_backlight set 0' \
    resume 'brightnessctl -rd asus::kbd_backlight' \
  timeout 180 '~/Documents/hypaurora/code/lock.sh' \
    resume 'brightnessctl -r' \
  timeout 600 'systemctl suspend' \
    resume 'brightnessctl -r' \
  before-sleep '~/Documents/hypaurora/code/lock.sh'
