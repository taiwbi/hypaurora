#!/bin/bash

red="\033[31m"
green="\033[32m"
yellow="\033[33m"
cyan="\033[36m"
reset_fg="\033[0m"

header_0="$red⦿  $green⦿  $yellow⦿ $reset_fg"
header_1="\n$red◉ $green◉ $yellow◉$reset_fg"

echo -e "$header_0 Fedora GNOME Setup"
echo -e "$cyan"
echo "  _    _                                             "
echo " | |  | |                                            "
echo " | |__| |_   _ _ __   __ _ _   _ _ __ ___  _ __ __ _ "
echo " |  __  | | | | '_ \ / _\` | | | | '__/ _ \| '__/ _\` |"
echo " | |  | | |_| | |_) | (_| | |_| | | | (_) | | | (_| |"
echo " |_|  |_|\__, | .__/ \__,_|\__,_|_|  \___/|_|  \__,_|"
echo "          __/ | |                                    "
echo "         |___/|_|                                    "
echo -e "$reset_fg\n"

echo "$header_1 This script is created to setup a workable system on Fedora Workstation for myself, this script might not work as good as it works for me."
read -p "Do you want to proceed? (Y/n): " answer

case ${answer:0:1} in
  y|Y )
    echo "Proceeding..."
  ;;
  * )
    echo "Aborting..."
    exit
  ;;
esac

bash -c "$PWD/scripts/installation.sh"
bash -c "$PWD/scripts/link.sh"
bash -c "$PWD/scripts/config.sh"

# TODO: Set Automatic suspend to 30 mins on battery
