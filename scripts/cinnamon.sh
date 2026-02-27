#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Fedora GNOME -> Cinnamon (X11) migration script
# - Installs Cinnamon, LightDM+slick-greeter
# - Removes GNOME packages/groups
# - Applies Cinnamon defaults via dconf
# - Installs a one-time per-user first-login setup (gsettings + applet config)
#
# Usage:
#   sudo bash cinnamon.sh
#
# Notes:
# - This will remove GNOME components. Make sure you have a way back in (TTY/SSH).
#
# IMPORTANT: NOT TESTED
###############################################################################

log() { printf "\n[%s] %s\n" "$(date +'%F %T')" "$*"; }

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: Run as root (use sudo)." >&2
    exit 1
  fi
}

detect_target_user() {
  # Prefer the invoking sudo user; else fall back to first non-root user in /home
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    TARGET_USER="${SUDO_USER}"
  else
    TARGET_USER="$(ls -1 /home 2>/dev/null | head -n1 || true)"
  fi

  if [[ -z "${TARGET_USER}" || ! -d "/home/${TARGET_USER}" ]]; then
    echo "ERROR: Could not detect a target user. Run with sudo from your user account." >&2
    exit 1
  fi
  TARGET_HOME="/home/${TARGET_USER}"
}

dnf_yes() {
  # Works with dnf4/dnf5
  dnf -y "$@"
}

safe_remove() {
  # Don't fail if a package isn't installed
  dnf -y remove "$@" --setopt=protected_packages= || true
}

write_file_root() {
  local path="$1"
  shift
  install -D -m 0644 /dev/null "$path"
  cat > "$path" <<'EOF'
'"$*"'
EOF
}

