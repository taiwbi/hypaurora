#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n[%s] %s\n" "$(date +'%F %T')" "$*"; }

require_user() {
  if [[ "${EUID}" -eq 0 ]]; then
    echo "ERROR: Run as your desktop user, not root." >&2
    exit 1
  fi
}

require_gsettings() {
  if ! command -v gsettings >/dev/null 2>&1; then
    echo "ERROR: gsettings command not found." >&2
    exit 1
  fi
}

choose_font() {
  local preferred="$1"
  local fallback="$2"
  if fc-list | grep -qiF "${preferred}"; then
    echo "${preferred}"
  else
    echo "${fallback}"
  fi
}

gset() {
  local schema="$1"
  local key="$2"
  local value="$3"
  gsettings set "${schema}" "${key}" "${value}" || true
}

main() {
  require_user
  require_gsettings

  if [[ "${XDG_CURRENT_DESKTOP:-}" != *"X-Cinnamon"* && "${XDG_CURRENT_DESKTOP:-}" != *"Cinnamon"* ]]; then
    log "WARNING: XDG_CURRENT_DESKTOP does not look like Cinnamon. Continuing anyway."
  fi

  local ui_font
  local ui_font_spec
  local mono_font_spec
  local doc_font_spec
  local title_font_spec

  ui_font="$(choose_font "BlinkMacSystemFont" "Noto Sans")"
  ui_font_spec="${ui_font} 11"
  mono_font_spec="JetBrains Mono NL 11"
  doc_font_spec="${ui_font} 11"
  title_font_spec="${ui_font} Bold 11"

  # Fonts
  gset org.cinnamon.desktop.interface font-name "${ui_font_spec}"
  gset org.gnome.desktop.interface document-font-name "${doc_font_spec}"
  gset org.gnome.desktop.interface monospace-font-name "${mono_font_spec}"
  gset org.cinnamon.desktop.wm.preferences titlebar-font "${title_font_spec}"

  # Mouse
  gset org.gnome.desktop.peripherals.mouse accel-profile "flat"
  gset org.gnome.desktop.peripherals.mouse speed "0.9"

  # Desktop icons
  gset org.nemo.desktop show-desktop-icons "false"

  # Hot corners
  gset org.cinnamon hotcorner-layout "['scale:true:0', 'expo:true:0', 'scale:false:0', 'desktop:false:0']"

  # Night light (21 -> 3)
  gset org.gnome.settings-daemon.plugins.color night-light-enabled "true"
  gset org.gnome.settings-daemon.plugins.color night-light-schedule-automatic "false"
  gset org.gnome.settings-daemon.plugins.color night-light-schedule-from "21.0"
  gset org.gnome.settings-daemon.plugins.color night-light-schedule-to "3.0"

  # Session + lock
  gset org.cinnamon.desktop.session idle-delay "900"
  gset org.cinnamon.desktop.screensaver lock-delay "15"
  gset org.cinnamon.desktop.screensaver lock-enabled "true"

  # Keyboard layouts
  gset org.gnome.libgnomekbd.keyboard layouts "['us', 'ir']"
  gset org.gnome.desktop.input-sources per-window "true"
  gset org.gnome.libgnomekbd.desktop group-per-window "true"
  gset org.gnome.libgnomekbd.desktop default-group "0"
  gset org.gnome.libgnomekbd.keyboard options "['grp\tgrp:win_space_toggle', 'caps\tcaps:escape_shifted_capslock']"

  # Workspaces + keybindings
  gset org.cinnamon.desktop.wm.preferences num-workspaces "5"
  for i in 1 2 3 4 5; do
    gset org.cinnamon.desktop.keybindings.wm "switch-to-workspace-${i}" "['<Super>${i}']"
    gset org.cinnamon.desktop.keybindings.wm "move-to-workspace-${i}" "['<Shift><Super>${i}']"
  done

  gset org.cinnamon.desktop.keybindings.wm close "['<Alt>F4', '<Super>q']"
  gset org.cinnamon.desktop.keybindings.wm move-to-center "['<Super>c']"
  gset org.cinnamon.desktop.keybindings.wm toggle-maximized "['<Alt>F10', '<Super>v']"
  gset org.cinnamon.desktop.keybindings.wm toggle-fullscreen "['<Super>f']"

  # Window behavior
  gset org.cinnamon.muffin center-new-windows "true"
  gset org.cinnamon.desktop.wm.preferences mouse-button-modifier "'<Super>'"

  # Power
  gset org.cinnamon.settings-daemon.plugins.power sleep-display-ac "900"
  gset org.cinnamon.settings-daemon.plugins.power sleep-display-battery "600"
  gset org.cinnamon.settings-daemon.plugins.power sleep-inactive-ac-timeout "1800"
  gset org.cinnamon.settings-daemon.plugins.power sleep-inactive-ac-type "'suspend'"
  gset org.cinnamon.settings-daemon.plugins.power sleep-inactive-battery-timeout "900"
  gset org.cinnamon.settings-daemon.plugins.power sleep-inactive-battery-type "'suspend'"

  # Bar
  gset org.cinnamon.desktop.interface first-day-of-week "6" # Saturday

  # File Manager
  gset org.nemo.icon-view default-zoom-level "large"
  gset org.nemo.preferences thumbnail-limit "31457280"

  log "DONE."
}

main "$@"
