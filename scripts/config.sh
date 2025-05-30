#!/bin/bash

red="\033[31m"
green="\033[32m"
yellow="\033[33m"
reset_fg="\033[0m"

header_0="$red⦿  $green⦿  $yellow⦿ $reset_fg"

echo -e "$header_0 Are you sure? $red THIS WILL OVERWRITE YOUR PREVIOUS GSETTINGS CONFIGURATIONS.$reset_fg"
read -rp "(y/n)" yn

if [ "$yn" != "y" ]; then
  echo -e "Ok, I won't ruin your configs :)"
  exit
fi

# Interface
gsettings set org.gnome.desktop.interface gtk-theme "'adw-gtk3'"
gsettings set org.gnome.desktop.interface font-name 'Geist 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Monaspace Neon, AzarMehrMonospaced, Symbols Nerd Font 12'
gsettings set org.gnome.desktop.interface document-font-name 'Addington CF, Aria 11'
gsettings set org.gnome.desktop.interface icon-theme 'ColorFlow'

# Keybindings
gsettings set org.gnome.shell.keybindings switch-to-application-1 "@as []"
gsettings set org.gnome.shell.keybindings switch-to-application-2 "@as []"
gsettings set org.gnome.shell.keybindings switch-to-application-3 "@as []"
gsettings set org.gnome.shell.keybindings switch-to-application-4 "@as []"
gsettings set org.gnome.shell.keybindings switch-to-application-5 "@as []"
gsettings set org.gnome.shell.keybindings switch-to-application-6 "@as []"
gsettings set org.gnome.shell.keybindings switch-to-application-7 "@as []"
gsettings set org.gnome.shell.keybindings switch-to-application-8 "@as []"
gsettings set org.gnome.shell.keybindings switch-to-application-9 "@as []"

gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "['<Super>5']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 "['<Super>6']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-7 "['<Super>7']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-8 "['<Super>8']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-9 "['<Super>9']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-10 "['<Super>0']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Shift><Super>1']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Shift><Super>2']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Shift><Super>3']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Shift><Super>4']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-5 "['<Shift><Super>5']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-6 "['<Shift><Super>6']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-7 "['<Shift><Super>7']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-8 "['<Shift><Super>8']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-9 "['<Shift><Super>9']"

gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q']"

gsettings set org.gnome.desktop.wm.keybindings move-to-center "['<Super>c']"
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Super>f']"
gsettings set org.gnome.desktop.wm.preferences resize-with-right-button 'true'
gsettings set org.gnome.shell.app-switcher current-workspace-only 'true'
gsettings set org.gnome.mutter center-new-windows 'true'

# Inputs
gsettings set org.gnome.desktop.peripherals.touchpad accel-profile 'flat'
gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled 'true'
gsettings set org.gnome.desktop.peripherals.touchpad speed '0.4'
gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'flat'
gsettings set org.gnome.desktop.peripherals.mouse speed '0.6'

gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'ir')]"
gsettings set org.gnome.desktop.input-sources xkb-options "['caps:escape']"
gsettings set org.gnome.desktop.input-sources per-window 'true'

# GTK and Apps
gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first 'true'
gsettings set org.gnome.nautilus.preferences show-create-link 'true'
gsettings set org.gnome.nautilus.preferences click-policy 'single'

gsettings set org.gnome.Epiphany restore-session-policy 'crashed'
gsettings set org.gnome.Epiphany search-engine-providers "[{'url': <'https://www.google.com/search?q=%s'>, 'bang': <'\!g'>, 'name': <'Google'>}, {'url': <'https://search.brave.com/search?q=%s&source=web&summary=1'>, 'bang': <'\!b'>, 'name': <'Brave'>}]"
gsettings set org.gnome.Epiphany default-search-engine 'Brave'
