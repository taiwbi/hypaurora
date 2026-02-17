# 🌌 Hypaurora

This is my **dotfiles** repository! 🎉 My personal configuration files for setting up and customizing the GNOME.

**If you want to use this make sure you clone it in `~/Documents/hypaurora` and change every `/home/mahdi` to whatever your user's home path is.**

## 🎨 Theme Management

Hypaurora features a unified theme management system! (Still not completed with the last changes) Change your entire desktop theme with one command:

```bash
usage: polarify [-h] {list,preview,apply,watch-dark-mode} ...

Hypaurora Theme Manager

positional arguments:
  {list,preview,apply,watch-dark-mode}
                        Commands
    list                List all available themes
    preview             Preview theme colors
    apply               Apply theme
    watch-dark-mode     Watch GNOME dark mode and auto-switch themes (GNOME only)
```

## 🎭 Customization

- ✨ Icon Pack: [MacTahoe-dark](https://github.com/vinceliuice/MacTahoe-icon-theme)
- 🖱️ Cursor Theme: [MacTahoe](https://github.com/vinceliuice/MacTahoe-icon-theme)
- 🅰️ Font Family: [Zed Sans](https://github.com/zed-industries/zed-fonts)
- ✍️ Persian Font Family: [Vazirmatn](https://rastikerdar.github.io/vazirmatn/en)
- 💻 Monospace Family: [Iosevka Extended](https://typeof.net/Iosevka/)
- 📜 Persian Monospace Family: [Vazir Code Hack](https://github.com/rastikerdar/vazir-code-font)

## Installation

- Clone the repo in `~/Documents/hypaurora`
- Change every `/home/mahdi` to whatever your user's home path is.
- Run link script `cd ~/Documents/hypaurora/ && ./scripts/link.sh`. **Be aware this will overwrite any existing configuration already exists.**
