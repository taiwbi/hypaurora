#!/usr/bin/env bash

# Keep Waybar hidden on occupied Hyprland workspaces and visible on empty ones.

set -Eeuo pipefail

hyprland_signature="${HYPRLAND_INSTANCE_SIGNATURE:?HYPRLAND_INSTANCE_SIGNATURE is not set}"
runtime_dir="${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set}"
hyprland_socket="$runtime_dir/hypr/$hyprland_signature/.socket2.sock"

send_waybar_signal() {
    local signal="$1"
    local waybar_pid

    while read -r waybar_pid; do
        [[ -n "$waybar_pid" ]] || continue
        kill "-$signal" "$waybar_pid" 2>/dev/null || true
    done < <(pgrep --exact waybar || true)
}

workspace_has_windows() {
    local workspace_id clients

    workspace_id="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // empty')" || return 1
    [[ -n "$workspace_id" ]] || return 1

    clients="$(hyprctl clients -j 2>/dev/null)" || return 1
    jq -e --argjson workspace_id "$workspace_id" \
        'any(.[]; .workspace.id == $workspace_id)' <<<"$clients" >/dev/null
}

sync_waybar_visibility() {
    if workspace_has_windows; then
        # SIGUSR1 is configured as an idempotent hide action in Waybar.
        send_waybar_signal USR1
    else
        # SIGUSR2 is configured as an idempotent show action in Waybar.
        send_waybar_signal USR2
    fi
}

while [[ ! -S "$hyprland_socket" ]]; do
    sleep 1
done

sync_waybar_visibility || true

# Any Hyprland event may affect the active workspace or its clients. Recheck
# the authoritative state instead of parsing event payloads.
while IFS= read -r _event; do
    sync_waybar_visibility || true
done < <(socat -u "UNIX-CONNECT:$hyprland_socket" - 2>/dev/null)

exit 1
