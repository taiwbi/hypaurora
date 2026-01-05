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
gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans, Vazirmatn 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Monaspace Neon Var, Vazir Code Hack 11'
gsettings set org.gnome.desktop.interface document-font-name 'Addington CF, Aria 11'
gsettings set org.gnome.desktop.interface icon-theme 'ColorFlow'
gsettings set org.gnome.desktop.interface cursor-theme "'MacOS-Tahoe-Cursor'"
gsettings set org.gnome.desktop.interface cursor-size 32

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
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 "['<Super>q']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-7 "['<Super>w']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-8 "['<Super>e']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-9 "['<Super>r']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-10 "['<Super>t']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Shift><Super>1']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Shift><Super>2']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Shift><Super>3']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Shift><Super>4']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-5 "['<Shift><Super>5']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-6 "['<Shift><Super>q']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-7 "['<Shift><Super>w']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-8 "['<Shift><Super>e']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-9 "['<Shift><Super>r']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-10 "['<Shift><Super>t']"

gsettings set org.gnome.desktop.wm.keybindings close "['<Super>c']"

gsettings set org.gnome.desktop.wm.keybindings move-to-center "['<Super>y']"
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Super>f']"

gsettings set org.gnome.mutter.wayland.keybindings restore-shortcuts '[]'
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Super>Escape']"

# Custom Keybindings
current=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
  "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/']"

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Ghostty'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'ghostty'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>Return'

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'Neovim'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command '/home/mahdi/Documents/hypaurora/code/nvim.sh'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Super>backslash'

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ name 'Brave'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ command 'flatpak run com.brave.Browser --new-window'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ binding '<Super>b'

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ name 'Reset Background'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ command '/home/mahdi/Documents/hypaurora/code/background.sh --reset'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ binding '<Super>x'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ enable-in-lockscreen true

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/ name 'Restore Background'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/ command '/home/mahdi/Documents/hypaurora/code/background.sh --restore'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/ binding '<Super><Alt>x'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/ enable-in-lockscreen false

# Window Management
gsettings set org.gnome.desktop.wm.preferences resize-with-right-button 'true'
gsettings set org.gnome.shell.app-switcher current-workspace-only 'true'
gsettings set org.gnome.mutter center-new-windows 'true'

# Inputs
gsettings set org.gnome.desktop.peripherals.touchpad accel-profile 'flat'
gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled 'true'
gsettings set org.gnome.desktop.peripherals.touchpad speed '0.4'
gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'flat'
gsettings set org.gnome.desktop.peripherals.mouse speed '1.0'

gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'ir')]"
gsettings set org.gnome.desktop.input-sources xkb-options "['caps:escape']"
gsettings set org.gnome.desktop.input-sources per-window 'true'

# Power options
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 300
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'suspend'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 600

gsettings set org.gnome.desktop.session idle-delay 60

gsettings set org.gnome.settings-daemon.plugins.power idle-dim true
gsettings set org.gnome.settings-daemon.plugins.power power-saver-profile-on-low-battery true

# GTK and Apps
gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first 'true'
gsettings set org.gnome.nautilus.preferences show-create-link 'true'
gsettings set org.gnome.nautilus.preferences click-policy 'single'

gsettings set org.gnome.Epiphany restore-session-policy 'crashed'
gsettings set org.gnome.Epiphany search-engine-providers "[{'url': <'https://www.google.com/search?q=%s'>, 'bang': <'\!g'>, 'name': <'Google'>}, {'url': <'https://search.brave.com/search?q=%s&source=web&summary=1'>, 'bang': <'\!b'>, 'name': <'Brave'>}]"
gsettings set org.gnome.Epiphany default-search-engine 'Brave'
