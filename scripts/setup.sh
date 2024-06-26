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

sudo zypper update

echo -e "$header_1 Installing basic packages"
sudo zypper install gnome-keyring polkit-gnome git bc jq socat inotify-tools starship # absolute basic
sudo zypper install sddm xorg-x11-server hyprland xdg-desktop-portal-hyprland hyprpaper hypridle kitty wofi waybar brightnessctl grim slurp wl-clipboard dunst fswebcam # Hyprland
# TODO: hyprlock

read -rp "Do you want to per window keyboard layout on Hyprland?? (y/n) " yn

if [ "$yn" = "y" ]; then
  sudo dnf install cargo
  cargo install hyprland-per-window-layout
fi

# TODO: Install Multimedia Packages

read -rp "Do you want to intel hardware acceleration?? (y/n) " yn
echo -e "$header_1 Installing multimedia packages"
if [ "$yn" = "y" ]; then
  echo -e "$header_1 Installing intel hardware acceleration"
  # TODO: Install Intel Hardware Acceleration
fi

echo "$header_1 Installing some utilities "
sudo zypper install gnome-calculator gnome-characters baobab gnome-disk-utility evince gnome-font-viewer nautilus totem-video-thumbnailer\
  celluloid lollypop loupe telegram-desktop firefox lazygit proxychains-ng aria2

read -rp "$header_1 Do you want to install NVIDIA GPU driver?" yn
if [ "$yn" = "y" ]; then
  # TODO: Install NVIDIA Driver
  echo -e "Use these env variables to run a program using NVIDIA: __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only"
fi

echo -e "$header_1 Linking configurations to your home folder."

/bin/bash -c "$(PWD)/scripts/link.sh"
