#!/usr/bin/env bash

# Link repository configuration into the user profile.
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

# Application configuration.
link_path "$repo_root/ghostty" "$HOME/.config/ghostty"

# Existing repository configuration kept from the GNOME setup.
for directory in \
    bash fish fontconfig gtk-3.0 gtk-4.0 lazygit mpv qt; do
    if [[ -e "$repo_root/$directory" ]]; then
        link_path "$repo_root/$directory" "$HOME/.config/$directory"
    fi
done

if [[ -e "$repo_root/bash/bashrc" ]]; then
    link_path "$repo_root/bash/bashrc" "$HOME/.bashrc"
fi

if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload || warn "Could not reload the user systemd manager in this session."
fi

info "Configuration links are ready. Backups are kept under $HOME/.local/state/hypaurora/backups."