main() {
  require_root
  detect_target_user

  log "Target user: ${TARGET_USER} (${TARGET_HOME})"

  # --- 1) Install Cinnamon + required components
  log "Installing Cinnamon group (excluding firefox, thunderbird)…"
  # Fedora docs: dnf install @cinnamon-desktop
  dnf_yes install @cinnamon-desktop --exclude=firefox,thunderbird

  # --- 2) Switch display manager to LightDM (X11)
  log "Disabling GDM (if present) and enabling LightDM…"
  systemctl disable --now gdm.service 2>/dev/null || true
  systemctl enable --force --now lightdm.service

  # --- 3) Remove GNOME (as requested)
  log "Removing GNOME group and GNOME packages (this is the destructive part)…"
  # Group remove (as you wrote)
  dnf -y group remove gnome-desktop --setopt=protected_packages= || true

  # Explicit removals (as you wrote)
  safe_remove gdm gnome-control-center gnome-session-wayland gnome-shell nautilus xdg-desktop-portal-gnome
  safe_remove ghostty epiphany

  log "Installing Cinnamon integration tools…"
  dnf_yes install \
    touchegg xdotool \
    malcontent \
    dconf dconf-editor \
    python3

  # Values:
  # - Hot corners: org.cinnamon hotcorner-layout strings: functionality:hover-enabled:hover-delay
  #   Order: TL, TR, BL, BR. (TL=scale, TR=expo, others disabled by hover=false)
  # - Screensaver timings: idle-delay in seconds, lock-delay in seconds
  # - Desktop icons: Nemo show-desktop-icons false
  # - Night light schedule: 21 -> 3 (manual schedule)
  # - Keyboard layouts: US + Persian (ir); per-window layout; Win+Space toggle; Caps->Esc (Shift+Caps = CapsLock)
  # - Power: screen off AC 15m (900s), battery 10m (600s); suspend AC 30m (1800s), battery 15m (900s)
  cat > /etc/dconf/db/local.d/00-cinnamon-migration <<'EOF'
[org/cinnamon]
hotcorner-layout=['scale:true:0', 'expo:true:0', 'scale:false:0', 'desktop:false:0']
hotcorner-fullscreen=true

[org/cinnamon/desktop/session]
idle-delay=uint32 600

[org/cinnamon/desktop/screensaver]
lock-enabled=true
lock-delay=uint32 15

[org/nemo/desktop]
show-desktop-icons=false

[org/gnome/settings-daemon/plugins/color]
night-light-enabled=true
night-light-schedule-automatic=false
night-light-schedule-from=21.0
night-light-schedule-to=3.0

[org/gnome/desktop/input-sources]
sources=[('xkb', 'us'), ('xkb', 'ir')]
per-window=true
xkb-options=['grp:win_space_toggle', 'caps:escape_shifted_capslock']

[org/cinnamon/settings-daemon/plugins/power]
sleep-display-ac=900
sleep-display-battery=600
sleep-inactive-ac-timeout=1800
sleep-inactive-ac-type='suspend'
sleep-inactive-battery-timeout=900
sleep-inactive-battery-type='suspend'
EOF

  dconf update

  # --- 5) One-time per-user “first Cinnamon login” setup
  log "Installing one-time per-user Cinnamon first-login setup…"

  install -d -m 0755 "${TARGET_HOME}/.local/bin" "${TARGET_HOME}/.config/autostart"
  cat > "${TARGET_HOME}/.local/bin/cinnamon-first-login-setup.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

MARKER="${HOME}/.cinnamon-first-login-setup.done"
AUTOSTART="${HOME}/.config/autostart/cinnamon-first-login-setup.desktop"

# Run once
if [[ -f "${MARKER}" ]]; then
  exit 0
fi

# Only run in Cinnamon session
if [[ "${XDG_CURRENT_DESKTOP:-}" != *"X-Cinnamon"* && "${XDG_CURRENT_DESKTOP:-}" != *"Cinnamon"* ]]; then
  exit 0
fi

# Small wait so gsettings/dconf services are ready
sleep 2

# --- Fonts (best effort):
# "BlinkMacSystemFont Regular" is usually not available on Linux.
# We'll prefer it if installed, else fall back to "Noto Sans".
choose_font() {
  local preferred="$1"
  local fallback="$2"
  if fc-list | grep -qiF "${preferred}"; then
    echo "${preferred}"
  else
    echo "${fallback}"
  fi
}

UI_FONT="$(choose_font "BlinkMacSystemFont" "Noto Sans")"
UI_FONT_SPEC="${UI_FONT} 10"
MONO_FONT_SPEC="Noto Sans Mono 10"
DOC_FONT_SPEC="${UI_FONT} 10"
TITLE_FONT_SPEC="${UI_FONT} Bold 10"

# Apply fonts
gsettings set org.cinnamon.desktop.interface font-name "${UI_FONT_SPEC}" || true
gsettings set org.cinnamon.desktop.interface document-font-name "${DOC_FONT_SPEC}" || true
gsettings set org.cinnamon.desktop.interface monospace-font-name "${MONO_FONT_SPEC}" || true
gsettings set org.cinnamon.desktop.wm.preferences titlebar-font "${TITLE_FONT_SPEC}" || true

# Mouse accel/speed (GNOME-compatible schemas are often used by Cinnamon too)
gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'flat' || true
gsettings set org.gnome.desktop.peripherals.mouse speed 0.6 || true

# Disable desktop icons (Nemo)
gsettings set org.nemo.desktop show-desktop-icons false || true

# Hot corners (TL=Scale, TR=Expo)
gsettings set org.cinnamon hotcorner-layout "['scale:true:0', 'expo:true:0', 'scale:false:0', 'desktop:false:0']" || true
gsettings set org.cinnamon hotcorner-fullscreen true || true

# Night light 21 -> 3
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true || true
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic false || true
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 21.0 || true
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 3.0 || true

# Screensaver / lock timing
# idle-delay is in seconds; lock-delay is in seconds
gsettings set org.cinnamon.desktop.session idle-delay 600 || true
gsettings set org.cinnamon.desktop.screensaver lock-delay 15 || true
gsettings set org.cinnamon.desktop.screensaver lock-enabled true || true

# Keyboard layouts: US + Persian (ir), per-window layouts, Win+Space switching
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'ir')]" || true
gsettings set org.gnome.desktop.input-sources per-window true || true
gsettings set org.gnome.desktop.input-sources xkb-options "['grp:win_space_toggle', 'caps:escape_shifted_capslock']" || true

