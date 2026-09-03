#!/usr/bin/env bash

# Hypaurora installer — CachyOS only.
#
# Installs the native Hyprland stack, UWSM, GNOME portal integration, Kitty,
# Waybar, the Rust per-window layout helper, and a converted Bibata Hyprcursor
# theme. Configuration linking is performed at the end with recoverable
# backups; use SKIP_LINK=1 to install packages without linking this repository.

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
backup_root="$HOME/.local/state/hypaurora/backups/$(date +%Y%m%d-%H%M%S)"

info() { printf '\033[1;34m[ hypaurora ]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[ warning ]\033[0m %s\n' "$*" >&2; }
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

enable_user_unit() {
    local unit="$1"
    if systemctl --user enable "$unit" >/dev/null 2>&1; then
        info "Enabled user service: $unit"
    elif systemctl --user add-wants graphical-session.target "$unit" >/dev/null 2>&1; then
        info "Attached user service to graphical-session.target: $unit"
    else
        warn "Could not enable $unit now; run 'systemctl --user enable $unit' after logging into UWSM."
    fi
}

install_bibata_hyprcursor() {
    local xcursor_theme="/usr/share/icons/Bibata-Modern-Classic"
    local cursor_root="$HOME/.local/share/icons"
    local cursor_theme="$cursor_root/Bibata-Modern-Classic"

    [[ -f "$cursor_theme/manifest.hl" ]] && return 0
    [[ -x /usr/bin/hyprcursor-util ]] || { warn "hyprcursor-util is unavailable; skipping Bibata conversion."; return 0; }
    [[ -d "$xcursor_theme" ]] || { warn "Bibata XCursor theme was not found at $xcursor_theme."; return 0; }

    local work_dir extracted created
    work_dir="$(mktemp -d)"
    info "Converting Bibata XCursor theme to native Hyprcursor format..."

    /usr/bin/hyprcursor-util --extract "$xcursor_theme" --output "$work_dir"
    extracted="$(find "$work_dir" -mindepth 1 -maxdepth 1 -type d -print -quit)"
    [[ -n "$extracted" ]] || { rm -rf -- "$work_dir"; warn "Bibata extraction produced no theme directory."; return 0; }

    mkdir -p "$cursor_root"
    if [[ -e "$cursor_theme" || -L "$cursor_theme" ]]; then
        mkdir -p "$backup_root"
        mv -- "$cursor_theme" "$backup_root/Bibata-Modern-Classic"
    fi

    /usr/bin/hyprcursor-util --create "$extracted" --output "$cursor_root"
    created="$(find "$cursor_root" -mindepth 1 -maxdepth 1 -type d -name 'create_*' -print -quit)"
    if [[ -n "$created" && "$created" != "$cursor_theme" ]]; then
        mv -- "$created" "$cursor_theme"
    fi
    rm -rf -- "$work_dir"
}

info "Updating CachyOS packages..."
sudo pacman -Syu --noconfirm

info "Installing the Hyprland and UWSM stack..."
install_repo_packages \
    base-devel git \
    hyprland hyprpaper hyprlock hyprpicker hyprlauncher hypridle hyprcursor \
    hyprshutdown hyprpolkitagent hyprland-qt-support hyprland-guiutils \
    waybar uwsm libnewt \
    xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome \
    xdg-desktop-portal-hyprland

info "Installing Kitty, Nautilus, GNOME integration, and desktop utilities..."
install_repo_packages \
    kitty gnome-control-center nautilus python-gobject gvfs file-roller gnome-keyring gcr-4 polkit \
    adw-gtk-theme adwaita-icon-theme gsettings-desktop-schemas qt6ct kvantum qt6-wayland \
    pipewire pipewire-audio pipewire-pulse wireplumber \
    grim slurp wl-clipboard xcur2png brightnessctl jq libnotify nm-connection-editor \
    networkmanager xdg-utils xdg-user-dirs ttf-jetbrains-mono-nerd

info "Installing the packaged Bibata cursor source..."
install_repo_packages bibata-cursor-theme

info "Installing the Catppuccin GTK theme from the configured Chaotic-AUR repository..."
install_repo_packages colloid-catppuccin-gtk-theme-git

info "Installing Rust and the per-window keyboard layout helper..."
install_repo_packages rust rust-src rust-analyzer
command -v cargo >/dev/null || die "cargo was not provided by the installed rust package."
if [[ ! -x "$HOME/.cargo/bin/hyprland-per-window-layout" ]]; then
    cargo install --locked hyprland-per-window-layout
fi

mkdir -p "$HOME/Pictures/Screenshots" "$HOME/.local/share/icons"
if [[ ! -f "$HOME/.config/background" ]]; then
    warn "No wallpaper found at $HOME/.config/background; add an image there for hyprpaper."
fi
install_bibata_hyprcursor

if [[ "${SKIP_LINK:-0}" != "1" ]]; then
    info "Linking Hypaurora configuration..."
    "$script_dir/link.sh" --yes
fi

systemctl --user daemon-reload || true
enable_user_unit waybar.service
enable_user_unit hyprlauncher.service
enable_user_unit hyprland-per-window-layout.service
enable_user_unit hyprpaper.service
enable_user_unit hypridle.service
enable_user_unit hyprpolkitagent.service
enable_user_unit gnome-keyring-daemon.service
enable_user_unit gcr-ssh-agent.socket

info "Installation complete. Select 'Hyprland (uwsm-managed)' at the login screen."
info "After entering Hyprland, inspect services with: systemctl --user --failed"
