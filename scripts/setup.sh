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

# TODO: Enable DNS-over-HTTPS on system

echo "$header_1 Enabling needed repositories"
sleep 5
sudo dnf update -y
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm -y
sudo dnf config-manager --enable fedora-cisco-openh264 -y
sudo dnf update -y

sudo dnf update -y # and reboot if you are not on the latest kernel
sudo dnf install akmod-nvidia -y # rhel/centos users can use kmod-nvidia instead
sudo dnf install xorg-x11-drv-nvidia-cuda -y #optional for cuda/nvdec/nvenc support
echo "$header_2 Waiting 5 minutes for NVIDIA to be build"
sleep 300 # Wait 5 minutes for kmod get build
nvidia_version=$(modinfo -F version nvidia 2>/dev/null)
if [[ $nvidia_version =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
    echo "$header_3 Valid NVIDIA driver version: $nvidia_version"
else
    echo "$header_2 Couldn't detect NVIDIA driver. Waiting another 5 minutes"
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
    echo "$header_1 IMPORTANT"
    echo "$red Mokutil asks to generate a password to enroll the public key. You will need this after reboot $reset_fg"
    sleep 10
    echo "On the next boot MOK Management is launched and you have to choose 'Enroll MOK'"
    sleeo 5
    echo "Choose 'Continue' to enroll the key or 'View key 0' to show the keys already enrolled"
    sleeo 5
    echo "Confirm enrollment by selecting 'Yes'."
    sleeo 5
    echo "You will be invited to enter the password generated above"
    sleep 20
    sudo mokutil --import /etc/pki/akmods/certs/public_key.der
  ;;
  * )
    echo "Aborting..."
    exit
  ;;
esac

# TODO: https://rpmfusion.org/Howto/CUDA

sudo dnf swap ffmpeg-free ffmpeg --allowerasing
sudo dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf install @sound-and-video
sudo dnf update @sound-and-video
sudo dnf install intel-media-driver
sudo dnf install libva-nvidia-driver

# Install software

sudo dnf install ripgrep nodejs npm wl-clipboard socat fish neovim aria2c python-pip unrar
sudo dnf install adw-gtk3-theme epiphany chromium gnome-console telegram-desktop celluloid lollypop gnome-tweaks gnome-extensions-app gnome-shell-extension-light-style gnome-shell-extension-screenshot-window-sizer.noarch
sudo dnf install php php-pecl-xdebug3 composer

sudo dnf copr enable dusansimic/themes
sudo dnf install morewaita-icon-theme

sudo dnf copr enable atim/lazygit
sudo dnf install lazygit

curl -sS https://starship.rs/install.sh | sh

# Install Rust
sudo dnf install rustup
rustup-init

sudo flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
sudo flatpak install flathub-beta app.drey.PaperPlane

# TODO: lazygit, gnome-shell-extension-legacy-theme-auto-switcher user-stylesheet@tomaszgasior.pl

sudo dnf remove firefox gnome-terminal rhythmbox

# Settings 

gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
gsettings set org.gnome.desktop.interface gtk-theme "'adw-gtk3'"

gsettings set org.gnome.shell.keybindings switch-to-application-1 "@as []"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
gsettings set org.gnome.shell.keybindings switch-to-application-2 "@as []"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
gsettings set org.gnome.shell.keybindings switch-to-application-3 "@as []"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
gsettings set org.gnome.shell.keybindings switch-to-application-4 "@as []"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']"
gsettings set org.gnome.shell.keybindings switch-to-application-5 "@as []"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "['<Super>5']"
gsettings set org.gnome.shell.keybindings switch-to-application-6 "@as []"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 "['<Super>6']"
gsettings set org.gnome.shell.keybindings switch-to-application-7 "@as []"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-7 "['<Super>7']"
gsettings set org.gnome.shell.keybindings switch-to-application-8 "@as []"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-8 "['<Super>8']"
gsettings set org.gnome.shell.keybindings switch-to-application-9 "@as []"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-9 "['<Super>9']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-10 "['<Super>0']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Shift><Super>1']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Shift><Super>2']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Shift><Super>3']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Shift><Super>4']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-5 "['<Shift><Super>5']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-6 "['<Shift><Super>6']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-7 "['<Shift><Super>7']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-8 "['<Shift><Super>8']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-9 "['<Shift><Super>9']"

gsettings set org.gnome.desktop.wm.keybindings maximize "['<Super>Up']"
gsettings set org.gnome.desktop.wm.keybindings unmaximize "['<Super>Down', '<Alt>F5']"
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q']"

gsettings set org.gnome.desktop.wm.keybindings move-to-center "['<Super>C']"
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Super>f']"
gsettings set org.gnome.desktop.wm.preferences resize-with-right-button 'true'
gsettings set org.gnome.shell.app-switcher current-workspace-only 'true'
gsettings set org.gnome.mutter center-new-windows 'true'

gsettings set org.gnome.desktop.peripherals.touchpad accel-profile 'flat'
gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled 'true'
gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'flat'
gsettings set org.gnome.desktop.peripherals.mouse speed '0.45'
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'ir')]"
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'ir')]"
gsettings set org.gnome.desktop.input-sources per-window 'true'

gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first 'true'
gsettings set org.gnome.nautilus.preferences show-create-link 'true'
gsettings set org.gnome.nautilus.preferences click-policy 'single'

gsettings set org.gnome.Epiphany restore-session-policy 'crashed'
gsettings set org.gnome.Epiphany search-engine-providers "[{'url': <'https://www.bing.com/search?q=%s'>, 'bang': <'\!bi'>, 'name': <'Bing'>}, {'url': <'https://duckduckgo.com/?q=%s&t=epiphany'>, 'bang': <'\!ddg'>, 'name': <'DuckDuckGo'>}, {'url': <'https://www.google.com/search?q=%s'>, 'bang': <'\!g'>, 'name': <'Google'>}, {'url': <'https://search.brave.com/search?q=%s&source=web&summary=1'>, 'bang': <'\!b'>, 'name': <'Brave'>}]"
gsettings set org.gnome.Epiphany default-search-engine 'Brave'
gsettings set org.gnome.Lollypop save-state 'true'
dconf write /org/gnome/desktop/notifications/application/org-gnome-lollypop/enable 'false'

# TODO: Set Automatic suspend to 30 mins on battery
