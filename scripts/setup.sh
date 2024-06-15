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

read -rp "This script is still under development and not tested. Are you sure you want to continue? (y/n)" yn

if [ "$yn" = "y" ]; then
  echo "Hope you know what you're doing..."
elif [ "$yn" = "n" ]; then
  echo "Right Choice (Just for now)."
  exit
fi

echo -e "$header_1 Confuring DNF package manager..."
read -rp "Do you want to use a proxy for DNF? (y/n) " yn

if [ "$yn" = "y" ]; then
  read -rp "Please write the proxy url (http://HOST:PORT or socks5://HOTS:PORT): " dnf_proxy
  if [[ "$dnf_proxy" =~ ^http:\/\/[0-9]*\.[0-9]*\.[0-9]*\.[0-9]:[0-9]* || "$dnf_proxy" =~ ^socks5:\/\/[0-9]*\.[0-9]*\.[0-9]*\.[0-9]:[0-9]* ]]; then
    sudo /bin/bash -c 'echo "proxy=$dnf_proxy" > /etc/dnf/dnf.conf'
  fi
fi
sudo /bin/bash -c 'echo "max_parallel_downloads=8" > /etc/dnf/dnf.conf'

echo -e "$header_1 Adding RPMFusion..."
sudo dnf update -y
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
sudo dnf update -y

echo -e "$header_1 Adding hyprland copr"
sudo dnf copr enable solopasha/hyprland
sudo dnf update -y

echo -e "$header_1 Installing basic packages"
sudo dnf install fish gnome-keyring polkit-gnome git bc jq socat inotify-tools # absolute basic
sudo dnf install kitty icat wofi waybar hyprland xdg-desktop-portal-hyprland hyprpaper hyprlock hypridle brightnessctl grim slurp wl-clipboard dunst fswebcam # Hyprland Specific

read -rp "Do you want to per window keyboard layout on Hyprland?? (y/n) " yn

if [ "$yn" = "y" ]; then
  sudo dnf install cargo
  cargo install hyprland-per-window-layout
fi

sudo usermod --shell=/bin/zsh "$(whoami)"


echo -e "$header_1 Installing multimedia packages"
sudo dnf swap ffmpeg-free ffmpeg --allowerasing -y
sudo dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
sudo dnf update @sound-and-video -y

read -rp "Do you want to intel hardware acceleration?? (y/n) " yn
echo -e "$header_1 Installing multimedia packages"
if [ "$yn" = "y" ]; then
  echo -e "$header_1 Installing intel hardware acceleration"
  sudo dnf install intel-media-driver -y
fi

echo "$header_1 Installing some utilities "
sudo dnf copr enable atim/lazygit -y
sudo dnf install gnome-calculator gnome-characters baobab gnome-disk-utility evince gnome-font-viewer telegram-desktop proxychains-ng aria2 obs-studio nautilus totem-video-thumbnailer celluloid lollypop loupe -y

read -rp "$header_1 Do you want to remove extra packages? (Thunar mousepad network-manager-applet i3 etc.)" yn
if [ "$yn" = "y" ]; then
  sudo dnf remove Thunar mousepad network-manager-applet i3 i3lock i3status i3status-config feh xfce4-terminal xfce-polkit network-manager-applet azote dmenu mousepad thunar -y
fi

read -rp "$header_1 Do you want to install NVIDIA GPU driver?" yn
if [ "$yn" = "y" ]; then
  sudo dnf update -y
  sudo dnf install akmod-nvidia # Reboot if you're not using the latest kernel
  sudo dnf install xorg-x11-drv-nvidia-cuda #optional for cuda/nvdec/nvenc support
  sudo dnf install vulkan # Vulkan
  sudo dnf install nvidia-vaapi-driver libva-utils vdpauinfo libva-nvidia-driver # Hardware Acceleration
  sudo dnf install xorg-x11-drv-nvidia-cuda-libs # NVENC/NVDEC
  sudo cp /usr/share/X11/xorg.conf.d/nvidia.conf /etc/X11/xorg.conf.d/nvidia.conf
  echo -e "Use these env variables to run a program using NVIDIA: __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only"
fi

echo -e "$header_1 Linking configurations to your home folder."

rm -rf "$HOME/.config/dunst" && ln -s "$PWD/dunst" "$HOME/.config/"
rm -rf "$HOME/.config/fastfetch" && ln -s "$PWD/fastfetch" "$HOME/.config/"
rm -rf "$HOME/.config/fontconfig" && ln -s "$PWD/fontconfig" "$HOME/.config/"
rm -rf "$HOME/.config/gtk-3.0" && ln -s "$PWD/gtk-3.0" "$HOME/.config/"
rm -rf "$HOME/.config/gtk-4.0" && ln -s "$PWD/gtk-4.0" "$HOME/.config/"
rm -rf "$HOME/.config/hypr" && ln -s "$PWD/hypr" "$HOME/.config/"
rm -rf "$HOME/.config/kitty" && ln -s "$PWD/kitty" "$HOME/.config/"
rm -rf "$HOME/.config/mpv" && ln -s "$PWD/mpv" "$HOME/.config/"
rm -rf "$HOME/.config/neovide" && ln -s "$PWD/neovide" "$HOME/.config/"
rm -rf "$HOME/.config/tmux" && ln -s "$PWD/tmux" "$HOME/.config/"
rm -rf "$HOME/.config/waybar" && ln -s "$PWD/waybar" "$HOME/.config/"
rm -rf "$HOME/.config/wofi" && ln -s "$PWD/wofi" "$HOME/.config/"
rm -rf "$HOME/.vimrc" && ln -s "$PWD/vimrc" "$HOME/"

rm -rf "$HOME/.local/share/hypr-scripts" && ln -s "$PWD"/hypr-scripts "$HOME/.local/share/"
rm -rf "$HOME/.local/share/nautilus/scripts" && ln -s "$PWD"/nautilus-scripts "$HOME/.local/share/nautilus/scripts"
