#!/usr/bin/env bash

# Link Hypaurora configuration into the user profile.
# Existing files and directories are moved to a timestamped backup rather
# than deleted. Run with --yes from installation.sh or interactively by hand.

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "$script_dir/.." && pwd -P)"
backup_root="$HOME/.local/state/hypaurora/backups/$(date +%Y%m%d-%H%M%S)"

info() { printf '\033[1;34m[ hypaurora ]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[ warning ]\033[0m %s\n' "$*" >&2; }

confirm=0
if [[ "${1:-}" == "--yes" ]]; then
    confirm=1
fi

if (( ! confirm )); then
    read -r -p "Link Hypaurora configuration? Existing targets will be backed up first [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || { info "Nothing changed."; exit 0; }
fi

safe_backup_name() {
    local target="$1"
    local relative="${target#"$HOME/"}"
    printf '%s' "${relative//\//__}"
}

link_path() {
    local source="$1"
    local target="$2"
    local resolved

    [[ -e "$source" || -L "$source" ]] || { warn "Skipping missing source: $source"; return 0; }
    source="$(realpath -e -- "$source")"
    mkdir -p -- "$(dirname -- "$target")"

    if [[ -L "$target" ]]; then
        resolved="$(readlink -f -- "$target" || true)"
        if [[ "$resolved" == "$source" ]]; then
            info "Already linked: $target"
            return 0
        fi
        unlink -- "$target"
    elif [[ -e "$target" ]]; then
        mkdir -p -- "$backup_root"
        local backup="$backup_root/$(safe_backup_name "$target")"
        mv -- "$target" "$backup"
        info "Backed up $target to $backup"
    fi

    ln -s -- "$source" "$target"
    info "Linked $target"
}

# Main desktop configuration.
link_path "$repo_root/hypr" "$HOME/.config/hypr"
link_path "$repo_root/waybar" "$HOME/.config/waybar"
link_path "$repo_root/kitty" "$HOME/.config/kitty"
link_path "$repo_root/xdg-desktop-portal/hyprland-portals.conf" "$HOME/.config/xdg-desktop-portal/hyprland-portals.conf"
link_path "$repo_root/xdg-desktop-portal/portals/nautilus.portal" "$HOME/.local/share/xdg-desktop-portal/portals/nautilus.portal"
link_path "$repo_root/hyprpolkitagent/hyprpolkitagent.conf" "$HOME/.config/hyprpolkitagent/hyprpolkitagent.conf"
link_path "$repo_root/uwsm/env-hyprland" "$HOME/.config/uwsm/env-hyprland"
link_path "$repo_root/scripts/nautilus-portal-proxy.py" "$HOME/.local/bin/hypaurora-nautilus-portal"
link_path "$repo_root/scripts/waybar-autohide.sh" "$HOME/.local/bin/hypaurora-waybar-autohide"
link_path "$repo_root/code/power-menu.sh" "$HOME/.local/bin/hypaurora-power-menu"

# Systemd user units are linked individually so unrelated user units survive.
for unit in "$repo_root/systemd/user"/*.service; do
    [[ -e "$unit" ]] || continue
    link_path "$unit" "$HOME/.config/systemd/user/$(basename -- "$unit")"
done

# Systemd drop-ins are linked as directories so packaged units can receive
# session-specific ordering without being replaced wholesale.
for dropin in "$repo_root/systemd/user"/*.service.d; do
    [[ -d "$dropin" ]] || continue
    link_path "$dropin" "$HOME/.config/systemd/user/$(basename -- "$dropin")"
done

# D-Bus activation descriptors are kept in the per-user data directory so the
# Nautilus portal bridge can be activated by xdg-desktop-portal on demand.
for service in "$repo_root/dbus-1/services"/*.service; do
    [[ -e "$service" ]] || continue
    link_path "$service" "$HOME/.local/share/dbus-1/services/$(basename -- "$service")"
done

# Existing repository configuration kept from the GNOME setup.
for directory in \
    bash fish fontconfig ghostty gtk-3.0 gtk-4.0 lazygit mpv qt; do
    if [[ -e "$repo_root/$directory" ]]; then
        link_path "$repo_root/$directory" "$HOME/.config/$directory"
    fi
done

if [[ -e "$repo_root/nautilus/scripts" ]]; then
    link_path "$repo_root/nautilus/scripts" "$HOME/.local/share/nautilus/scripts"
fi

if [[ -e "$repo_root/bash/bashrc" ]]; then
    link_path "$repo_root/bash/bashrc" "$HOME/.bashrc"
fi

if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload || warn "Could not reload the user systemd manager in this session."
fi

info "Configuration links are ready. Backups are kept under $HOME/.local/state/hypaurora/backups."
