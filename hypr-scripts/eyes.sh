#!/bin/bash

while true; do
  notify-send "Eye rest time" "It's time to rest your eyes for 20 seconds, I'll send you another notification when 20s is done."
  sleep 20
  notify-send "Get back to work" "Eye rest time is over, continue your work"
  sleep 1200
done
