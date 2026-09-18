#!/usr/bin/env bash
set -euo pipefail

PACMAN_DIR="/etc/pacman.d"
CHAOTIC_LIST="$PACMAN_DIR/chaotic-mirrorlist"
BACKUP_DIR="$PACMAN_DIR/mirror-backups/$(date +'%Y%m%d-%H%M%S')"

echo "==> Checking required tools..."

for cmd in cachyos-rate-mirrors rate-mirrors sudo mktemp; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: '$cmd' is not installed."
        exit 1
    fi
done

echo "==> Requesting sudo privileges..."
sudo -v

echo "==> Creating backups in:"
echo "    $BACKUP_DIR"

sudo mkdir -p "$BACKUP_DIR"

for file in \
    mirrorlist \
    cachyos-mirrorlist \
    cachyos-v3-mirrorlist \
    cachyos-v4-mirrorlist \
    chaotic-mirrorlist
do
    if [[ -f "$PACMAN_DIR/$file" ]]; then
        sudo cp -a "$PACMAN_DIR/$file" "$BACKUP_DIR/"
    fi
done

echo
echo "==> Ranking Arch + CachyOS mirrors..."
sudo cachyos-rate-mirrors

if [[ -f "$CHAOTIC_LIST" ]]; then
    echo
    echo "==> Ranking Chaotic-AUR mirrors..."

    tmpfile="$(mktemp)"
    trap 'rm -f "$tmpfile"' EXIT

    # Run rate-mirrors as the normal user.
    # It supports Chaotic-AUR directly.
    if rate-mirrors \
        --protocol https \
        --max-mirrors-to-output 10 \
        --save "$tmpfile" \
        chaotic-aur
    then
        if [[ -s "$tmpfile" ]] && grep -q '^Server' "$tmpfile"; then
            sudo install -m 0644 "$tmpfile" "$CHAOTIC_LIST"
            echo "==> Chaotic-AUR mirror list updated."
        else
            echo "Warning: generated Chaotic-AUR list looked invalid."
            echo "         Keeping the existing mirror list."
        fi
    else
        echo "Warning: Chaotic-AUR mirror ranking failed."
        echo "         Keeping the existing mirror list."
    fi
else
    echo
    echo "==> No $CHAOTIC_LIST found; skipping Chaotic-AUR."
fi

echo
echo "==> Mirror update complete."

echo
echo "Arch:"
grep '^Server' "$PACMAN_DIR/mirrorlist" 2>/dev/null | head -5 || true

echo
echo "CachyOS:"
grep '^Server' "$PACMAN_DIR/cachyos-mirrorlist" 2>/dev/null | head -5 || true

echo
echo "CachyOS v3:"
grep '^Server' "$PACMAN_DIR/cachyos-v3-mirrorlist" 2>/dev/null | head -5 || true

echo
echo "CachyOS v4:"
grep '^Server' "$PACMAN_DIR/cachyos-v4-mirrorlist" 2>/dev/null | head -5 || true

echo
echo "Chaotic-AUR:"
grep '^Server' "$CHAOTIC_LIST" 2>/dev/null | head -5 || true

echo
echo "Backups saved to:"
echo "  $BACKUP_DIR"

echo
echo "You can now update normally with:"
echo "  sudo pacman -Syu"
