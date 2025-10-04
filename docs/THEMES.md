# 🎨 Hypaurora Theme Management

A unified theme management system for your Hyprland desktop environment.

## Overview

This system allows you to manage themes across all your applications from a single source of truth. Change your entire desktop theme with one command!

### Supported Applications

- **Ghostty** - Terminal emulator
- **GTK 4.0** - GTK applications (Nautilus, GNOME apps, etc.)
- **Rofi** - Application launcher
- **EWW** - Widget system
- **Hyprland** - Window manager (borders, groups)

## Quick Start

### List Available Themes

```bash
./theme-manager.py list
```

### Preview a Theme

```bash
./theme-manager.py preview bearded_arc
```

### Apply a Theme

```bash
./theme-manager.py apply bearded_monokai_stone
```

### Test Before Applying

```bash
./theme-manager.py apply --dry-run bearded_arc
```

## How It Works

### Single Source of Truth

All themes are defined in `themes/*.json` files with a unified color schema:

```json
{
  "name": "Theme Name",
  "variant": "dark",
  "colors": {
    "base": {
      "background": "#2A2D33",
      "foreground": "#dee0e4",
      "cursor": "#ffd866",
      ...
    },
    "palette": ["#000000", "#fc6a67", ...],
    "semantic": {
      "accent": "#62676c",
      "border": "#78dce8",
      ...
    },
    "ui": {
      "card": "#25282d",
      "popover": "#363941",
      ...
    }
  }
}
```

### Single Theme Files

Instead of maintaining multiple theme files per application, each app has a single `hypaurora` theme file that gets overwritten when you switch themes:

- `ghostty/themes/hypaurora` - Ghostty theme
- `gtk-4.0/themes/hypaurora.css` - GTK theme
- `rofi/themes/hypaurora.rasi` - Rofi theme
- `eww/themes/hypaurora.scss` - EWW theme
- `hypr/hyprland/look.conf` - Hyprland colors

Your application configs reference these files, so switching themes is seamless.

## Reloading Applications

After applying a theme, some applications like ghostty need to be reloaded (using `ctrl`, `shift` `,`) and some like GTK needs to be restarted to see the changes.

## Adding New Themes

Create a new JSON file in `themes/` with the schema, Here is an example:

```json
{
  "name": "My Custom Theme",
  "author": "Your Name",
  "variant": "dark",
  "colors": {
    "base": {
      "background": "#1a1b26",
      "foreground": "#c0caf5",
      "cursor": "#c0caf5",
      "cursor_text": "#1a1b26",
      "selection_bg": "#33467c",
      "selection_fg": "#c0caf5"
    },
    "palette": [
      "#15161e",
      "#f7768e",
      "#9ece6a",
      "#e0af68",
      "#7aa2f7",
      "#bb9af7",
      "#7dcfff",
      "#a9b1d6",
      "#414868",
      "#f7768e",
      "#9ece6a",
      "#e0af68",
      "#7aa2f7",
      "#bb9af7",
      "#7dcfff",
      "#c0caf5"
    ],
    "semantic": {
      "accent": "#7aa2f7",
      "accent_fg": "#1a1b26",
      "border": "#7dcfff",
      "success": "#9ece6a",
      "warning": "#e0af68",
      "error": "#f7768e"
    },
    "ui": {
      "card": "#1f2335",
      "card_fg": "#c0caf5",
      "popover": "#24283b",
      "popover_fg": "#c0caf5",
      "sidebar": "#1f2335",
      "sidebar_fg": "#a9b1d6",
      "headerbar": "#16161e",
      "headerbar_fg": "#787c99"
    }
  }
}
```

## Configuration

The current theme is stored in `theme-config.json`:

```json
{
  "current_theme": "bearded_monokai_stone"
}
```

## File Structure

```
hypaurora/
├── themes/                          # Theme definitions (JSON)
│   ├── my_theme.json
│   ├── bearded_arc.json
│   └── ...
├── theme-manager.py                 # Theme management tool
├── theme-config.json                # Current theme config
├── ghostty/
│   ├── config                       # Sources themes/hypaurora
│   └── themes/hypaurora             # Generated theme file
├── gtk-4.0/
│   ├── gtk.css                      # Imports themes/hypaurora.css
│   └── themes/hypaurora.css         # Generated theme file
├── rofi/
│   ├── config.rasi                  # Sources themes/hypaurora.rasi
│   └── themes/hypaurora.rasi        # Generated theme file
├── eww/
│   ├── eww.scss                     # Imports themes/hypaurora.scss
│   └── themes/hypaurora.scss        # Generated theme file
└── hypr/hyprland/
    └── look.conf                    # Colors updated in-place
```

## Future Enhancements

Planned features:

- Wallpaper-based theme generation (pywal integration)
- Auto update VS Code and Neovim theme with desktop
- VS Code theme import
- GUI theme picker (Rofi/EWW menu)
