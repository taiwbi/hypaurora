# 🌌 Hypaurora

Welcome to my **dotfiles** repository! 🎉 These are my personal configuration files for setting up and customizing the Hyprland.

> If you want to use this make sure you clone it in `~/Documents/hypaurora`

## 🎨 Theme Management

Hypaurora features a unified theme management system! Change your entire desktop theme with one command:

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

- ✨ Icon Pack: [Neuwaita](https://github.com/RusticBard/Neuwaita)
- 🖱️ Cursor Theme: [MacOS Tahoe Cursor](https://www.gnome-look.org/p/2300466)
- 🅰️ Font Family: [Geist](https://vercel.com/font)
- ✍️ Persian Font Family: [Vazirmatn](https://rastikerdar.github.io/vazirmatn/en)
- 💻 Monospace Family: [FantasqueSansMono Nerd Font](https://github.com/be5invis/Iosevka)
- 📜 Persian Monospace Family: [AzarMehrMonospaced](https://github.com/aminabedi68/AzarMehrMonospaced)

## Installation

Install hyprland and necessary package from Fedora repo:

```sh
# Enable hyprland copr repo
sudo dnf copr enable solopasha/hyprland

# Install hyprland and necessary packages
sudo dnf install hyprland hyprlock hypridle hyprpaper hyprsunset hyprland-plugins hyprland-qtutils dunst rofi \
rofi-wayland pyprland qgnomeplatform-qt5 qgnomeplatform-qt6 qt5-qtwayland qt6-qtwayland
```

If you want to have per window keyboard layout install [Hyprland per window layout](https://github.com/coffebar/hyprland-per-window-layout) package.

```sh
# Install cargo and rust
sudo dnf install cargo rust rust-src rustfmt

# Install hyprland per window layout
cargo install hyprland-per-window-layout
```

### AGS Shell

I haven't found any good copr for installing AGS shell so you need to manually compile and install astal and aylur shell, but fortunately it's not that hard and there is a good documentation for it:

- First install [Astal](https://aylur.github.io/ags/guide/install.html)
- Then install [Aylur's GTK Shell](https://aylur.github.io/ags/guide/install.html)

You also have to install sass compiler:

```sh
sudo dnf install sass
```

After installation, you need to create a configuration file for loading libraries:

```sh
# Create the configuration file
echo "/usr/local/lib64" | sudo tee /etc/ld.so.conf.d/usr-local.conf

# Update the cache
sudo ldconfig

# Verify the libraries are now in the cache
ldconfig -p | grep astal
```

> Default fish configuration adds two env variables that lets ags find astal libraries, if you're planning for using another terminal shell, you might want to add these two variables to your shell configuration.
>
> ```sh
> set -gx GI_TYPELIB_PATH "/usr/local/lib64/girepository-1.0"
> set -gx LD_LIBRARY_PATH "/usr/local/lib64:$LD_LIBRARY_PATH"
> ```

After installing astal and ags, you need to install these astal libraries as well:

- [Hyprland](https://aylur.github.io/astal/guide/libraries/hyprland)
- [Battery](https://aylur.github.io/astal/guide/libraries/battery)
- [Network](https://aylur.github.io/astal/guide/libraries/network)
- [Wireplumber](https://aylur.github.io/astal/guide/libraries/wireplumber)
- [Mpris](https://aylur.github.io/astal/guide/libraries/mpris)
- [Apps](https://aylur.github.io/astal/guide/libraries/apps)

To add type definitions for Astal and GNOME libraries for better development experience, run this command inside the ags directory:

```sh
npx @ts-for-gir/cli generate 'GLib-2.0' 'Gio-2.0' 'GObject-2.0' 'Gdk-4.0' 'Gtk-4.0' \
  'Astal-4.0' 'AstalApps-0.1' 'AstalBattery-0.1' 'AstalHyprland-0.1' 'AstalIO-0.1' 'AstalMpris-0.1' 'AstalNetwork-0.1' \
  --girDirectories /usr/local/share/gir-1.0 /usr/share/gir-1.0 '/usr/share/*/gir-1.0' \
  --outdir ~/hypaurora/ags/@girs \
  --ignoreVersionConflicts --reporter
```

_This only generate type definitions for **needed** Astal and GNOME libraries, this is not necessary if you're not planning to develop ags or don't need type definitions for better development experience._
