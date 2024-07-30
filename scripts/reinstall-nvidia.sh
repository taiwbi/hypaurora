#!/bin/bash

red="\033[31m"
green="\033[32m"
yellow="\033[33m"
cyan="\033[36m"
reset_fg="\033[0m"

header_0="$red⦿  $green⦿  $yellow⦿ $reset_fg"
header_1="\n$red◉ $green◉ $yellow◉$reset_fg"
header_2="\n$red◉ $reset_fg"
header_3="\n$green◉ $reset_fg"

echo -e "$header_0 NVIDIA Reintall"
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

if [[ "$1" == "--continue" ]]; then
  echo "Continuing after reboot"
else
  echo -e "$header_1 This script will reinstall all the nvidia drivers and rebuild the secure boot keys."
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

  echo -e "$header_1 Uninstalling NVIDIA"
  sudo dnf remove xorg-x11-drv-nvidia\* -y

  echo -e "$header_1 Updating system"
  sudo dnf update -y
  sudo dnf install kernel-devel kernel-headers
  echo -e "$header_0 $red Rebooting, rerun the script with --continue after reboot"
  systemctl reboot
fi

echo -e "$header_1 Reinstall NVIDIA"

sudo dnf install akmod-nvidia -y # rhel/centos users can use kmod-nvidia instead
sudo dnf install xorg-x11-drv-nvidia-cuda -y #optional for cuda/nvdec/nvenc support
echo -e "$header_2 Waiting 5 minutes for NVIDIA to be build"
sleep 300 # Wait 5 minutes for kmod get build
nvidia_version=$(modinfo -F version nvidia 2>/dev/null)
if [[ $nvidia_version =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
    echo -e "$header_3 Valid NVIDIA driver version: $nvidia_version"
else
    echo -e "$header_2 Couldn't detect NVIDIA driver. Force rebuilding" 
    sudo akmods --force
    sleep 300
fi
sudo dnf mark install akmod-nvidia -y # To prevent autoremove to consider akmod-nvidia as uneeded
sudo dnf install xorg-x11-drv-nvidia-power -y
sudo systemctl enable nvidia-{suspend,resume,hibernate}
sudo dnf install vulkan -y
sudo dnf install xorg-x11-drv-nvidia-cuda-libs -y
sudo dnf install nvidia-vaapi-driver libva-utils vdpauinfo -y

read -p "Do you want to role secure boot MOK now? (Y/n): " answer

case ${answer:0:1} in
  y|Y )
    sudo dnf install kmodtool akmods mokutil openssl -y
    sudo kmodgenca -a
    echo  -e "$header_1 IMPORTANT"
    echo -e "$red Mokutil will asks to generate a password to enroll the public key. You will need this after reboot $reset_fg"
    sleep 10
    echo "On the next boot MOK Management is launched and you have to choose 'Enroll MOK'"
    sleep 5
    echo "Choose 'Continue' to enroll the key or 'View key 0' to show the keys already enrolled"
    sleep 5
    echo "Confirm enrollment by selecting 'Yes'."
    sleep 5
    echo "You will be invited to enter the password generated above"
    sleep 20
    sudo mokutil --import /etc/pki/akmods/certs/public_key.der
  ;;
  * )
    echo "Aborting..."
    exit
  ;;
esac
