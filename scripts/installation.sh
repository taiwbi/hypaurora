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
sudo dnf mark user akmod-nvidia # To prevent autoremove to consider akmod-nvidia as uneeded
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

sudo dnf install ripgrep nodejs npm wl-clipboard socat neovim aria2c python-pip grc lsd fzf papers
sudo dnf install adw-gtk3-theme telegram-desktop celluloid gnome-tweaks
sudo dnf install php php-pecl-xdebug3 composer

sudo dnf copr enable trixieua/morewaita-icon-theme
sudo dnf install morewaita-icon-theme

sudo dnf install nautilus-python
# TODO: Install lazygit


sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null

sudo dnf config-manager addrepo --overwrite --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
sudo dnf check-update
sudo dnf install brave-browser

## Install Hyprland?

read -p "Do you want to install hyprland now? (Y/n): " answer
case ${answer:0:1} in
  y|Y )
    sudo dnf copr enable solopasha/hyprland
    sudo dnf install hyprland hyprlock hypridle hyprpaper hyprland-plugins hyprland-qtutils kitty rofi-wayland eww-git \
     --exclude=swww-bash-completion,swww-fish-completion
  ;;
  * )
    echo "I won't install hyprland :)"
  ;;
esac

flatpak install flathub com.github.tchx84.Flatseal com.mattjakeman.ExtensionManager re.sonny.Tangram io.github.seadve.Kooha com.github.finefindus.eyedropper io.bassi.Amberol

# Install Rust
sudo dnf install rustup
rustup-init

sudo dnf mark user totem-video-thumbnailer evince-previewer
sudo dnf remove rhythmbox totem evinc installatione gnome-shell-extension-* firefox firefox-*

rm -rf ~/.mozilla/
