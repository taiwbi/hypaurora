#!/usr/bin/env bash
# Install the CachyOS XFCE desktop and copy its mutable configuration.
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "$script_dir/.." && pwd -P)"
gtk_theme="${XFCE_GTK_THEME:-Skeuos-Blue-Dark}"
wm_theme="${XFCE_WM_THEME:-${gtk_theme}-XFWM}"
icon_theme="${XFCE_ICON_THEME:-Flat-Remix-Blue-Dark}"
skeuos_revision=095e06aa44c637af675850e421057c6f09b9f8d0
flat_remix_revision=e7de6c346da46e008987228f363b0eae6e638637
config_only=0
enable_lightdm=0
dry_run=0
non_interactive=0
work_dir=""

info() { printf '[ hypaurora ] %s\n' "$*"; }
die() { printf '[ error ] %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<'EOF'
Usage: scripts/installation-xfce.sh [OPTIONS]

Run as your normal user, with XFCE logged out (e.g. from Ctrl+Alt+F3).
Existing configurations and replaced themes are backed up first.

  --dry-run       Show the plan without changing files, packages, or services
  --config-only   Copy settings and helpers; assume packages/themes are installed
  --lightdm       Select LightDM for the next boot (does not stop this session)
  --yes           Use non-interactive pacman installation
  -h, --help      Show this help

Theme overrides: XFCE_GTK_THEME, XFCE_WM_THEME, XFCE_ICON_THEME.
Defaults: Skeuos-Blue-Dark, Skeuos-Blue-Dark-XFWM, Flat-Remix-Blue-Dark.
Panel override: XFCE_PANEL_PACKAGE=xfce4-panel-compiz or xfce4-panel.
Keeps an installed panel; on a new machine prefers Compiz if available.
EOF
}

while (( $# )); do
    case "$1" in
        --dry-run) dry_run=1 ;;
        --config-only) config_only=1 ;;
        --lightdm) enable_lightdm=1 ;;
        --yes) non_interactive=1 ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown argument: $1 (see --help)" ;;
    esac
    shift
done

[[ "$EUID" -ne 0 ]] || die "Run as your normal user; the installer uses sudo for system changes."
[[ -r /etc/os-release ]] || die "Cannot identify the operating system."
# shellcheck disable=SC1091
source /etc/os-release
[[ "${ID:-}" == cachyos ]] || die "This installer supports CachyOS only (detected: ${ID:-unknown})."
for theme in "$gtk_theme" "$wm_theme" "$icon_theme"; do
    [[ "$theme" =~ ^[A-Za-z0-9_+.-]+$ && "$theme" != . && "$theme" != .. ]] || die "Invalid theme directory name: $theme"
done
command -v python3 >/dev/null || die "python3 is required (sudo pacman -S python)."
command -v pgrep >/dev/null || die "pgrep from procps-ng is required."
configure=(python3 "$repo_root/xfce/configure.py" --gtk-theme "$gtk_theme" --wm-theme "$wm_theme" --icon-theme "$icon_theme")

packages=(xfce4-goodies lightdm lightdm-gtk-greeter networkmanager
    nm-connection-editor xdotool xorg-xinput xorg-setxkbmap zed elementary-icon-theme python git)
if (( ! config_only )); then
    command -v pacman >/dev/null || die "pacman is required."
    panel_package="${XFCE_PANEL_PACKAGE:-}"
    if [[ -z "$panel_package" ]]; then
        if pacman -Qq xfce4-panel-compiz >/dev/null 2>&1; then
            panel_package=xfce4-panel-compiz
        elif pacman -Qq xfce4-panel >/dev/null 2>&1; then
            panel_package=xfce4-panel
        elif pacman -Si xfce4-panel-compiz >/dev/null 2>&1; then
            panel_package=xfce4-panel-compiz
        else
            panel_package=xfce4-panel
        fi
    fi
    case "$panel_package" in
        xfce4-panel|xfce4-panel-compiz) ;;
        *) die "XFCE_PANEL_PACKAGE must be xfce4-panel or xfce4-panel-compiz." ;;
    esac
    pacman -Si "$panel_package" >/dev/null 2>&1 || die "Package $panel_package is unavailable in enabled repositories. Enable its repository or use --config-only with existing packages."

    # The xfce4 group can contain both mutually exclusive panel packages.
    # Expand it explicitly so pacman never selects the other panel variant.
    group_packages="$(pacman -Sgq xfce4)" || die "Cannot read the xfce4 package group."
    [[ -n "$group_packages" ]] || die "The xfce4 package group is empty."
    while IFS= read -r package; do
        case "$package" in
            xfce4-panel|xfce4-panel-compiz) continue ;;
        esac
        packages+=("$package")
    done < <(printf '%s\n' "$group_packages" | sort -u)
    packages+=("$panel_package")
    info "Selected panel package: $panel_package"
fi
pacman_options=(--needed)
if (( non_interactive )); then
    pacman_options+=(--noconfirm)
fi

