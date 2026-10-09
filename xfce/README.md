# XFCE on CachyOS

This configuration reproduces the saved XFCE setup using portable snapshots.
It targets XFCE 4.20 on X11 and keeps the GNOME installer separate.

## Install

Run these commands from the repository, as your normal user:

```bash
./scripts/installation-xfce.sh --dry-run
# Log out of XFCE, press Ctrl+Alt+F3, and log into the TTY first.
./scripts/installation-xfce.sh --lightdm
```

The installer performs a full CachyOS package upgrade, installs `xfce4`,
`xfce4-goodies`, LightDM and its GTK greeter, NetworkManager,
`network-manager-applet`, `nm-connection-editor`, `xdotool`, `xorg-xinput`, `xorg-setxkbmap`, Zed,
elementary icons/cursors, Python, and Git. NetworkManager is enabled for boot.
Theme files are fetched
from pinned upstream commits using Git sparse checkout and installed under
`/usr/share/themes` and `/usr/share/icons`; no AUR helper is required.

The `xfce4` package group is expanded explicitly to select only one panel
variant. An installed `xfce4-panel-compiz` or `xfce4-panel` is retained. On a
fresh machine, the installer prefers `xfce4-panel-compiz` when it is available
in the enabled repositories, otherwise it uses `xfce4-panel`. To explicitly
replicate the Compiz panel on a new machine, use:

```bash
XFCE_PANEL_PACKAGE=xfce4-panel-compiz ./scripts/installation-xfce.sh --lightdm
```

The selected panel must be available in an enabled package repository. The
installer does not configure additional repositories.

`--lightdm` selects LightDM and the XFCE session for the next boot, replacing
any previous display-manager selection. It does not stop the current session.
Without that option, select XFCE in your existing login screen. If you selected
LightDM, reboot when convenient and choose the XFCE session.

Use `--yes` for non-interactive package installation. Use `--config-only` to
reapply settings without package upgrades or theme downloads; it assumes those
dependencies are already installed. All options can be combined, including
`--dry-run --config-only`. `--help` lists the options.

XFCE must be logged out when applying settings. The installer refuses to copy
settings while your `xfce4-session` is running. Panel and settings-daemon
processes alone do not block installation at the login screen. A dry run is
safe inside the desktop. Configurations are copied rather than symlinked, so changing
settings in XFCE does not write into the repository. Rerunning the installer
reapplies these snapshots and makes a new backup.

## Appearance

The defaults are `Skeuos-Blue-Dark` for GTK and the panel,
`Skeuos-Blue-Dark-XFWM` for window decorations, `Flat-Remix-Blue-Dark` for
icons, and `elementary` cursors at size 32. To choose light variants:

```bash
XFCE_GTK_THEME=Skeuos-Blue-Light \
XFCE_WM_THEME=Skeuos-Blue-Light-XFWM \
XFCE_ICON_THEME=Flat-Remix-Blue-Light \
  ./scripts/installation-xfce.sh
```

