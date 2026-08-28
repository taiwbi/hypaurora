#!/bin/bash

# Hypaurora installation script — CachyOS (Arch) edition.

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

red="\033[31m"
green="\033[32m"
yellow="\033[33m"
reset_fg="\033[0m"

header_1="\n$red◉ $green◉ $yellow◉$reset_fg"
header_2="\n$red◉ $reset_fg"
header_3="\n$green◉ $reset_fg"

install() {
  sudo pacman -S --needed --noconfirm "$@"
}

echo -e "$header_1 Updating the system"

sudo pacman -Syu --noconfirm

echo -e "$header_1 Checking the NVIDIA driver"

nvidia_branch=$(pacman -Qqs '^nvidia.*-dkms$|^nvidia-open' | head -n1)
nvidia_version=$(modinfo -F version nvidia 2>/dev/null)

if [[ $nvidia_version =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
  echo -e "$header_3 Valid NVIDIA driver version: $nvidia_version (${nvidia_branch:-unknown package})"
else
  echo -e "$header_2 Couldn't detect a loaded NVIDIA driver."
  echo -e "$header_2 Run 'sudo chwd -a' to let CachyOS pick the right driver, then reboot."
fi

# VA-API / VDPAU / Vulkan diagnostics + the Intel side of the hybrid setup.
# libva-nvidia-driver, nvidia-prime and intel-media-driver are part of the
# CachyOS defaults, --needed keeps this a no-op when they already are.
# install libva-utils vdpauinfo vulkan-tools mesa-utils
# install intel-media-driver libva-nvidia-driver nvidia-prime

# echo -e "$header_2 Verify the hybrid setup with: vainfo, vdpauinfo, vulkaninfo --summary,"
# echo -e "  prime-run glxinfo | grep 'OpenGL renderer' and lsmod | grep nouveau"
# echo -e "$header_2 This script does not install CUDA and does not enable Secure Boot."
# echo -e "  For CUDA: sudo pacman -S cuda cuda-tools (matching branch: opencl-nvidia*)"

## Multimedia

# CachyOS already ships ffmpeg, the full GStreamer stack and libdvdcss, so
# there is no ffmpeg-free swap and no RPM Fusion equivalent to deal with.
# echo -e "$header_1 Installing multimedia bits"
#
# install ffmpeg ffmpegthumbnailer libdvdcss
# install gst-libav gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly \
#   gst-plugin-va gst-plugin-gtk4 gst-plugin-pipewire

echo -e "$header_2 Enabling MKV thumbnails in Nautilus"
"$script_dir/thumbnailers.sh"

## Command line tools

echo -e "$header_1 Installing command line tools"

install ripgrep nodejs npm wl-clipboard socat neovim aria2 python-pip fzf \
  fish python-fonttools tmux lazygit jq unzip

## Desktop

echo -e "$header_1 Installing desktop applications and theming"

install adw-gtk-theme nautilus-python gnome-browser-connector
install ghostty
install epiphany zed neovide
install brave-origin-bin

install extension-manager telegram-desktop eyedropper amberol

install ttf-nunito

## Development

echo -e "$header_1 Installing development tools"

# Rust
install rust rust-src rust-analyzer
# PHP
install php composer
mkdir -p ~/.local/npm
npm config set prefix ~/.local/npm
npm install -g devsense-php-ls

sudo mkdir -p /etc/php/conf.d
echo 'extension=iconv' | sudo tee /etc/php/conf.d/iconv.ini

install docker docker-compose docker-buildx
sudo systemctl enable --now docker.socket
sudo usermod -aG docker "$USER"
echo -e "$header_2 Log out and back in for the 'docker' group to take effect."

## Cleanup

echo -e "$header_1 Removing the defaults I don't use"

for pkg in shelly ptyxis alacritty gnome-extension meld vim firefox; do
  pacman -Qq "$pkg" &>/dev/null && sudo pacman -Rns "$pkg"
done

rm -rf .cache/mozilla/ .config/mozilla/

# TODO: Install Chaotic AUR

echo -e "$header_3 Done. Reboot before running config.sh if the driver was reinstalled."
