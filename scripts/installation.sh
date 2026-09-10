#!/usr/bin/env bash

# Hypaurora installer.
#
# Installs the GNOME integration, ghostyy, and desktop utilities used by this
# repository. Configuration linking is performed at the end with recoverable
# backups; use SKIP_LINK=1 to install packages without linking this repository.

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

info() { printf '\033[1;34m[ hypaurora ]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[ error ]\033[0m %s\n' "$*" >&2; exit 1; }

[[ -r /etc/os-release ]] || die "Cannot identify the operating system."
# shellcheck disable=SC1091
source /etc/os-release
[[ "${ID:-}" == "cachyos" ]] || die "This installer supports CachyOS only (detected: ${ID:-unknown})."

command -v sudo >/dev/null || die "sudo is required."
command -v pacman >/dev/null || die "pacman is required."
command -v systemctl >/dev/null || die "systemd is required."

install_repo_packages() {
    sudo pacman -S --needed --noconfirm "$@"
}

info "Updating CachyOS packages..."
sudo pacman -Syu --noconfirm

info "Installing ghostty, Nautilus, GNOME integration, and desktop utilities..."
install_repo_packages \
    base-devel git ghostty ghostty-nautilus gnome-control-center nautilus python-gobject gvfs file-roller gnome-keyring gcr-4 polkit \
    adw-gtk-theme adwaita-icon-theme gsettings-desktop-schemas qt6ct kvantum qt6-wayland \
    xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome \
    pipewire pipewire-audio pipewire-pulse wireplumber \
    grim slurp wl-clipboard xcur2png brightnessctl jq socat libnotify nm-connection-editor \
    networkmanager xdg-utils xdg-user-dirs ttf-jetbrains-mono-nerd \
    neovim neovide zed

info "Installing the packaged Bibata cursor source..."
install_repo_packages bibata-cursor-theme

mkdir -p "$HOME/Pictures/Screenshots"

if [[ "${SKIP_LINK:-0}" != "1" ]]; then
    info "Linking Hypaurora configuration..."
    "$script_dir/link.sh" --yes
fi

systemctl --user daemon-reload || true

info "Installation complete. Log into GNOME and inspect services with: systemctl --user --failed"
