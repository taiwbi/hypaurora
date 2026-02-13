#!/usr/bin/env bash
set -euo pipefail

# Cleanup script for Hyprland/Niri/Sway/AGS-related packages & config on Fedora (dnf)
# Usage:
#   bash cleanup-wm.sh --dry-run
#   bash cleanup-wm.sh
#
# Notes:
# - This is conservative by default (no broad wildcards like sway* or hypr*).
# - It only removes packages that are currently installed.
# - It asks before each category.

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

say() { printf "\n\033[1m%s\033[0m\n" "$*"; }
warn() { printf "\n\033[33m%s\033[0m\n" "$*"; }
die() { printf "\n\033[31mERROR:\033[0m %s\n" "$*" >&2; exit 1; }

confirm() {
  local prompt="${1:-Are you sure?}"
  read -r -p "$prompt [y/N] " ans
  [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]]
}

run() {
  if (( DRY_RUN )); then
    echo "DRY-RUN: $*"
  else
    eval "$@"
  fi
}

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"; }

need_cmd dnf
need_cmd rpm

# Deduplicate + keep non-empty
dedupe_words() {
  awk 'NF{for(i=1;i<=NF;i++) print $i}' \
    | awk '!seen[$0]++'
}

# Filter to installed packages only
installed_only() {
  while IFS= read -r pkg; do
    if rpm -q "$pkg" >/dev/null 2>&1; then
      echo "$pkg"
    fi
  done
}

remove_pkgs() {
  local title="$1"; shift
  local pkgs=("$@")

  # Normalize: one-per-line -> dedupe -> installed-only
  mapfile -t pkgs < <(printf "%s\n" "${pkgs[@]}" | dedupe_words | installed_only)

  if ((${#pkgs[@]} == 0)); then
    say "$title: nothing installed to remove."
    return 0
  fi

  say "$title: packages that will be removed (${#pkgs[@]}):"
  printf "  %s\n" "${pkgs[@]}"

  if confirm "Proceed to remove these packages?"; then
    run "sudo dnf remove -y ${pkgs[*]}"
  else
    warn "Skipped $title package removal."
  fi
}

remove_dirs() {
  local title="$1"; shift
  local dirs=("$@")

  # Expand ~ safely
  local expanded=()
  for d in "${dirs[@]}"; do
    expanded+=("${d/#\~/$HOME}")
  done

  # Only keep existing
  local existing=()
  for d in "${expanded[@]}"; do
    [[ -e "$d" ]] && existing+=("$d")
  done

  if ((${#existing[@]} == 0)); then
    say "$title: no config paths found."
    return 0
  fi

  say "$title: paths that will be removed (${#existing[@]}):"
  printf "  %s\n" "${existing[@]}"

  if confirm "Proceed to delete these paths?"; then
    for d in "${existing[@]}"; do
      run "rm -rf -- '$d'"
    done
  else
    warn "Skipped $title config removal."
  fi
}

remove_copr() {
  local title="$1"; shift
  local repos=("$@")

  say "$title: COPR repos to remove:"
  printf "  %s\n" "${repos[@]}"

  if confirm "Proceed to remove these COPR repos?"; then
    for r in "${repos[@]}"; do
      run "sudo dnf -y copr remove '$r' || true"
    done
  else
    warn "Skipped COPR removal."
  fi
}

# ----------------------------
# Package groups (edit freely)
# ----------------------------

HYPR_PKGS=(
  hyprland hyprlock hypridle hyprpaper hyprsunset
  hyprland-plugins hyprland-qtutils hyprland-qt-support
  pyprland hyprpolkitagent hyprshot hyprpanel
  qgnomeplatform-qt5 qgnomeplatform-qt6
  qt5-qtwayland qt6-qtwayland
)

NIRI_SWAY_PKGS=(
  niri xwayland-satellite quickshell
  swayidle swaylock swaybg
  SwayNotificationCenter
)

AGS_ASTAL_PKGS=(
  ags aylur-gtk-shell astal libastal-meta
  typescript pnpm dart-sass python-pywal16
  meson ninja golang
  gobject-introspection-devel gjs-devel astal-gjs-devel
  gtk3-devel gtk4-devel
  gtk-layer-shell-devel gtk4-layer-shell-devel
)

TOOLS_PKGS=(
  rofi rofi-wayland waybar eww-git
  cliphist grim slurp matugen brightnessctl
  kitty alacritty fastfetch htop cava mpd mpc
  openssh-askpass mpv vlc blueman ModemManager
)

# Optional broad wildcard removal (dangerous)
WILDCARDS=( "sway*" "hypr*" )

# ----------------------------
# Config groups
# ----------------------------
HYPR_DIRS=( "~/.config/hypr" "~/.config/hyprpanel" "~/.config/pyprland" )
NIRI_SWAY_DIRS=( "~/.config/niri" "~/.config/illogical-impulse" )
AGS_DIRS=( "~/.config/ags" )
UI_DIRS=( "~/.config/waybar" "~/.config/rofi" "~/.config/eww" )

# ----------------------------
# COPR repos from your script
# ----------------------------
COPR_REPOS=(
  "copr.fedorainfracloud.org/solopasha/hyprland"
  "copr.fedorainfracloud.org/heus-sueh/packages"
  "copr.fedorainfracloud.org/errornointernet/quickshell"
  "copr.fedorainfracloud.org/alternateved/cliphist"
)

say "Fedora WM Cleanup (Hyprland/Niri/Sway/AGS)"
if (( DRY_RUN )); then
  warn "Running in DRY-RUN mode. No changes will be made."
fi

# 1) COPR repos
if confirm "Remove related COPR repos?"; then
  remove_copr "COPR cleanup" "${COPR_REPOS[@]}"
fi

# 2) Package removals by category
remove_pkgs "Hyprland stack" "${HYPR_PKGS[@]}"
remove_pkgs "Niri/Sway stack" "${NIRI_SWAY_PKGS[@]}"
remove_pkgs "AGS / Astal build stack" "${AGS_ASTAL_PKGS[@]}"
remove_pkgs "Tools / launchers / bars / misc" "${TOOLS_PKGS[@]}"

if command -v cargo >/dev/null 2>&1; then
  if cargo install --list | grep -q hyprland-per-window-layout; then
    echo "Found hyprland-per-window-layout (cargo)"
    if confirm "Remove hyprland-per-window-layout (cargo)?"; then
      run "cargo uninstall hyprland-per-window-layout"
    fi
  fi
fi

# 3) Optional wildcards (extra confirmation)
warn "Optional step: remove wildcard package groups (${WILDCARDS[*]})."
warn "This can remove more than you intended (e.g., unrelated sway/hypr-named packages)."
if confirm "Do you want to attempt wildcard removals anyway?"; then
  say "Wildcards selected: ${WILDCARDS[*]}"
  if confirm "LAST CHANCE: proceed with wildcard removal via dnf remove?"; then
    run "sudo dnf remove -y ${WILDCARDS[*]} || true"
  else
    warn "Skipped wildcard removal."
  fi
else
  say "Skipping wildcard removals."
fi

# 4) Config cleanup by category
remove_dirs "Hyprland config" "${HYPR_DIRS[@]}"
remove_dirs "Niri/Sway config" "${NIRI_SWAY_DIRS[@]}"
remove_dirs "AGS/Astal config" "${AGS_DIRS[@]}"
remove_dirs "UI config (waybar/rofi/eww)" "${UI_DIRS[@]}"

say "Done."
warn "Tip: run 'sudo dnf autoremove' afterwards if you want to remove orphaned deps (review carefully)."
