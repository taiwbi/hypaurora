#!/bin/bash

red="\033[31m"
green="\033[32m"
yellow="\033[33m"
reset_fg="\033[0m"

header_0="$red⦿  $green⦿  $yellow⦿ $reset_fg"

echo -e "$header_0 This script is suppoed to be ran on server or computer without GUI instaleld."
echo -e "$header_0 Are you sure? $red THIS WILL REMOVE ALL OF YOUR PREVIOUS CONFIGUTAIONS.$reset_fg"
read -rp "(y/n)" yn

if [ "$yn" != "y" ]; then
  echo -e "Ok, I won't ruin your configs :)"
  exit
fi

mkdir -p "$HOME/Pictures/background/"

rm -rf "$HOME/.config/starship.toml" && ln -s "$PWD/starship.toml" "$HOME/.config/starship.toml"
rm -rf "$HOME/.config/tmux" && ln -s "$PWD/tmux" "$HOME/.config/"
rm -rf "$HOME/.config/fish" && ln -s "$PWD/fish" "$HOME/.config/"
rm -rf "$HOME/.vimrc" && ln -s "$PWD/vimrc" "$HOME/.vimrc"

echo -e ""
