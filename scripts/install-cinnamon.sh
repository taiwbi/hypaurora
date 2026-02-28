#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n[%s] %s\n" "$(date +'%F %T')" "$*"; }

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: Run as root (use sudo)." >&2
    exit 1
  fi
}

dnf_yes() {
  # Works with dnf4/dnf5
  dnf -y "$@"
}

safe_remove() {
  # Don't fail if a package isn't installed
  dnf -y remove "$@" --setopt=protected_packages= || true
}

main() {
  require_root

  log "Installing Cinnamon group (excluding firefox, thunderbird)..."
  dnf_yes install @cinnamon-desktop --exclude=firefox,thunderbird

  log "Disabling GDM (if present) and enabling LightDM..."
  systemctl disable --now gdm.service 2>/dev/null || true
  systemctl enable --force --now lightdm.service

  log "Removing GNOME group and GNOME packages..."
  dnf -y group remove gnome-desktop --setopt=protected_packages= || true
  safe_remove gdm gnome-control-center gnome-session-wayland gnome-shell nautilus xdg-desktop-portal-gnome
  safe_remove ghostty epiphany

  log "Installing Cinnamon integration tools..."
  dnf_yes install \
    touchegg xdotool \
    malcontent \
    dconf dconf-editor \
    python3 \
    kvantum qt5ct

  log "DONE."
  cat <<'EOF'
Next steps:
  1) Reboot
  2) Log into Cinnamon
  3) Run scripts/configure-cinnamon.sh as your user (not root)
  4) Run scripts/link.sh from repository root to link Cinnamon config files
EOF
}

main "$@"
