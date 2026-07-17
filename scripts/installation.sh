#!/bin/bash
set -euo pipefail

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

sudo dnf install ripgrep nodejs npm wl-clipboard socat neovim aria2c python-pip grc lsd fzf papers fish python3-fonttools
sudo dnf install adw-gtk3-theme celluloid gnome-tweaks

sudo dnf install php php-pecl-xdebug3 composer
sudo dnf -y install dnf-plugins-core
sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo dnf copr enable trixieua/morewaita-icon-theme
sudo dnf install morewaita-icon-theme

sudo dnf install nautilus-python

sudo dnf copr enable scottames/ghostty
sudo dnf install xdg-terminal-exec ghostty kitty-kitten

# TODO: Install lazygit

flatpak install flathub com.github.tchx84.Flatseal com.mattjakeman.ExtensionManager org.telegram.desktop \
  com.github.finefindus.eyedropper io.bassi.Amberol

# Install Rust
sudo dnf install cargo rust rust-src rustfmt

# Install hypr
sudo dnf copr enable -y lionheartp/Hyprland
sudo dnf install -y hyprland hyprlock hypridle hyprpaper hyprsunset hyprland-plugins hyprland-guiutils
sudo dnf install -y xdg-desktop-portal-gtk

# Install AGS build dependencies
sudo dnf install -y \
  npm meson ninja golang-bin vala valadoc gobject-introspection-devel wayland-protocols-devel \
  gtk3-devel gtk-layer-shell-devel \
  gtk4-devel gtk4-layer-shell-devel

# Build and install astal + ags in an isolated temp directory so the repo
# checkout is not left with build artifacts.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$(mktemp -d -t hypaurora-ags-build.XXXXXX)"
trap 'rm -rf "$BUILD_DIR"' EXIT

echo "Building astal + ags in $BUILD_DIR"

git clone https://github.com/aylur/astal.git "$BUILD_DIR/astal"

pushd "$BUILD_DIR/astal/lib/astal/io" >/dev/null
meson setup build
sudo meson install -C build
popd >/dev/null

pushd "$BUILD_DIR/astal/lib/astal/gtk3" >/dev/null
meson setup build
sudo meson install -C build
popd >/dev/null

pushd "$BUILD_DIR/astal/lib/astal/gtk4" >/dev/null
meson setup build
sudo meson install -C build
popd >/dev/null

git clone https://github.com/aylur/ags.git "$BUILD_DIR/ags"

pushd "$BUILD_DIR/ags" >/dev/null
npm install
meson setup build
sudo meson install -C build
popd >/dev/null

sudo ldconfig

# Finish setting up this repo's AGS config (the actual shell, not the ags
# CLI/framework built above).
pushd "$REPO_DIR/ags" >/dev/null
npm install
glib-compile-schemas schemas/
popd >/dev/null

sudo dnf mark user totem-video-thumbnailer evince-previewer
sudo dnf remove rhythmbox totem evinc gnome-shell-extension-* mediawriter yelp

echo "$header_3 To have GNOME like signle tab experience, in firefox, turn on gnomeTheme.hideSingleTab in about:config"
echo "To hide youtube shorts, add the following to uBlock Origin's custom filters: https://raw.githubusercontent.com/gijsdev/ublock-hide-yt-shorts/master/list.txt"

rm -rf ~/.mozilla/
