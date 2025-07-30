#!/bin/bash


while true; do
    sleep 1200 # 20 minuets
    brightnessctl -s set 60%-
    sleep 0.5
    brightnessctl -r
    sleep 0.5
    brightnessctl -s set 60%-
    sleep 0.5
    brightnessctl -r
    sleep 0.5
    brightnessctl -s set 60%-
    sleep 0.5
    brightnessctl -r
    sleep 0.5
    brightnessctl -s set 85%-
    sleep 15 # brightnessctl -r
    brightnessctl -r
done
