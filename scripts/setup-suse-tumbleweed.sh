#!/bin/bash

red="\033[31m"
green="\033[32m"
yellow="\033[33m"
cyan="\033[36m"
reset_fg="\033[0m"

header_0="$red⦿  $green⦿  $yellow⦿ $reset_fg"
header_1="\n$red◉ $green◉ $yellow◉$reset_fg"
header_2="\n$red◉$reset_fg"

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
echo "                                                     "
echo "                                                     "
echo "Hyprland Installation for OpenSUSE"
echo -e "$reset_fg\n"

read -rp "This script is still under development and not tested. Are you sure you want to continue? (y/n)" yn

if [ "$yn" = "y" ]; then
  echo "Hope you know what you're doing..."
elif [ "$yn" = "n" ]; then
  echo "Right Choice."
  exit
fi

echo -e "$header_1 Adding necessary repositories"
sudo zypper addrepo -cfp 90 'https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/' packman
sudo zypper addrepo https://download.opensuse.org/repositories/X11:Wayland/openSUSE_Tumbleweed/X11:Wayland.repo
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
sudo zypper addrepo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo

echo -e "$header_2 Refreshing zypper database"
sudo zypper refresh
sudo zypper dist-upgrade --from packman --allow-vendor-change
sudo zypper update

echo -e "$header_1 Installing basic packages"
sudo zypper install gnome-keyring polkit-gnome git bc jq socat libnotify-tools inotify-tools starship libgthread-2_0-0 # absolute basic
sudo zypper install sddm libQt6QuickControls2-6 libQt6Svg6 sddm-greeter-qt6 xorg-x11-server hyprland xdg-desktop-portal-hyprland hyprpaper hypridle hyprlock kitty wofi waybar brightnessctl ImageMagick grim slurp wl-clipboard dunst fswebcam alsa-utils # Hyprland
read -rp "OpenSUSE for some unknown reason installs sway and its related packages whith hyprland. Do you want to remove them?? (y/n) " yn
if [ "$yn" = "y" ]; then
  sudo zypper remove sway swaybar swaybg sway-branding-openSUSE swayidle swaylock swaynag swaync
fi

read -rp "Do you want per window keyboard layout on Hyprland?? (y/n) " yn

if [ "$yn" = "y" ]; then
  sudo dnf install cargo
  cargo install hyprland-per-window-layout
fi

read -rp "Do you want to intel hardware acceleration?? (y/n) " yn
if [ "$yn" = "y" ]; then
  echo -e "$header_1 Installing multimedia packages"
  echo -e "$header_1 Installing intel hardware acceleration"
  sudo zypper install intel-media-driver intel-vaapi-driver
fi

echo "$header_1 Installing some utilities "
sudo zypper install gnome-calculator gnome-characters baobab gnome-disk-utility evince gnome-font-viewer nautilus totem-video-thumbnailer\
  celluloid lollypop loupe telegram-desktop brave-browser proxychains-ng aria2 glow fastfetch # Utilites
read -rp "OpenSUSE for some unknown reason installs some additional packages like alacritty and konsole with installed utilities. Do you want to remove them?? (y/n) " yn
if [ "$yn" = "y" ]; then
  sudo zypper remove konsole alacritty alacritty-bash-completion
fi

sudo zypper install --from packman ffmpeg libavcodec # Multimedia
read -rp "Do you want to install gstreamer plugins (for generating thumbnails in Files)?? (y/n) " yn
if [ "$yn" = "y" ]; then
  sudo zypper install --from packman gstreamer-plugins-{good,bad,ugly,libav} gstreamer-plugins-good-extra gstreamer-plugins-bad-orig-addon gstreamer-plugins-ugly-orig-addon # GStreamer plugins
fi

read -rp "$header_1 Do you want to install NVIDIA GPU driver?" yn
if [ "$yn" = "y" ]; then
  sudo zypper addrepo --refresh https://download.nvidia.com/opensuse/tumbleweed NVIDIA
  sudo zypper install-new-recommends --repo NVIDIA
  echo "If automatic command don't install drivers, you can use 'sudo zypper install x11-video-nvidiaG06 nvidia-gl-G06 nvidia-compute-utils-G06' to install them"
  echo "Replace G06 with the driver compatible with your video card"
  echo -e "Use these env variables to run a program using NVIDIA: __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only"
fi

echo -e "$header_1 Linking configurations to your home folder."

/bin/bash -c "$(PWD)/scripts/link.sh"

echo "$header_1 Installing development tools"
sudo zypper install lua-language-server npm lazygit selene
read -rp "$header_1 Do you want to install PHP development packages?? (y/n) " yn
if [ "$yn" = "y" ]; then
  sudo zypper install --from php php-ctype php-dom php-iconv php-openssl php-sqlite php-tokenizer php-xmlreader php-xmlwriter php-gettext php-mbstring php-mysql # PHP development
fi

sudo systemctl set-default graphical.target

echo -e "$header_0"
echo -e "$header_0"
echo -e "$header_0 Installation of Hyprland environemnt was finished. Now you can restart and enjoy your new workflow or install BSPWM as X11 session."

read -rp "$header_1 Would you want to install BSPWM as X11 session?"
if [ "$yn" = "y" ]; then
  sudo zypper install xsetroot xsettingsd xev scrot sxhkd bspwm feh polybar rofi dejavu-sans-fonts xinput picom
fi
