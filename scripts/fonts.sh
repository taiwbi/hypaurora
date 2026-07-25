#!/bin/bash

# Hypaurora font installation script — downloads fonts straight from their
# GitHub releases (instead of distro packages) and installs them for the
# current user only.

red="\033[31m"
green="\033[32m"
yellow="\033[33m"
reset_fg="\033[0m"

header_1="\n$red◉ $green◉ $yellow◉$reset_fg"
header_2="\n$red◉ $reset_fg"
header_3="\n$green◉ $reset_fg"

fonts_dir="$HOME/.local/share/fonts"
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

# name|archive-url (.tar.xz / .zip) OR name|comma-separated raw .ttf urls
fonts=(
  "hack|https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.tar.xz"
  "geist|https://github.com/vercel/geist-font/releases/download/v1.7.2/geist-font-v1.7.2.zip"
  "vazirmatn|https://github.com/rastikerdar/vazirmatn/releases/download/v33.003/vazirmatn-v33.003.zip"
  "vazir-code|https://github.com/rastikerdar/vazir-code-font/releases/download/v1.1.2/vazir-code-font-v1.1.2.zip"
  "lusitana|https://raw.githubusercontent.com/google/fonts/main/ofl/lusitana/Lusitana-Regular.ttf,https://raw.githubusercontent.com/google/fonts/main/ofl/lusitana/Lusitana-Bold.ttf"
)

install_font() {
  local name="$1" url="$2"
  local dest_dir="$fonts_dir/$name"

  echo -e "$header_2 Downloading $name"
  echo -e "$header_2 Installing $name to $dest_dir"
  rm -rf "$dest_dir"
  mkdir -p "$dest_dir"

  # Lusitana (and other Google Fonts entries without a GitHub release
  # archive) are listed as comma-separated raw .ttf urls instead.
  if [[ "$url" == *.ttf ]] || [[ "$url" == *.ttf,* ]]; then
    IFS=',' read -ra ttf_urls <<< "$url"
    for ttf_url in "${ttf_urls[@]}"; do
      curl -sL -o "$dest_dir/${ttf_url##*/}" "$ttf_url"
    done
    return
  fi

  local archive="$tmp_dir/$name.${url##*.}"
  local extract_dir="$tmp_dir/$name"

  curl -sL -o "$archive" "$url"

  mkdir -p "$extract_dir"
  case "$archive" in
    *.tar.xz) tar -xf "$archive" -C "$extract_dir" ;;
    *.zip) unzip -qo "$archive" -d "$extract_dir" ;;
  esac

  find "$extract_dir" -type f -name "*.ttf" -exec cp -f {} "$dest_dir/" \;
}

echo -e "$header_1 Installing fonts to $fonts_dir"

mkdir -p "$fonts_dir"

for entry in "${fonts[@]}"; do
  install_font "${entry%%|*}" "${entry#*|}"
done

echo -e "$header_1 Refreshing font cache"
fc-cache -f "$fonts_dir"

echo -e "$header_3 Done."
