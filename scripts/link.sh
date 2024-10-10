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

rm -rf "$HOME/.config/dunst" && ln -s "$PWD/dunst" "$HOME/.config/"
rm -rf "$HOME/.config/fastfetch" && ln -s "$PWD/fastfetch" "$HOME/.config/"
rm -rf "$HOME/.config/starship.toml" && ln -s "$PWD/starship.toml" "$HOME/.config/starship.toml"
rm -rf "$HOME/.config/fontconfig" && ln -s "$PWD/fontconfig" "$HOME/.config/"
rm -rf "$HOME/.config/gtk-3.0" && ln -s "$PWD/gtk-3.0" "$HOME/.config/"
rm -rf "$HOME/.config/gtk-4.0" && ln -s "$PWD/gtk-4.0" "$HOME/.config/"
rm -rf "$HOME/.config/hypr" && ln -s "$PWD/hypr" "$HOME/.config/"
rm -rf "$HOME/.config/kitty" && ln -s "$PWD/kitty" "$HOME/.config/"
rm -rf "$HOME/.config/mpv" && ln -s "$PWD/mpv" "$HOME/.config/"
rm -rf "$HOME/.config/neovide" && ln -s "$PWD/neovide" "$HOME/.config/"
rm -rf "$HOME/.config/tmux" && ln -s "$PWD/tmux" "$HOME/.config/"
rm -rf "$HOME/.config/waybar" && ln -s "$PWD/waybar" "$HOME/.config/"
rm -rf "$HOME/.config/wofi" && ln -s "$PWD/wofi" "$HOME/.config/"
rm -rf "$HOME/.config/fish" && ln -s "$PWD/fish" "$HOME/.config/"
rm -rf "$HOME/.vimrc" && ln -s "$PWD/vimrc" "$HOME/.vimrc"

rm -rf "$HOME/.local/share/hypr-scripts" && ln -s "$PWD"/hypr-scripts "$HOME/.local/share/"
rm -rf "$HOME/.local/share/nautilus/scripts" && ln -s "$PWD"/nautilus-scripts "$HOME/.local/share/nautilus/scripts"
rm -rf "$HOME/.ideavimrc" && ln -s "$PWD/ideavimrc" "$HOME/.ideavimrc"
rm -rf "$HOME/.local/bin/toggle-proxy" && ln -s "$PWD/bin/toggle-proxy" "$HOME/.local/bin/toggle-proxy"
rm -rf "$HOME/.local/bin/toggle-background" && ln -s "$PWD/bin/toggle-background" "$HOME/.local/bin/toggle-background"
rm -rf "$HOME/.local/share/alchemy" && ln -s "$PWD/alchemy" "$HOME/.local/share/alchemy/"
mkdir -p ~/.config/autostart
rm -f "$HOME/.local/share/applications/Hypaurora.desktop" && cp "$PWD/alchemy/Hypaurora.desktop" "$HOME/.config/autostart/Hypaurora.desktop"

echo -e ""
