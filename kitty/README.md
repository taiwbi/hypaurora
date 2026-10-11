# Kitty

Kitty counterpart of [`ghostty/config`](../ghostty/config), with Noto Sans Mono
at 13 pt, 10 additional pixels of cell height, a 120 × 27 initial grid,
10 pt horizontal and 5 pt vertical padding, an opaque background, a block
cursor, and the same configured shortcuts.

Requires Kitty 0.38 or newer and the font families **Noto Sans Mono**,
**BetterIcons**, and **Vazir Code Hack**, matching Ghostty. BetterIcons contains
the Nerd Fonts icons; its private-use glyphs are explicitly mapped so an
unpatched text font works. To use standard monochrome Nerd Font icons instead,
replace `BetterIcons` in `kitty.conf` with `Symbols Nerd Font Mono` (installed by
`scripts/fonts.sh`). That changes the icon appearance from Ghostty.

The light theme copies the repository's custom Gruvbox Light Soft palette.
The dark theme copies Ghostty's bundled Gruvbox Dark Hard palette. Kitty loads
the sibling `light-theme.auto.conf` and `dark-theme.auto.conf` files automatically
when the desktop reports its light/dark preference. Dark Hard is the fallback
when no preference is reported; `no-preference-theme.auto.conf` links to that
palette. The desktop must expose color-scheme changes
for automatic switching to work.

Preview from the repository root without installing the configuration:

```bash
KITTY_CONFIG_DIRECTORY="$PWD/kitty" kitty
```

The repository's `scripts/link.sh` also links this directory to `~/.config/kitty`
and backs up an existing target directory. Restart Kitty after linking.

## Persian rendering limits

Arabic/Persian glyphs, presentation forms, and ZWNJ/ZWJ are mapped to Vazir Code
Hack. `force_ltr no` preserves Kitty's RTL shaping, and ligatures remain enabled.
Fonts can only supply the characters they contain; other Arabic extensions
still depend on available fallback fonts.

Kitty does **not** implement the Unicode bidirectional algorithm. Persian
letters can join, but word order in a sentence, mixed Persian/Latin text,
cursor movement, and substring selection cannot be made perfect by configuration.
See [Kitty's `force_ltr` documentation](https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.force_ltr).
No font mapping fixes this limitation.

The terminal colors and explicit numeric settings match Ghostty, but font
rasterization, tab widgets, and desktop window decorations differ between
the applications. Kitty changes font size for the current OS window, including
its tabs, whereas Ghostty changes the focused terminal surface.
Titlebar coloring applies to supported Wayland/macOS
decorations; X11 decorations are controlled by the window manager.
