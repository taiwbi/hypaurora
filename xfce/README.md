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
`nm-connection-editor`, `xdotool`, `xorg-xinput`, Zed, elementary icons/cursors,
Python, and Git. NetworkManager is enabled for boot. Theme files are fetched
from pinned upstream commits using Git sparse checkout and installed under
`/usr/share/themes` and `/usr/share/icons`; no AUR helper is required.

`--lightdm` selects LightDM and the XFCE session for the next boot, replacing
any previous display-manager selection. It does not stop the current session.
Without that option, select XFCE in your existing login screen. If you selected
LightDM, reboot when convenient and choose the XFCE session.

Use `--yes` for non-interactive package installation. Use `--config-only` to
reapply settings without package upgrades or theme downloads; it assumes those
dependencies are already installed. All options can be combined, including
`--dry-run --config-only`. `--help` lists the options.

XFCE must be logged out when applying settings. The installer refuses to copy
settings while your `xfce4-session`, `xfce4-panel`, or `xfconfd` is running,
because a live daemon can overwrite the imported XML. A dry run is safe inside
the desktop. Configurations are copied rather than symlinked, so changing
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

English (US) and Persian layouts use Super+Space to switch. Windows open in
the center with the smart placement threshold at 100%. There are ten workspaces
and no desktop icons.

| Shortcut | Action |
| --- | --- |
| Super+A | Application finder |
| Super+Return | XFCE terminal |
| Super+Backslash | Zed (`zeditor`) |
| Super+C | Center the active window |
| Super+S | Close window |
| Super+Up | Maximize window |
| Super+H | Hide window |
| Super+F | Toggle fullscreen |
| Super+D | Show desktop |
| Super+1…5 | Switch to workspaces 1…5 |
| Super+Q/W/E/R/T | Switch to workspaces 6/7/8/9/10 |
| Add Shift to workspace shortcuts | Move window to that workspace |

The top panel is copied from the current setup: application menu without a
title, window buttons without titles or a handle, an expanding transparent
separator, workspace switcher with two rows, Wavelan, power manager without a
label, system tray with 17-pixel icons, time-only clock in Sans 10, and the
actions menu titled “Power”, separated by transparent separators. The existing
bottom launcher panel is also included: desktop, terminal, file manager,
browser, appfinder, and home directory menu.

The installer chooses a local wireless interface, preferring one that is up.
Wavelan hides when offline or hardware is missing, displays its icon without
the signal bar or quality colors, and launches `nm-connection-editor`. If the
wireless hardware changes later, rerun `--config-only` while logged out, or
choose the new interface in Wavelan preferences.

An XFCE-only login helper detects each libinput mouse/touchpad by its local
device name, selects flat acceleration where supported, and sets XFCE's
acceleration slider value to 8 (libinput speed 0.6). It preserves other device
preferences. For a pointer connected after login, run
`~/.local/bin/hypaurora-xfce-pointers` once or log in again. The center helper
uses the full X screen dimensions, matching the original script.

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
managed autostart file under `autostart/`, and any replaced system themes under
`themes/`. With `--lightdm`, it also records the previous display-manager
symlink destination and backs up an existing Hypaurora LightDM drop-in.

To restore settings, log out of XFCE, move the installed
`${XDG_CONFIG_HOME:-$HOME/.config}/xfce4` directory aside, and copy the backup's
`xfce4/` directory into its place. Restore the backed-up helpers/autostart file
if present, or remove the newly installed managed helpers/autostart entry if
they did not exist before. System themes can be restored with sudo from
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
