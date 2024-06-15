# 🌌 Hyprland Dotfiles

Welcome to my **Hyprland dotfiles** repository. 🎉 These are my personal configuration files for setting up and customizing the Hyprland window manager.

## What's Included?? 🤔

This repository includes configuration files for ✨:

- **Hyprland**: Dynamic tiling Wayland compositor
- **Waybar**: Customizable status bar for Wayland
- **Dunst**:
- **Kitty**: Fast, cross-platform terminal emulator
- **Wofi**: Application launcher
- **Neovide**: Beautiful and feature-rich neovim GUI
- **Fastfetch**:
- **foot**:
- **adw-gtk3** & **LibAdwaita**: Catppuccin Mocha and Catppuccin Latte themes for dark and light mode
- **tmux**:
- **mpv**:

## Dependencies 🛠️

Make sure you have the following installed before using these dotfiles:

- **Hyprland**: The star of the show.
- **Waybar**: A highly customizable status bar for Wayland.
- **wofi**: An application launcher, and dmenu replacement.
<!--  TODO: add dependencies -->

## Installation 🚀

Follow these steps to get your Hyprland environment up and running with these dotfiles:

1. **Clone this repository:**

   ```bash
   git clone https://github.com/taiwbi/hyprland-dotfiles.git
   cd hyprland-dotfiles
   ```

2. **Backup your existing dotfiles:**

   It's always a good idea to backup your existing configuration files:

   ```bash
   mkdir -p ~/dotfiles_backup
   cp -r ~/.config/hyprland ~/.config/waybar ~/.config/alacritty ~/.config/rofi ~/.config/nvim ~/dotfiles_backup/
   ```

3. **Install the new dotfiles:**

   Copy the new configuration files to your home directory:

   ```bash
   cp -r .config/* ~/.config/
   ```

4. **Start Hyprland:**

   Now, start or restart Hyprland to see the magic happen!

   ```bash
   Hyprland
   ```

## Customization 🎨

Feel free to tweak these configurations to your heart's content. Here are some tips:

- **Hyprland**: Edit the `~/.config/hyprland/hyprland.conf` file to change keybindings, window rules, and more.
- **Waybar**: Customize the `~/.config/waybar/config` and `~/.config/waybar/style.css` files for your status bar.

## Contributing 🤝

Got some cool tweaks or fixes? Contributions are welcome! Feel free to fork this repo, make your changes, and open a pull request.

## License 📄

Do what the hell you want with this.

---

Happy customizing! If you run into any issues or have questions, don't hesitate to open an issue or reach out. May your Hyprland setup be ever in your favor! 🌟
