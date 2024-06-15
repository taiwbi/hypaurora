#!/bin/bash

old_scheme=$(gsettings get org.gnome.desktop.interface color-scheme)
scheme=$(echo "$old_scheme" | tr -d "'")
if [[ "$scheme" == "default" ]]; then
	scheme="prefer-light"
fi

echo "$scheme"

if [[ "$scheme" == "prefer-light" ]]; then
	wofi --show drun --conf ~/.config/wofi/config/config --style ~/.config/wofi/src/latte/style.css
elif [[ "$scheme" == "prefer-dark" ]]; then
	wofi --show drun --conf ~/.config/wofi/config/config --style ~/.config/wofi/src/mocha/style.css
fi
