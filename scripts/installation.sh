#!/bin/bash

red="\033[31m"
green="\033[32m"
yellow="\033[33m"
reset_fg="\033[0m"

header_1="\n$red◉ $green◉ $yellow◉$reset_fg"
header_2="\n$red◉ $reset_fg"
header_3="\n$green◉ $reset_fg"

echo "$header_1 Enabling needed repositories"
sleep 5
sudo dnf update -y
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm -y
sudo dnf config-manager --enable fedora-cisco-openh264 -y
sudo dnf update -y

sudo dnf update -y # and reboot if you are not on the latest kernel
sudo dnf install akmod-nvidia -y # rhel/centos users can use kmod-nvidia instead
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
sudo dnf mark install akmod-nvidia -y # To prevent autoremove to consider akmod-nvidia as uneeded
sudo dnf install xorg-x11-drv-nvidia-power -y
sudo systemctl enable nvidia-{suspend,resume,hibernate}
sudo dnf install vulkan -y
sudo dnf install xorg-x11-drv-nvidia-cuda-libs -y
sudo dnf install nvidia-vaapi-driver libva-utils vdpauinfo -y

read -p "Do you want to role secure boot MOK now? (Y/n): " answer

case ${answer:0:1} in
  y|Y )
    sudo dnf install kmodtool akmods mokutil openssl -y
    sudo kmodgenca -a
    echo "$header_1 IMPORTANT"
    echo "$red Mokutil asks to generate a password to enroll the public key. You will need this after reboot $reset_fg"
    sleep 10
    echo "On the next boot MOK Management is launched and you have to choose 'Enroll MOK'"
    sleeo 5
    echo "Choose 'Continue' to enroll the key or 'View key 0' to show the keys already enrolled"
    sleeo 5
    echo "Confirm enrollment by selecting 'Yes'."
    sleeo 5
    echo "You will be invited to enter the password generated above"
    sleep 20
    sudo mokutil --import /etc/pki/akmods/certs/public_key.der
  ;;
  * )
    echo "Aborting..."
    exit
  ;;
esac

echo -e "$header_2 This script does not install CUDA driver. If you need it checkout https://rpmfusion.org/Howto/CUDA"


sudo dnf swap ffmpeg-free ffmpeg --allowerasing
sudo dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf install @sound-and-video
sudo dnf update @sound-and-video
sudo dnf install intel-media-driver
sudo dnf install libva-nvidia-driver

# Install software

sudo dnf install ripgrep nodejs npm wl-clipboard socat neovim aria2c python-pip unrar grc lsd
sudo dnf install adw-gtk3-theme epiphany chromium gnome-console telegram-desktop celluloid lollypop gnome-tweaks \
  gnome-extensions-app gnome-shell-extension-light-style gnome-shell-extension-screenshot-window-sizer \
  gnome-shell-extension-gsconnect
sudo dnf install php php-pecl-xdebug3 composer

sudo dnf install python-pillow python-watchdog python-numpy python-opencv libnotify

sudo dnf copr enable dusansimic/themes
sudo dnf install morewaita-icon-theme

sudo dnf copr enable atim/lazygit
sudo dnf install lazygit

sudo dnf copr enable pgdev/ghostty
sudo dnf install ghostty

curl -sS https://starship.rs/install.sh | sh

# Install Rust
sudo dnf install rustup
rustup-init

sudo flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
sudo flatpak install flathub-beta app.drey.PaperPlane

sudo dnf remove firefox gnome-terminal rhythmbox
