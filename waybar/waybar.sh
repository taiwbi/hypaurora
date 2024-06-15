#!/usr/bin/env sh

export LC_ADDRESS='en_US.UTF-8'
export LC_MONETARY='en_US.UTF-8'
export LC_PAPER='en_US.UTF-8'
export LC_TELEPHONE='en_US.UTF-8'
export LC_MEASUREMENT='en_US.UTF-8'
export LC_TIME='en_US.UTF-8'
export LC_NUMERIC='en_US.UTF-8'

# Terminate already running bar instances
killall -q waybar

if [ ! -d /tmp/hypr ]; then
	ln -s "$XDG_RUNTIME_DIR/hypr" /tmp/hypr # Why would waybar look `/tmp/hypr` instead of `$XDG_RUNTIME_DIR/hypr`?!
fi

# Wait until the processes have been shut down
while pgrep -x waybar >/dev/null; do sleep 1; done

# Launch main
waybar
