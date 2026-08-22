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
  "aporetic-sans|https://raw.githubusercontent.com/protesilaos/aporetic/main/aporetic-sans/TTF/aporetic-sans-normalbolditalic.ttf,https://raw.githubusercontent.com/protesilaos/aporetic/main/aporetic-sans/TTF/aporetic-sans-normalboldupright.ttf,https://raw.githubusercontent.com/protesilaos/aporetic/main/aporetic-sans/TTF/aporetic-sans-normalregularitalic.ttf,https://raw.githubusercontent.com/protesilaos/aporetic/main/aporetic-sans/TTF/aporetic-sans-normalregularupright.ttf"
  "aporetic-sans-mono|https://raw.githubusercontent.com/protesilaos/aporetic/main/aporetic-sans-mono/TTF/aporetic-sans-mono-normalbolditalic.ttf,https://raw.githubusercontent.com/protesilaos/aporetic/main/aporetic-sans-mono/TTF/aporetic-sans-mono-normalboldupright.ttf,https://raw.githubusercontent.com/protesilaos/aporetic/main/aporetic-sans-mono/TTF/aporetic-sans-mono-normalregularitalic.ttf,https://raw.githubusercontent.com/protesilaos/aporetic/main/aporetic-sans-mono/TTF/aporetic-sans-mono-normalregularupright.ttf"
  "nerd-fonts-symbols|https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/NerdFontsSymbolsOnly.zip"
  "0xProto|https://github.com/0xType/0xProto/releases/download/2.502/0xProto_2_502.zip"
  "commit-mono|https://github.com/eigilnikolajsen/commit-mono/releases/download/v1.143/CommitMono-1.143.zip"
  "iosevka|https://github.com/be5invis/Iosevka/releases/download/v34.8.0/PkgTTC-SGr-Iosevka-34.8.0.zip"
  "iosevka-term|https://github.com/be5invis/Iosevka/releases/download/v34.8.0/PkgTTC-SGr-IosevkaTerm-34.8.0.zip"
  "iosevka-aile|https://github.com/be5invis/Iosevka/releases/download/v34.8.0/PkgTTC-IosevkaAile-34.8.0.zip"
  "elephant|https://github.com/taiwbi/elephant/releases/download/34.8.0/Elephant-34.8.0.zip"
  "monaspace|https://github.com/githubnext/monaspace/releases/download/v1.400/monaspace-static-v1.400.zip"
  "zed-mono|https://github.com/taiwbi/zed-fonts/releases/download/v34.8.0-3/Zed-Mono-v34.8.0-3.zip"
  "zed-sans|https://github.com/taiwbi/zed-fonts/releases/download/v34.8.0-3/Zed-Sans-v34.8.0-3.zip"
)
manal_fonts=(
  "Aria|For Persian and Arabic serif texts"
)

install_font() {
  local name="$1" url="$2"
  local dest_dir="$fonts_dir/$name"

  if [ -d "$dest_dir" ] && find "$dest_dir" -type f \( -iname "*.ttf" -o -iname "*.otf" -o -iname "*.ttc" \) -print -quit | grep -q .; then
    echo -e "$header_2 $name already installed, skipping"
    return
  fi

  echo -e "$header_2 Downloading $name"
  echo -e "$header_2 Installing $name to $dest_dir"
  rm -rf "$dest_dir"
  mkdir -p "$dest_dir"

  # Fonts without a release archive are listed as comma-separated raw .ttf
  # URLs instead (including fonts stored in a GitHub repository directory).
  if [[ "$url" == *.ttf ]] || [[ "$url" == *.ttf,* ]]; then
    IFS=',' read -ra ttf_urls <<< "$url"
    for ttf_url in "${ttf_urls[@]}"; do
      if ! curl -fsSL -o "$dest_dir/${ttf_url##*/}" "$ttf_url"; then
        echo -e "$header_2 Failed to download $name" >&2
        return 1
      fi
    done
    return
  fi

  local ext="${url##*.}"
  [[ "$url" == *.tar.xz ]] && ext="tar.xz"
  local archive="$tmp_dir/$name.$ext"
  local extract_dir="$tmp_dir/$name"

  curl -fsSL -o "$archive" "$url"

  mkdir -p "$extract_dir"
  case "$archive" in
    *.tar.xz) tar -xf "$archive" -C "$extract_dir" ;;
    *.zip) unzip -qo "$archive" -d "$extract_dir" ;;
  esac

  find "$extract_dir" -type f \( -iname "*.ttf" -o -iname "*.otf" -o -iname "*.ttc" \) -exec cp -f {} "$dest_dir/" \;

  if ! find "$dest_dir" -type f \( -iname "*.ttf" -o -iname "*.otf" -o -iname "*.ttc" \) -print -quit | grep -q .; then
    echo -e "$header_2 Failed to find font files for $name in the downloaded archive" >&2
    return 1
  fi
}

echo -e "$header_1 Installing fonts to $fonts_dir"

mkdir -p "$fonts_dir"

failed=0
for entry in "${fonts[@]}"; do
  install_font "${entry%%|*}" "${entry#*|}" || failed=1
done

if (( failed )); then
  echo -e "$header_2 One or more fonts could not be installed" >&2
  exit 1
fi

echo -e "$header_1 Refreshing font cache"
fc-cache -f "$fonts_dir"


echo -e "$header_1 You still need to install the following fonts manually:"

for entry in "${manal_fonts[@]}"; do
  echo "${entry%%|*} -> ${entry#*|}"
done

echo -e "$header_3 Done."
