#!/bin/bash

red="\033[31m"
green="\033[32m"
yellow="\033[33m"
reset_fg="\033[0m"

header_0="$red⦿  $green⦿  $yellow⦿ $reset_fg"

echo -e "$header_0 Are you sure? $red THIS WILL REMOVE ALL OF YOUR PREVIOUS CONFIGUTAIONS.$reset_fg"
read -rp "(y/n)" yn

if [ "$yn" != "y" ]; then
  echo -e "Ok, I won't ruin your configs :)"
  exit
fi

mkdir -p "$HOME/Pictures/background/"

rm -rf "$HOME/.config/starship.toml" && ln -s "$PWD/starship.toml" "$HOME/.config/starship.toml"
rm -rf "$HOME/.config/fontconfig" && ln -s "$PWD/fontconfig" "$HOME/.config/"
rm -rf "$HOME/.config/mpv" && ln -s "$PWD/mpv" "$HOME/.config/"
rm -rf "$HOME/.config/gtk-3.0" && ln -s "$PWD/gtk-3.0" "$HOME/.config/"
rm -rf "$HOME/.config/gtk-4.0" && ln -s "$PWD/gtk-4.0" "$HOME/.config/"
rm -rf "$HOME/.config/ghostty" && ln -s "$PWD/ghostty" "$HOME/.config/"
rm -rf "$HOME/.config/tmux" && ln -s "$PWD/tmux" "$HOME/.config/"
rm -rf "$HOME/.vimrc" && ln -s "$PWD/vimrc" "$HOME/.vimrc"
rm -rf "$HOME/.ideavimrc" && ln -s "$PWD/ideavimrc" "$HOME/.ideavimrc"
rm -rf "$HOME/.local/utils" && ln -s "$PWD/utils" "$HOME/.local/utils"
rm -rf "$HOME/.bashrc" && ln -s "$PWD/bash/bashrc" "$HOME/.bashrc"
rm -rf "$HOME/.bashrc.d" && ln -s "$PWD/bash/bashrc.d" "$HOME/.bashrc.d"

echo -e ""
