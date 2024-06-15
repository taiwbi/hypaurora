#!/bin/bash

# Specify the file to watch
FILE_TO_WATCH=$HOME/Pictures/background/background.png

while true; do
    inotifywait -e modify "$FILE_TO_WATCH"
    if [ $? -eq 0 ]; then
      sleep 1
	    pkill hyprpaper
	    # Wait until the processes have been shut down
	    while pgrep -x hyprpaper >/dev/null; do sleep 1; done
	    hyprpaper & disown
    else
        echo "Error: inotifywait encountered an issue."
        exit 1
    fi
done
