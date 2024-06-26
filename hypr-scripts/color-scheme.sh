#!/bin/bash

# Define your themes for light and dark mode
LIGHT_ICON_THEME="Zafiro-Nord-Black"
DARK_ICON_THEME="Zafiro-Nord-Black"

LIGHT_GTK_THEME="adw-gtk3"
DARK_GTK_THEME="adw-gtk3-dark"

LIGHT_CURSOR_THEME="Bibata-Modern-Ice"
DARK_CURSOR_THEME="Bibata-Modern-Ice"

# Function to set themes
set_themes() {
	local mode=$1

	# Set Icon Theme only if they differ
	if [ "$LIGHT_ICON_THEME" != "$DARK_ICON_THEME" ]; then
		if [ "$mode" == "prefer-light" ]; then
			gsettings set org.gnome.desktop.interface icon-theme "$LIGHT_ICON_THEME"
		elif [ "$mode" == "prefer-dark" ]; then
			gsettings set org.gnome.desktop.interface icon-theme "$DARK_ICON_THEME"
		fi
	fi

	# Set GTK Theme
	if [ "$LIGHT_GTK_THEME" != "$DARK_GTK_THEME" ]; then
		if [ "$mode" == "prefer-light" ]; then
			gsettings set org.gnome.desktop.interface gtk-theme "$LIGHT_GTK_THEME"
		elif [ "$mode" == "prefer-dark" ]; then
			gsettings set org.gnome.desktop.interface gtk-theme "$DARK_GTK_THEME"
		fi
	fi

	# Set Cursor Theme only if they differ
	if [ "$LIGHT_CURSOR_THEME" != "$DARK_CURSOR_THEME" ]; then
		if [ "$mode" == "prefer-light" ]; then
			gsettings set org.gnome.desktop.interface cursor-theme "$LIGHT_CURSOR_THEME"
		elif [ "$mode" == "prefer-dark" ]; then
			gsettings set org.gnome.desktop.interface cursor-theme "$DARK_CURSOR_THEME"
		fi
	fi

	## Change Hyprland assets colorscheme
	if [[ "$mode" == "prefer-light" ]]; then
		echo "Light Mode"
		ln -s -f "dunstrc-light" "$HOME/.config/dunst/dunstrc"
		ln -s -f "foot-light.ini" "$HOME/.config/foot/foot.ini"
		ln -s -f "kitty-light.conf" "$HOME/.config/kitty/kitty.conf"
		ln -s -f "gtk-light.css" "$HOME/.config/gtk-3.0/gtk.css"
		ln -s -f "gtk-light.css" "$HOME/.config/gtk-4.0/gtk.css"
		ln -s -f "settings-light.ini" "$HOME/.config/gtk-3.0/settings.ini"
		ln -s -f "settings-dark.ini" "$HOME/.config/gtk-4.0/settings.ini"
		ln -s -f "customChrome-light.css" "$HOME/.mozilla/firefox/Miti/chrome/firefox-gnome-theme/customChrome.css"
		sed -i 's/background-dark.png/background-light.png/g' "$HOME/.config/hypr/hyprpaper.conf"
		sed -i "s/'mocha'/'latte'/g" "$HOME/.config/tmux/tmux.conf"
	elif [[ "$mode" == "prefer-dark" ]]; then
		echo "Dark Mode"
		ln -s -f "dunstrc-dark" "$HOME/.config/dunst/dunstrc"
		ln -s -f "foot-dark.ini" "$HOME/.config/foot/foot.ini"
		ln -s -f "kitty-dark.conf" "$HOME/.config/kitty/kitty.conf"
		ln -s -f "gtk-dark.css" "$HOME/.config/gtk-3.0/gtk.css"
		ln -s -f "gtk-dark.css" "$HOME/.config/gtk-4.0/gtk.css"
		ln -s -f "settings-dark.ini" "$HOME/.config/gtk-3.0/settings.ini"
		ln -s -f "settings-dark.ini" "$HOME/.config/gtk-4.0/settings.ini"
		ln -s -f "customChrome-dark.css" "$HOME/.mozilla/firefox/Miti/chrome/firefox-gnome-theme/customChrome.css"
		sed -i 's/background-light.png/background-dark.png/g' "$HOME/.config/hypr/hyprpaper.conf"
		sed -i "s/'latte'/'mocha'/g" "$HOME/.config/tmux/tmux.conf"
	fi

	systemctl --user restart xdg-desktop-portal-gtk.service
	pkill dunst
	pkill hyprpaper
	sleep 0.2
	hyprpaper &
	dunst &
}

old_scheme=$(gsettings get org.gnome.desktop.interface color-scheme)
scheme=$(echo "$old_scheme" | tr -d "'")
if [[ "$scheme" == "default" ]]; then
	gsettings set org.gnome.desktop.interface color-scheme "prefer-light"
	scheme="prefer-light"
fi
set_themes "$scheme"

# Watch for changes in the color scheme
while read -r; do
	# Initial set up based on current scheme
	echo "Check"
	current_scheme=$(gsettings get org.gnome.desktop.interface color-scheme)
	if [[ "$old_scheme" != "$current_scheme" ]]; then
		scheme=$(echo "$current_scheme" | tr -d "'")
		if [[ "$scheme" == "default" ]]; then
			gsettings set org.gnome.desktop.interface color-scheme "prefer-light"
			scheme="prefer-light"
		fi
		set_themes "$scheme"
		old_scheme=$(gsettings get org.gnome.desktop.interface color-scheme)
		sleep 0.2
	fi
done < <(dconf watch /org/gnome/desktop/interface/color-scheme)
