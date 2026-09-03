# 🌌 Hypaurora

This is my **dotfiles** repository! 🎉 My personal configuration files for setting up and customizing GNOME and Hyprland.

> ⚠️ **This is the `playground` branch.**
>
> Daily experiments, font changes, icon swaps, theme chaos.

## Hypaurora Hyprland session

This repository contains a CachyOS-only Hyprland setup built around the native
Hyprland Lua configuration format, UWSM, and systemd user services.

The session includes Hyprpaper, Hyprlock, Hyprpicker, Hyprlauncher, Hypridle,
Hyprcursor, Hyprshutdown, Waybar, Kitty, Nautilus, and the official Hyprland
polkit agent. Keyboard layouts are `us,ir`; `Super+Space`
switches them, while `hyprland-per-window-layout` remembers the layout per
window.

The session also enables GCR's systemd SSH agent. It uses one agent for the
whole graphical session and shows a graphical passphrase dialog the first time
an encrypted key is used. The dialog can save the passphrase in the GNOME
login keyring with its automatic-unlock checkbox.

Install and link it on CachyOS with:

```bash
./scripts/installation.sh
```

To only link the repository after making changes:

```bash
./scripts/link.sh
```

Existing targets are moved to
`~/.local/state/hypaurora/backups/<timestamp>/` before they are replaced.

Choose **Hyprland (uwsm-managed)** in the display manager after installation.
Waybar, Hyprlauncher, the Rust layout helper, Hyprpaper, Hypridle,
hyprpolkitagent, GNOME Keyring, and the GCR SSH agent are enabled as systemd
user services. Portal daemons and the Nautilus chooser bridge are started
through systemd/D-Bus activation; they are not launched from the compositor
config.

### Portal routing

The session-specific portal configuration uses the GTK backend for ordinary
interfaces, routes FileChooser through the Nautilus bridge, routes screen
capture, remote desktop, global shortcuts, and input capture through
`xdg-desktop-portal-hyprland`, and keeps GNOME Keyring for secrets. The bridge
answers the portal frontend's startup probe immediately and forwards chooser
requests to Nautilus after the frontend is ready; this avoids the GTK4/Nautilus
startup cycle present in current portal releases while preserving Nautilus as
the visible file chooser.

The wallpaper path is intentionally kept compatible with the old setup:
`~/.config/background`. The installer warns if that file is missing.

Useful diagnostics after logging into Hyprland:

```bash
systemctl --user --failed
systemctl --user status waybar hyprlauncher hypridle hyprpaper hyprpolkitagent
busctl --user tree org.freedesktop.portal.Desktop
```

## 🎭 Customization

- ✨ Desktop Theme: [Catppuccin Mocha](https://github.com/catppuccin/catppuccin)
- 🖱️ Cursor Theme: [Bibata](https://github.com/ful1e5/Bibata_Cursor), converted to Hyprcursor by the installer
- 🅰️ Font Family: [Adwaita Sans](https://gitlab.gnome.org/GNOME/adwaita-fonts)
- ✍️ Persian Font Family: [Vazirmatn](https://rastikerdar.github.io/vazirmatn/en)
- 💻 Monospace Family: [JetBrains Mono](https://www.jetbrains.com/lp/mono/)
- 📜 Persian Monospace Family: [Vazir Code Hack](https://rastikerdar.github.io/vazir-code-font)
