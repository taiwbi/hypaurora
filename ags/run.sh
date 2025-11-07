#!/bin/bash

export GI_TYPELIB_PATH="/usr/local/lib64/girepository-1.0"
export LD_LIBRARY_PATH="/usr/local/lib64:$LD_LIBRARY_PATH"

if pgrep -x "ags" > /dev/null
then
    echo "Quitting AGS."
    ags quit
    sleep 0.5
fi

echo "Starting AGS shell."
# nohup ags run ~/.config/ags/app.ts > /dev/null 2>&1 &
nohup ags run ~/.config/ags/app.ts &> ~/ags.log

echo "AGS started."