if (( dry_run )); then
    if (( ! config_only )); then
        printf 'Would run:'
        printf ' %q' sudo pacman -Syu "${pacman_options[@]}" "${packages[@]}"
        printf '\n'
        info "Would install $gtk_theme and $wm_theme from daniruiz/skeuos-gtk@$skeuos_revision"
        info "Would install $icon_theme from daniruiz/flat-remix@$flat_remix_revision"
        info "Would enable NetworkManager for boot."
    fi
    "${configure[@]}" --dry-run
    if (( enable_lightdm )); then
        info "Would set the GTK greeter and enable LightDM for the next boot, replacing any display-manager selection."
    fi
    info "Existing targets would be backed up under the user's state directory."
    exit 0
fi

# Check before installing packages, and again immediately before copying files.
"${configure[@]}" --check
if (( ! config_only || enable_lightdm )); then
    for executable in sudo pacman systemctl; do
        command -v "$executable" >/dev/null || die "$executable is required."
    done
fi
state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
[[ "$state_home" == /* ]] || die "XDG_STATE_HOME must be absolute."
mkdir -p -- "$state_home/hypaurora/backups"
backup_root="$(mktemp -d "$state_home/hypaurora/backups/xfce-$(date +%Y%m%d-%H%M%S)-XXXXXX")"
info "Backups: $backup_root"

cleanup() {
    if [[ -n "$work_dir" ]]; then
        rm -rf -- "$work_dir"
    fi
}
trap cleanup EXIT
trap 'printf "[ error ] XFCE setup stopped at line %s. Backups: %s\n" "$LINENO" "$backup_root" >&2' ERR

fetch_theme() {
    local project="$1" revision="$2" destination="$3"
    shift 3
    git init --quiet "$destination"
    git -C "$destination" remote add origin "https://github.com/daniruiz/$project.git"
    git -C "$destination" -c protocol.version=2 fetch --depth=1 --filter=blob:none origin "$revision"
    git -C "$destination" sparse-checkout set -- "$@"
    git -C "$destination" checkout --detach FETCH_HEAD
}

install_theme() {
    local source="$1" parent="$2" name
    name="$(basename -- "$source")"
    local target="$parent/$name"
    [[ -d "$source" ]] || die "Upstream does not contain theme: $name"
    sudo mkdir -p -- "$parent"
    if [[ -e "$target" || -L "$target" ]]; then
        mkdir -p -- "$backup_root/themes"
        sudo mv -- "$target" "$backup_root/themes/$name"
    fi
    sudo cp -a --no-preserve=ownership -- "$source" "$target"
}

if (( ! config_only )); then
    info "Updating CachyOS and installing XFCE, its plugins, Zed, and elementary cursors..."
    sudo pacman -Syu "${pacman_options[@]}" "${packages[@]}"
    work_dir="$(mktemp -d -t hypaurora-xfce-XXXXXX)"
    info "Fetching pinned Skeuos and Flat Remix themes..."
    fetch_theme skeuos-gtk "$skeuos_revision" "$work_dir/skeuos" "themes/$gtk_theme" "themes/$wm_theme"
    fetch_theme flat-remix "$flat_remix_revision" "$work_dir/icons" "$icon_theme"
    [[ -f "$work_dir/skeuos/themes/$gtk_theme/gtk-3.0/gtk.css" ]] || die "GTK theme is incomplete: $gtk_theme"
    [[ -f "$work_dir/skeuos/themes/$wm_theme/xfwm4/themerc" ]] || die "XFWM theme is incomplete: $wm_theme"
    [[ -f "$work_dir/icons/$icon_theme/index.theme" ]] || die "Icon theme is incomplete: $icon_theme"
    install_theme "$work_dir/skeuos/themes/$gtk_theme" /usr/share/themes
    install_theme "$work_dir/skeuos/themes/$wm_theme" /usr/share/themes
    install_theme "$work_dir/icons/$icon_theme" /usr/share/icons
    if command -v gtk-update-icon-cache >/dev/null; then
        sudo gtk-update-icon-cache -q -t "/usr/share/icons/$icon_theme" || info "Icon cache could not be generated; icons remain installed."
    fi
    sudo systemctl enable NetworkManager.service
fi

"${configure[@]}" --backup-dir "$backup_root"
xfconf-query -c xfwm4 -p /general/easy_click -s Super

if (( enable_lightdm )); then
    [[ -f /usr/share/xsessions/xfce.desktop ]] || die "The XFCE session is not installed."
    [[ -f /usr/share/xgreeters/lightdm-gtk-greeter.desktop ]] || die "The LightDM GTK greeter is not installed."
    greeter_config=/etc/lightdm/lightdm.conf.d/50-hypaurora.conf
    if [[ -e "$greeter_config" || -L "$greeter_config" ]]; then
        sudo mv -- "$greeter_config" "$backup_root/lightdm.conf"
    fi
    readlink /etc/systemd/system/display-manager.service > "$backup_root/display-manager.txt" || true
    printf '[Seat:*]\ngreeter-session=lightdm-gtk-greeter\nuser-session=xfce\n' > "$backup_root/new-lightdm.conf"
    sudo install -Dm644 "$backup_root/new-lightdm.conf" "$greeter_config"
    sudo systemctl enable --force lightdm.service
fi

info "XFCE setup complete. Log into the XFCE (X11) session to use it."
if (( enable_lightdm )); then
    info "LightDM will be used after reboot."
else
    info "Your display-manager selection is unchanged. Use --lightdm to select LightDM for the next boot."
fi
info "Backups are kept at $backup_root."
