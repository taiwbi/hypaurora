#!/bin/bash

red="\033[31m"
green="\033[32m"
yellow="\033[33m"
reset_fg="\033[0m"

header_0="$red⦿  $green⦿  $yellow⦿ $reset_fg"

echo -e "$header_0 Are you sure? $red THIS WILL REMOVE ALL OF YOUR PREVIOUS CONFIGURATIONS.$reset_fg"
read -rp "(y/n)" yn

if [ "$yn" != "y" ]; then
  echo -e "Ok, I won't ruin your configs :)"
  exit
fi


rm -rf "$HOME/.config/fontconfig";
ln -s "$PWD/fontconfig" "$HOME/.config/"

rm -rf "$HOME/.config/mpv";
ln -s "$PWD/mpv" "$HOME/.config/"

rm -rf "$HOME/.config/gtk-3.0";
ln -s "$PWD/gtk-3.0" "$HOME/.config/"

rm -rf "$HOME/.config/gtk-4.0";
ln -s "$PWD/gtk-4.0" "$HOME/.config/"

rm -rf "$HOME/.config/ghostty";
ln -s "$PWD/ghostty" "$HOME/.config/"

rm -rf "$HOME/.config/tmux";
ln -s "$PWD/tmux" "$HOME/.config/"

rm -rf "$HOME/.config/fish";
ln -sf "$PWD/fish" "$HOME/.config/fish"

rm -rf "$HOME/.config/Kvantum";
ln -sf "$PWD/kvantum" "$HOME/.config/Kvantum"

rm -rf "$HOME/.config/qt6ct";
ln -sf "$PWD/qt" "$HOME/.config/qt6ct"

rm -rf "$HOME/.bashrc"
ln -sf "$PWD/bash/bashrc" "$HOME/.bashrc"

mkdir -p $HOME/.local/binary/

rm -rf "$HOME/.local/binary/polarify"
ln -sf "$PWD/polarify.py" "$HOME/.local/binary/polarify"

if [ -d "$HOME/.local/share/epiphany" ]; then
  rm -f "$HOME/.local/share/epiphany/user-*";
  ln -sf "$PWD/epiphany/user-javascript.js" "$HOME/.local/share/epiphany/user-javascript.js" 
  ln -sf "$PWD/epiphany/user-stylesheet.css" "$HOME/.local/share/epiphany/user-stylesheet.css"
fi

git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

echo -e ""
