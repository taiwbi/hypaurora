#!/bin/bash

red="\033[31m"
green="\033[32m"
yellow="\033[33m"
reset_fg="\033[0m"

header_1="\n$red◉ $green◉ $yellow◉$reset_fg"
header_2="\n$red◉ $reset_fg"
header_3="\n$green◉ $reset_fg"

echo "$header_1 Enabling needed repositories"

## RPMFUSION

sleep 5
sudo dnf update -y
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
sudo dnf update @core
sudo dnf update -y

## NVIDIA

sudo dnf update -y # and reboot if you are not on the latest kernel
sudo dnf install akmod-nvidia -y
sudo dnf install xorg-x11-drv-nvidia-cuda -y #optional for cuda/nvdec/nvenc support
echo "$header_2 Waiting 5 minutes for NVIDIA to be build"
sleep 300 # Wait 5 minutes for kmod get build
nvidia_version=$(modinfo -F version nvidia 2>/dev/null)
if [[ $nvidia_version =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
    echo "$header_3 Valid NVIDIA driver version: $nvidia_version"
else
    echo "$header_2 Couldn't detect NVIDIA driver. Waiting another 5 minutes"
    sleep 300
fi
sudo dnf mark user akmod-nvidia # To prevent autoremove to consider akmod-nvidia as unneeded
sudo dnf install xorg-x11-drv-nvidia-power -y
sudo systemctl enable nvidia-{suspend,resume,hibernate}
sudo dnf install vulkan -y
sudo dnf install xorg-x11-drv-nvidia-cuda-libs -y
sudo dnf install nvidia-vaapi-driver libva-utils vdpauinfo -y

# TODO: xorg-x11-drv-nvidia-libs.i686
# check vdpauinfo output and vainfo https://rpmfusion.org/Howto/NVIDIA?highlight=%28%5CbCategoryHowto%5Cb%29
# lsmod |grep nouveau
# INSTALL CUDA

echo -e "$header_2 This script does not install CUDA driver and does not enable Secure Boot. If you need it checkout https://rpmfusion.org/Howto/"

## Multimedia

sudo dnf swap ffmpeg-free ffmpeg --allowerasing
sudo dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf install @sound-and-video
sudo dnf update @sound-and-video
sudo dnf install intel-media-driver
sudo dnf install libva-nvidia-driver

# Install software

sudo dnf install dnf-plugins-core

sudo dnf install ripgrep nodejs npm wl-clipboard socat neovim aria2c python-pip grc lsd fzf papers fish
sudo dnf install adw-gtk3-theme celluloid gnome-tweaks

sudo dnf install php php-pecl-xdebug3 composer
sudo dnf -y install dnf-plugins-core
sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo dnf copr enable atim/starship
sudo dnf install starship

sudo dnf copr enable trixieua/morewaita-icon-theme
sudo dnf install morewaita-icon-theme

sudo dnf install nautilus-python

sudo dnf copr enable scottames/ghostty
sudo dnf install xdg-terminal-exec ghostty kitty kitty-kitten


read -p "Do you want to install niri now? (Y/n): " answer
case ${answer:0:1} in
  y|Y )
    sudo dnf install niri xwayland-satellite \ 
      swaybg swayidle swaylock \
      rofi-wayland waybar htop \
      mpd mpc cava
  ;;
  * )
    echo "I won't install hyprland :)"
  ;;
esac
# TODO: Install lazygit

flatpak install flathub com.github.tchx84.Flatseal com.mattjakeman.ExtensionManager org.telegram.desktop \
  com.github.finefindus.eyedropper io.bassi.Amberol com.brave.Browser

# Install Rust
sudo dnf install cargo rust rust-src rustfmt

read -p "Do you want to install hyprland now? (Y/n): " answer
case ${answer:0:1} in
  y|Y )
    sudo dnf copr enable solopasha/hyprland
    sudo dnf install hyprland hyprlock hypridle hyprpaper hyprsunset hyprland-plugins hyprland-qtutils \
    eww-git pyprland qgnomeplatform-qt5 qgnomeplatform-qt6 qt5-qtwayland qt6-qtwayland
    cargo install hyprland-per-window-layout
  ;;
  * )
    echo "I won't install Hyprland :)"
  ;;
esac


sudo dnf mark user totem-video-thumbnailer evince-previewer
sudo dnf remove rhythmbox totem evinc gnome-shell-extension-* firefox firefox-* mediawriter yelp

rm -rf ~/.mozilla/
