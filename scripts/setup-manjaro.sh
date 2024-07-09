#!/bin/bash

red="\033[31m"
green="\033[32m"
yellow="\033[33m"
cyan="\033[36m"
reset_fg="\033[0m"

header_0="$red⦿  $green⦿  $yellow⦿ $reset_fg"
header_1="\n$red◉ $green◉ $yellow◉$reset_fg"

echo -e "$header_0 Fedora Fast Hyprland Setup"
echo -e "$cyan"
echo "  _    _                                             "
echo " | |  | |                                            "
echo " | |__| |_   _ _ __   __ _ _   _ _ __ ___  _ __ __ _ "
echo " |  __  | | | | '_ \ / _\` | | | | '__/ _ \| '__/ _\` |"
echo " | |  | | |_| | |_) | (_| | |_| | | | (_) | | | (_| |"
echo " |_|  |_|\__, | .__/ \__,_|\__,_|_|  \___/|_|  \__,_|"
echo "          __/ | |                                    "
echo "         |___/|_|                                    "
echo -e "$reset_fg\n"

sudo pacman-mirrors --geoip
sudo pacman -Syu

sudo pacman -Rns firefox
# Libraries and ...
sudo pacman -S ripgrep lazygit node npm # Development tools
sudo pacman -S touchegg ttf-joypixels
sudo pacman -S wl-clipboard xclip --asdeps mailcap
sudo pacman -S socat
sudo pacman -S --needed totem --asdeps gst-plugins-ugly gst-libav # totem should already be installed
sudo pacman -S gst-plugin-pipewire gst-plugins-good
# Terminal Tools
sudo pacman -S pkgfile fish neovim aria2 starship
sudo pacman -S gcc
# GUI Applications
sudo pacman -S epiphany gnome-console telegram-desktop evince celluloid
# GNOME Extensions
sudo pacman -S gnome-shell-extension-x11gestures gnome-shell-extension-legacy-theme-auto-switcher

# Chaotic AUR Packages
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
echo "[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf

sudo pacman -Syu morewaita gnome-shell-extension-proxy-switcher

sudo systemctl enable --now touchegg.service
systemctl enable --user gnome-keyring-daemon
systemctl enable --user ssh-agent.service
systemctl enable --user gcr-ssh-agent.socket

bash -c "$PWD/scripts/link.sh"

# ==========================================
# Settings
# ==========================================

# Extensions
gsettings set org.gnome.shell enabled-extensions "['legacyschemeautoswitcher@joshimukul29.gmail.com', 'x11gestures@joseexposito.github.io', 'light-style@gnome-shell-extensions.gcampax.github.com']"

# UI
gsettings set org.gnome.desktop.interface font-name 'Cantarell 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Cartograph CF 12'
gsettings set org.gnome.desktop.interface icon-theme 'MoreWaita'

# Window management
gsettings set org.gnome.desktop.wm.keybindings move-to-center "['<Super>C']"
gsettings set org.gnome.shell.app-switcher current-workspace-only 'true'
gsettings set org.gnome.mutter center-new-windows 'true'
gsettings set org.gnome.desktop.wm.preferences resize-with-right-button 'true'
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:close'

# Mouse, Touchpad and keyboard
gsettings set org.gnome.desktop.peripherals.touchpad accel-profile 'flat'
gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled 'true'
gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'flat'
gsettings set org.gnome.desktop.peripherals.mouse speed '0.45'
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'ir')]"
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'ir')]"
gsettings set org.gnome.desktop.input-sources per-window 'true'

gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first 'true'
gsettings set org.gnome.nautilus.preferences show-create-link 'true'
gsettings set org.gnome.nautilus.preferences click-policy 'single'

# Apps
gsettings set org.gnome.Epiphany restore-session-policy 'crashed'
gsettings set org.gnome.Epiphany search-engine-providers "[{'url': <'https://www.bing.com/search?q=%s'>, 'bang': <'\!bi'>, 'name': <'Bing'>}, {'url': <'https://duckduckgo.com/?q=%s&t=epiphany'>, 'bang': <'\!ddg'>, 'name': <'DuckDuckGo'>}, {'url': <'https://www.google.com/search?q=%s'>, 'bang': <'\!g'>, 'name': <'Google'>}, {'url': <'https://search.brave.com/search?q=%s&source=web&summary=1'>, 'bang': <'\!b'>, 'name': <'Brave'>}]"
gsettings set org.gnome.Epiphany default-search-engine 'Brave'

# Keyboard Shortcuts
gsettings set org.gnome.desktop.wm.keybindings maximize "['<Super>Up']"

sudo pacman -Rns gnome-terminal
