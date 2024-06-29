# 🌌 Hypaurora Lite

Welcome to my **Hyprland dotfiles** repository! 🎉 These are my personal configuration files for setting up and customizing the Hyprland window manager in a more compact and minimal design.

<img src="https://raw.githubusercontent.com/taiwbi/hypaurora/lite/assets/dark-clean.png" alt="Dark Mode screenshot">
<img src="https://raw.githubusercontent.com/taiwbi/hypaurora/lite/assets/dark-apps.png" alt="Dark Mode with apps screenshot">
<img src="https://raw.githubusercontent.com/taiwbi/hypaurora/lite/assets/light-clean.png" alt="Light Mode screenshot">
<img src="https://raw.githubusercontent.com/taiwbi/hypaurora/lite/assets/light-apps.png" alt="Light Mode with apps screenshot">

## What's Included? 🤔

This repository includes configuration files for:

- **Hyprland**: Dynamic tiling Wayland compositor
- **Waybar**: Customizable status bar for Wayland
- **Dunst**: Catppuccin minimal theme for Dunst
- **Kitty**: Fast, cross-platform terminal emulator
- **Wofi**: Application launcher
- **Neovide**: Beautiful and feature-rich Neovim GUI
- **Fastfetch**: Stunning system information fetch tool
- **adw-gtk3** & **LibAdwaita**: Catppuccin Mocha and Catppuccin Latte themes for dark and light mode
- **tmux**: Terminal multiplexer

## Installation 🚀

Follow these steps to set up your Hyprland environment with these dotfiles (on Fedora):

1. **Clone this repository:**

Clone the repository and checkout the lite branch

```bash
git clone --recursive https://github.com/taiwbi/hypaurora.git
cd hypaurora
```

2. **Install dependencies:**

   First, Add Hyprland copr:

   ```sh
   sudo dnf copr enable solopasha/hyprland
   sudo dnf update -y
   ```

   Install the necessary packages for the configuration to work properly.

   ```bash
   sudo dnf install fish gnome-keyring polkit-gnome git bc jq socat inotify-tools
   sudo dnf install kitty icat wofi waybar hyprland xdg-desktop-portal-hyprland hyprpaper hyprlock hypridle brightnessctl grim slurp wl-clipboard dunst fswebcam
   ```

   If you want per-window layout support:

   ```bash
   sudo dnf install cargo
   cargo install hyprland-per-window-layout
   ```

3. **Install the new dotfiles:**

   Link the dotfiles to your configuration directories. **Be aware if you already have any configuration files in the specified directories, those all will be removed**

   ```bash
   ./scripts/link.sh
   ```

4. **Start Hyprland:**

   Start or restart Hyprland to apply the new configuration.

   ```bash
   Hyprland
   ```

---

Happy customizing! If you run into any issues or have questions, don't hesitate to open an issue or reach out. May your Hyprland lite setup be ever in your favor! 🌟

---

This dotfiles also a have a more beautiful and fancy design, checkout lite branch