# Workspaces: set to 5
gsettings set org.cinnamon.desktop.wm.preferences num-workspaces 5 || true

# Keybinds:
# Super+1..5 -> switch to workspace 1..5
# Super+Shift+1..5 -> move window to workspace 1..5
for i in 1 2 3 4 5; do
  gsettings set org.cinnamon.desktop.keybindings.wm "switch-to-workspace-${i}" "['<Super>${i}']" || true
  gsettings set org.cinnamon.desktop.keybindings.wm "move-to-workspace-${i}" "['<Shift><Super>${i}']" || true
done

# Power:
# Screen off: AC 15m (900s), battery 10m (600s)
# Suspend:    AC 30m (1800s), battery 15m (900s)
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-ac 900 || true
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-battery 600 || true
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-inactive-ac-timeout 1800 || true
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-inactive-ac-type 'suspend' || true
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-inactive-battery-timeout 900 || true
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend' || true

# Enable touchegg (service may be system-level depending on packaging)
if systemctl list-unit-files | grep -q '^touchegg\.service'; then
  sudo systemctl enable --now touchegg.service >/dev/null 2>&1 || true
fi

# --- Fix Grouped Window List stealing Super+1..9:
# Cinnamon applet configs live in ~/.cinnamon/configs/<uuid>/*.json and include a "description" and "value"
# We'll search for any setting whose description mentions Super+<number> shortcut and disable it.
python3 - <<'PY'
import glob, json, os, re

def patch_files(globpat, matcher, new_value):
    for path in glob.glob(os.path.expanduser(globpat)):
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception:
            continue
        changed = False
        for k,v in list(data.items()):
            if isinstance(v, dict):
                desc = str(v.get("description",""))
                if matcher(desc):
                    v["value"] = new_value
                    changed = True
        if changed:
            with open(path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=4)

# Grouped Window List: disable Super+<number> hotkeys
patch_files(
    "~/.cinnamon/configs/grouped-window-list@cinnamon.org/*.json",
    lambda d: ("Super+" in d and "shortcut" in d) or ("Super+<number>" in d),
    False
)

# Keyboard applet: best-effort tweaks (if the options exist in your Cinnamon version)
# - Disable country flag usage, prefer text labels
patch_files(
    "~/.cinnamon/configs/keyboard@cinnamon.org/*.json",
    lambda d: ("flag" in d.lower() and ("country" in d.lower() or "show" in d.lower())),
    False
)
PY

# Mark done, remove autostart, and restart Cinnamon once to apply applet config changes immediately.
touch "${MARKER}"
rm -f "${AUTOSTART}" || true

# Restart Cinnamon shell (fast apply). If this fails, changes still apply next login.
( cinnamon --replace >/dev/null 2>&1 & disown ) || true
EOF

  chmod 0755 "${TARGET_HOME}/.local/bin/cinnamon-first-login-setup.sh"

  cat > "${TARGET_HOME}/.config/autostart/cinnamon-first-login-setup.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Cinnamon First Login Setup
Exec=${TARGET_HOME}/.local/bin/cinnamon-first-login-setup.sh
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Phase=Initialization
NoDisplay=true
EOF

  chown -R "${TARGET_USER}:${TARGET_USER}" \
    "${TARGET_HOME}/.local/bin/cinnamon-first-login-setup.sh" \
    "${TARGET_HOME}/.config/autostart/cinnamon-first-login-setup.desktop"

  log "DONE."
  echo "Next steps:"
  echo "  1) Reboot"
  echo "  2) In LightDM, log into Cinnamon"
  echo "  3) The first-login setup runs once and restarts Cinnamon to apply applet tweaks."

  echo "These steps haven't been done yet."
  echo "  - Settings -> Windows -> Behavior -> Special key to move and resize windows -> <Super>"
  echo "  - gsettings set org.cinnamon.muffin center-new-windows true"
}

main "$@"
