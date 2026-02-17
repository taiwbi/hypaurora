#!/usr/bin/env bash
# Installs Iosevka Font family as the default font family
#
set -euo pipefail

# Requirements
for cmd in curl aria2c unzip fc-cache; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Error: '$cmd' is required but not installed." >&2
    exit 1
  }
done

REPO="be5invis/Iosevka"
BASE="https://github.com/${REPO}/releases/download"

# Resolve latest release tag via redirect
latest_url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest")"
tag="${latest_url##*/}"   # e.g. v34.1.0
ver="${tag#v}"            # e.g. 34.1.0

echo "Latest Iosevka release detected: ${tag}"

tmp="$(mktemp -d)"
# cleanup() { rm -rf "$tmp"; }
# trap cleanup EXIT

zip="PkgTTF-Iosevka-${ver}.zip"

url="${BASE}/${tag}/${zip}"

fonts_root="${HOME}/.local/share/fonts/Mono"
dest="${fonts_root}/Iosevka"

mkdir -p "$dest"

echo "Downloading..."
aria2c -x 16 -s 16 -d "$tmp" "$url"

echo "Installing into:"
echo "  $dest"

# Remove old files to avoid stale leftovers
rm -rf "${dest:?}/"* 2>/dev/null || true

unzip -oq "${tmp}/${zip}" -d "$dest"

echo "Refreshing font cache..."
fc-cache -f "$fonts_root" >/dev/null

echo "Done. Installed Iosevka ${ver} into:"
echo "  $dest"
