# 🌌 Hypaurora

Welcome to my **Hyprland dotfiles** repository! 🎉 These are my personal configuration files for setting up and customizing the Hyprland window manager.

<img src="https://raw.githubusercontent.com/taiwbi/hypaurora/main/assets/dark-clean.png" alt="Dark Mode screenshot">
<img src="https://raw.githubusercontent.com/taiwbi/hypaurora/main/assets/dark-apps.png" alt="Dark Mode with apps screenshot">
<img src="https://raw.githubusercontent.com/taiwbi/hypaurora/main/assets/light-clean.png" alt="Light Mode screenshot">
<img src="https://raw.githubusercontent.com/taiwbi/hypaurora/main/assets/light-apps.png" alt="Light Mode with apps screenshot">

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
   sudo dnf install kitty wofi waybar hyprland xdg-desktop-portal-hyprland hyprpaper hyprlock hypridle hyprland-plugins brightnessctl grim slurp wl-clipboard dunst fswebcam
   ```

   ##### Per Windows Keyboard Layout

   If you want per-window layout support:

   ```bash
   sudo dnf install cargo
   cargo install hyprland-per-window-layout
   ```

   ##### Night Light (Blue Light Filter) Support

   To enable night light support:

   1. Install the required dependencies:

      ```bash
      sudo dnf install cargo
      cargo install hyprland-per-window-layout
      ```

   2. Configure night light settings:

      Edit the `hypr-scripts/night-light.sh` file to adjust the hours and temperature:

      ```sh
      if [ "$current_hour" -ge 20 ] || [ "$current_hour" -lt 5 ]; then
        if ! pgrep -x "wl-gammarelay-rs" > /dev/null; then
          wl-gammarelay-rs &
          busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Temperature q 2300
      ```

      - Start time: 8 PM (`-ge 20`)
      - End time: 5 AM (`-lt 5`)
      - Temperature: 2300 (lower values increase blue light filtering)

      Modify these values to customize your night light schedule and intensity.

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

This dotfiles also a have a more beautiful and fancy design, checkout main branch