When omitted, `XFCE_WM_THEME` is the GTK theme name plus `-XFWM`. Other
variants must exist in the pinned theme repositories. Upstream sources:
[Skeuos GTK](https://github.com/daniruiz/skeuos-gtk) and
[Flat Remix icons](https://github.com/daniruiz/flat-remix). Their pinned commit
IDs are recorded in the installer. GTK themes apply to XFCE and applications
that honor GTK theme settings; applications with their own styling may differ.

## Included settings

XFCE Terminal uses a Skeuos Blue Dark-inspired ANSI palette with the theme's
dark background (`#23252e`), light foreground (`#eeeeec`), and blue cursor and
selection (`#2777ff`). Other terminal preferences, including fonts, are retained.
The palette remains dark when choosing another GTK theme.

Caps Lock acts as an additional Escape key. Shift+Space inserts a Persian
zero-width non-joiner (ZWNJ) through the Persian layout's built-in mapping.
Super+Space switches between English (US) and Persian through an XFCE keyboard
shortcut, while Alt+Shift also switches layouts through XKB. The Super+Space
helper changes the active XKB group directly, keeping Shift+Space available
for ZWNJ. An XFCE-only autostart entry reapplies the layout and keyboard options
at each login.
Windows open in the center with the smart placement threshold at 100%. There
are ten workspaces and no desktop icons.

| Shortcut                         | Action                          |
| -------------------------------- | ------------------------------- |
| Super+A                          | Application finder              |
| Super+Return                     | XFCE terminal                   |
| Super+Escape                     | Lock the session (`xflock4`)     |
| Super+Backslash                  | Zed (`zeditor`)                 |
| Super+C                          | Center the active window        |
| Super+X                          | Show the rescue wallpaper      |
| Super+Alt+X                      | Restore the previous wallpaper |
| Super+S                          | Close window                    |
| Super+Up                         | Maximize window                 |
| Super+H                          | Hide window                     |
| Super+F                          | Toggle fullscreen               |
| Super+D                          | Show desktop                    |
| Super+1…5                        | Switch to workspaces 1…5        |
| Super+Q/W/E/R/T                  | Switch to workspaces 6/7/8/9/10 |
| Add Shift to workspace shortcuts | Move window to that workspace   |

The top panel is copied from the current setup: application menu without a
title, window buttons without titles or a handle, an expanding transparent
separator, workspace switcher with two rows, power manager without a label,
system tray with 17-pixel icons, time-only clock in Sans 10, and the
actions menu titled “Power”, separated by transparent separators. The existing
bottom launcher panel is also included: desktop, terminal, file manager,
browser, appfinder, and home directory menu.

The NetworkManager applet starts automatically at XFCE login and places its
network status icon in the system tray. Use the icon to view and manage
available network connections.

An XFCE-only login helper detects each libinput mouse/touchpad by its local
device name, selects flat acceleration where supported, and sets XFCE's
acceleration slider value to 8 (libinput speed 0.6). It preserves other device
preferences. For a pointer connected after login, run
`~/.local/bin/hypaurora-xfce-pointers` once or log in again. The center helper
uses the full X screen dimensions, matching the original script.

The wallpaper shortcuts save the current XFCE backdrop properties on first use,
apply `/home/mahdi/Pictures/rescue.jpg` across displays and workspaces, and
restore the saved settings with Super+Alt+X. The state file lives under
`${XDG_STATE_HOME:-$HOME/.local/state}/hypaurora/`.
An XFCE autostart listener also applies the rescue image while the screen is
locked and restores the backdrop that was active immediately before locking.

Monitor layouts, device names, external wallpaper paths, tray history, and
session caches are excluded from the snapshots. Existing wallpaper, GTK font,
and power-policy settings are retained when applying the relevant theme,
desktop-icon, and panel-label properties. Home-directory and helper-command
paths are expanded during installation. `XDG_CONFIG_HOME` and `XDG_STATE_HOME`
are respected.

## Backups and verification

Each run prints its backup directory, normally
`~/.local/state/hypaurora/backups/xfce-TIMESTAMP-SUFFIX`. It contains the prior
`xfce4/` configuration, previous managed helpers under `bin/`, the previous
managed autostart files under `autostart/`, and any replaced system themes under
`themes/`. With `--lightdm`, it also records the previous display-manager
symlink destination and backs up an existing Hypaurora LightDM drop-in.

To restore settings, log out of XFCE, move the installed
`${XDG_CONFIG_HOME:-$HOME/.config}/xfce4` directory aside, and copy the backup's
`xfce4/` directory into its place. Restore the backed-up helpers/autostart file
if present, or remove the newly installed managed helpers/autostart entry if
they did not exist before. The managed keyboard entry is
`autostart/hypaurora-xfce-keyboard.desktop`; remove it to stop remapping Caps Lock
at future logins. System themes can be restored with sudo from
`themes/`. To restore a previous display manager, enable its service with
`sudo systemctl enable --force SERVICE` using the recorded destination; restore
the saved LightDM drop-in or remove `50-hypaurora.conf` if it was newly created.
On a fresh profile without an `xfce4/` backup, moving the installed directory
aside lets XFCE create its defaults at the next login.

After logging into XFCE, check the panel, layout toggle, shortcuts, workspace
count, pointer settings, and themes. Inspect services with
`systemctl --user --failed` and, if selected, `systemctl status lightdm`.
Use `xfconf-query -c xfwm4 -p /general/workspace_count` to verify the workspace
count and `xfconf-query -c xsettings -p /Net/ThemeName` to verify the GTK theme.
