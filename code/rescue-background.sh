#!/usr/bin/env bash

set -Eeuo pipefail

readonly ORIGINAL_BACKGROUND="${XDG_CONFIG_HOME:-$HOME/.config}/background"
readonly RESCUE_BACKGROUND="$HOME/Pictures/rescue.jpg"

die() {
	printf 'rescue-background: %s\n' "$*" >&2
	exit 1
}

set_background() {
	local background="$1"

	[[ -f "$background" ]] || die "background does not exist: $background"
	command -v hyprctl >/dev/null 2>&1 || die "hyprctl was not found in PATH"

	hyprctl hyprpaper wallpaper ",${background},cover" >/dev/null || \
		die "could not change the Hyprpaper wallpaper"
}

notify() {
	if command -v notify-send >/dev/null 2>&1; then
		notify-send "$1" "$2" || true
	fi
}

case "${1:-}" in
	rescue)
		set_background "$RESCUE_BACKGROUND"
		notify "Rescue background" "Rescue background enabled."
		;;
	restore)
		set_background "$ORIGINAL_BACKGROUND"
		notify "Background restored" "Original background restored."
		;;
	*)
		die "usage: $0 {rescue|restore}"
		;;
esac
