#!/usr/bin/env python3
"""
Hypaurora Theme Manager
Manages themes across Ghostty, GTK, Rofi, EWW, and Hyprland from a central theme registry.
"""

import json
import sys
from pathlib import Path
from typing import Dict, Any
import argparse


class ThemeManager:
    def __init__(self, base_dir: Path = None):
        self.base_dir = base_dir or Path(__file__).parent
        self.themes_dir = self.base_dir / "themes"
        self.config_file = self.base_dir / "theme-config.json"
        
    def load_theme(self, theme_name: str) -> Dict[str, Any]:
        """Load theme JSON file."""
        theme_file = self.themes_dir / f"{theme_name}.json"
        if not theme_file.exists():
            raise FileNotFoundError(f"Theme '{theme_name}' not found at {theme_file}")
        
        with open(theme_file, 'r') as f:
            return json.load(f)
    
    def load_config(self) -> Dict[str, Any]:
        """Load theme configuration."""
        if self.config_file.exists():
            with open(self.config_file, 'r') as f:
                return json.load(f)
        return {"current_theme": "bearded_monokai_stone"}
    
    def save_config(self, config: Dict[str, Any]):
        """Save theme configuration."""
        with open(self.config_file, 'w') as f:
            json.dump(config, f, indent=2)
    
    def list_themes(self):
        """List all available themes."""
        themes = sorted([f.stem for f in self.themes_dir.glob("*.json")])
        config = self.load_config()
        current = config.get("current_theme", "")
        
        print("Available themes:")
        print()
        for theme in themes:
            marker = "→" if theme == current else " "
            print(f"  {marker} {theme}")
        print()
        print(f"Total: {len(themes)} themes")
    
    def preview_theme(self, theme_name: str):
        """Preview theme colors."""
        theme = self.load_theme(theme_name)
        colors = theme["colors"]
        
        print(f"\n{theme['name']} ({theme['variant']})")
        print("=" * 50)
        
        print("\n📦 Base Colors:")
        for key, value in colors["base"].items():
            print(f"  {key:20s} {value}")
        
        print("\n🎨 Palette:")
        for i, color in enumerate(colors["palette"]):
            print(f"  color{i:2d}              {color}")
        
        print("\n✨ Semantic Colors:")
        for key, value in colors["semantic"].items():
            print(f"  {key:20s} {value}")
        
        print("\n🖼️  UI Colors:")
        for key, value in colors["ui"].items():
            print(f"  {key:20s} {value}")
        print()
    
    def generate_ghostty(self, theme: Dict[str, Any]) -> str:
        """Generate Ghostty theme file content."""
        colors = theme["colors"]
        lines = []
        
        # Palette colors
        for i, color in enumerate(colors["palette"]):
            lines.append(f"palette = {i}={color}")
        
        # Base colors
        lines.append(f"background = {colors['base']['background']}")
        lines.append(f"foreground = {colors['base']['foreground']}")
        lines.append(f"cursor-color = {colors['base']['cursor']}")
        lines.append(f"cursor-text = {colors['base']['cursor_text']}")
        lines.append(f"selection-background = {colors['base']['selection_bg']}")
        lines.append(f"selection-foreground = {colors['base']['selection_fg']}")
        
        return "\n".join(lines)
    
    def generate_gtk(self, theme: Dict[str, Any]) -> str:
        """Generate GTK theme CSS content."""
        colors = theme["colors"]
        base = colors["base"]
        semantic = colors["semantic"]
        ui = colors["ui"]
        
        lines = [
            f"@define-color accent_bg_color {semantic['accent']};",
            f"@define-color accent_fg_color {semantic['accent_fg']};",
            f"@define-color accent_color {semantic['accent']};",
            f"@define-color destructive_bg_color {semantic['error']};",
            f"@define-color destructive_fg_color {base['background']};",
            f"@define-color destructive_color {semantic['error']};",
            f"@define-color success_bg_color {semantic['success']};",
            f"@define-color success_fg_color {base['foreground']};",
            f"@define-color success_color {semantic['success']};",
            f"@define-color warning_bg_color {semantic['warning']};",
            f"@define-color warning_fg_color {base['foreground']};",
            f"@define-color warning_color {semantic['warning']};",
            f"@define-color error_bg_color {semantic['error']};",
            f"@define-color error_fg_color {base['foreground']};",
            f"@define-color error_color {semantic['error']};",
            f"@define-color window_bg_color {base['background']};",
            f"@define-color window_fg_color {base['foreground']};",
            f"@define-color view_bg_color {base['background']};",
            f"@define-color view_fg_color {base['foreground']};",
            f"@define-color headerbar_bg_color {ui['headerbar']};",
            f"@define-color headerbar_fg_color {ui['headerbar_fg']};",
            f"@define-color headerbar_backdrop_color {ui['headerbar']};",
            f"@define-color headerbar_shade_color {ui['headerbar']};",
            f"@define-color card_bg_color {ui['card']};",
            f"@define-color card_fg_color {ui['card_fg']};",
            f"@define-color card_shade_color {ui['card']};",
            f"@define-color popover_bg_color {ui['popover']};",
            f"@define-color popover_fg_color {ui['popover_fg']};",
            f"@define-color sidebar_backdrop_color {ui['sidebar']};",
            f"@define-color sidebar_bg_color {ui['sidebar']};",
            f"@define-color sidebar_fg_color {ui['sidebar_fg']};",
            "",
            "/* Target the specific row in the sidebar that's selected */",
            ".navigation-sidebar row:selected {",
            f"    background-color: {semantic['accent']};",
            f"    color: {semantic['accent_fg']};",
            "}",
            "",
            "/* Target the label in the selected row */",
            ".navigation-sidebar row:selected .sidebar-label {",
            f"    color: {semantic['accent_fg']};",
            "}",
            "",
            "/* Hover effect for non-selected rows */",
            ".navigation-sidebar row:hover:not(:selected) {",
            f"    background-color: {semantic['accent']}33;",
            "}",
        ]
        
        return "\n".join(lines)
    
    def generate_rofi(self, theme: Dict[str, Any]) -> str:
        """Generate Rofi theme content."""
        colors = theme["colors"]
        base = colors["base"]
        semantic = colors["semantic"]
        palette = colors["palette"]
        
        # Generate background shades
        bg = base["background"]
        
        lines = [
            "configuration {",
            '    show-icons: true;',
            '    icon-theme: "Reversal-orange-dark";',
            "}",
            "",
            "* {",
            f"    bg0:    {bg}D4;",
            f"    bg1:    {palette[8]}D4;",
            f"    bg2:    {palette[0]}D4;",
            f"    bg3:    {palette[8]}D4;",
            f"    fg0:    {base['foreground']};",
            f"    fg1:    {base['foreground']}E6;",
            f"    fg2:    {base['foreground']}CC;",
            f"    fg3:    {base['foreground']}B3;",
            f"    border: {palette[13]};",
            f"    accent: {semantic['accent']};",
            "",
            '    font:   "Geist Medium 11";',
            "",
            "    background-color:   transparent;",
            "    text-color:         @fg0;",
            "",
            "    margin:     0px;",
            "    padding:    0px;",
            "    spacing:    0px;",
            "}",
            "",
            "window {",
            "    location:       north;",
            "    y-offset:       calc(50% - 176px);",
            "    width:          480;",
            "    height:         416;",
            "",
            "    border-radius:  8px;",
            "    border-color: @accent;",
            "    border: 2px;",
            "",
            "    background-color:   @bg0;",
            "}",
            "",
            "mainbox {",
            "    padding:    12px;",
            "}",
            "",
            "inputbar {",
            "    background-color:   @bg1;",
            "    border-color:       @border;",
            "",
            "    border:         2px;",
            "    border-radius:  6px;",
            "",
            "    padding:    8px 16px;",
            "    spacing:    8px;",
            "    children:   [ prompt, entry ];",
            "}",
            "",
            "prompt {",
            "    text-color: @accent;",
            "}",
            "",
            "entry {",
            '    placeholder:        "Search";',
            "    placeholder-color:  @fg3;",
            "}",
            "",
            "message {",
            "    margin:             12px 0 0;",
            "    border-radius:      16px;",
            "    border-color:       @bg2;",
            "    background-color:   @bg2;",
            "}",
            "",
            "textbox {",
            "    padding:    8px 24px;",
            "}",
            "",
            "listview {",
            "    background-color:   transparent;",
            "",
            "    margin:     12px 0 0;",
            "    lines:      8;",
            "    columns:    1;",
            "",
            "    fixed-height: false;",
            "}",
            "",
            "element {",
            "    padding:        8px 16px;",
            "    spacing:        8px;",
            "    border-radius:  6px;",
            "}",
            "",
            "element normal active {",
            "    text-color: @bg3;",
            "}",
            "",
            "element alternate active {",
            "    text-color: @bg3;",
            "}",
            "",
            "element selected normal, element selected active {",
            "    background-color:       @bg2;",
            "}",
            "",
            "element-icon {",
            "    size:           2em;",
            "    vertical-align: 0.5;",
            "}",
            "",
            "element-text {",
            "    text-color: inherit;",
            "    margin: 9px 0 0;",
            "}",
        ]
        
        return "\n".join(lines)
    
    def generate_eww(self, theme: Dict[str, Any]) -> str:
        """Generate EWW theme SCSS content."""
        colors = theme["colors"]
        palette = colors["palette"]
        semantic = colors["semantic"]
        ui = colors["ui"]
        base = colors["base"]
        
        lines = [
            "// Background colors",
            f"$bg-base: {base['background']};          // Base background from theme",
            f"$bg-popover: {ui['popover']};       // Popover background from theme",
            f"$bg-active: {palette[10]};        // Active/highlighted background",
            f"$bg-hover: {palette[8]};         // Hover state background",
            "",
            "// Foreground/text colors",
            f"$fg-base: {base['foreground']};          // Base foreground text",
            f"$fg-popover: {ui['popover_fg']};       // Popover text from theme",
            f"$fg-sidebar: {ui['sidebar_fg']};       // Sidebar text from theme",
            f"$fg-active: {base['background']};        // Text on active background",
            "",
            "// Border colors",
            f"$border-base: {semantic['border']};      // Main border color",
            f"$border-popup: {palette[6]};     // Popup window borders",
            f"$border-osd: {palette[5]};       // On-screen display borders",
            "",
            "// Accent and functional colors",
            f"$accent-color: {semantic['accent']};     // General accent color",
            f"$accent-logo: {palette[6]};      // Logo/brand color",
            f"$accent-slider: {semantic['warning']};    // Slider/progress color",
        ]
        
        return "\n".join(lines)
    
    def generate_hyprland(self, theme: Dict[str, Any]) -> str:
        """Generate Hyprland theme colors to inject into look.conf."""
        colors = theme["colors"]
        palette = colors["palette"]
        
        # Return the color values that will be injected
        return {
            "active_border": f"rgb({palette[4][1:]}) rgb({palette[2][1:]}) 25deg",
            "inactive_border": f"rgb({palette[8][1:]}) rgb({palette[0][1:]}) 25deg",
            "group_active": f"rgb({palette[1][1:]}) rgb({palette[5][1:]}) 25deg",
            "group_inactive": f"rgb({palette[3][1:]}) rgb({palette[8][1:]}) 25deg",
            "groupbar_active": f"rgb({palette[1][1:]})",
            "groupbar_inactive": f"rgba({palette[0][1:]}80)",
        }
    
    def update_dunst_config(self, theme: Dict[str, Any], dry_run: bool = False) -> str:
        """Update the existing dunstrc file with theme colors."""
        import re
        
        dunstrc_file = self.base_dir / "dunst/dunstrc"
        colors = theme["colors"]
        base = colors["base"]
        semantic = colors["semantic"]
        palette = colors["palette"]
        ui = colors["ui"]
        
        if not dunstrc_file.exists():
            print(f"  ⚠ Dunst config not found: {dunstrc_file}")
            return ""
        
        with open(dunstrc_file, 'r') as f:
            content = f.read()
        
        # Replace color values in the configuration
        # Global section colors
        content = re.sub(
            r'(frame_color\s*=\s*)"[^"]+"',
            f'\\1"{semantic["border"]}"',
            content
        )
        content = re.sub(
            r'(highlight\s*=\s*)"[^"]+"',
            f'\\1"{semantic["warning"]}"',
            content
        )
        
        # Urgency low colors
        content = re.sub(
            r'(\[urgency_low\]\s*\n\s*background\s*=\s*)"[^"]+"',
            f'\\1"{base["background"]}80"',
            content
        )
        content = re.sub(
            r'(\[urgency_low\]\s*\n\s*foreground\s*=\s*)"[^"]+"',
            f'\\1"{base["foreground"]}"',
            content
        )
        content = re.sub(
            r'(\[urgency_low\]\s*\n\s*frame_color\s*=\s*)"[^"]+"',
            f'\\1"{semantic["success"]}"',
            content
        )
        
        # Urgency normal colors
        content = re.sub(
            r'(\[urgency_normal\]\s*\n\s*background\s*=\s*)"[^"]+"',
            f'\\1"{base["background"]}80"',
            content
        )
        content = re.sub(
            r'(\[urgency_normal\]\s*\n\s*foreground\s*=\s*)"[^"]+"',
            f'\\1"{base["foreground"]}"',
            content
        )
        content = re.sub(
            r'(\[urgency_normal\]\s*\n\s*frame_color\s*=\s*)"[^"]+"',
            f'\\1"{semantic["warning"]}"',
            content
        )
        
        # Urgency critical colors
        content = re.sub(
            r'(\[urgency_critical\]\s*\n\s*background\s*=\s*)"[^"]+"',
            f'\\1"{base["background"]}80"',
            content
        )
        content = re.sub(
            r'(\[urgency_critical\]\s*\n\s*foreground\s*=\s*)"[^"]+"',
            f'\\1"{base["foreground"]}"',
            content
        )
        content = re.sub(
            r'(\[urgency_critical\]\s*\n\s*frame_color\s*=\s*)"[^"]+"',
            f'\\1"{semantic["error"]}"',
            content
        )
        
        if not dry_run:
            with open(dunstrc_file, 'w') as f:
                f.write(content)
        
        return content
    
    def update_svg_colors(self, theme: Dict[str, Any], dry_run: bool = False):
        """Update fill colors in SVG icon files."""
        colors = theme["colors"]
        fg_color = colors["base"]["foreground"]  # Use base foreground as default icon color
        
        # Find all SVG files in the eww icons directory
        icons_dir = self.base_dir / "eww/icons"
        if not icons_dir.exists():
            print(f"  ⚠ Icons directory not found: {icons_dir}")
            return
        
        svg_files = list(icons_dir.glob("*.svg"))
        
        for svg_file in svg_files:
            with open(svg_file, 'r') as f:
                content = f.read()
            
            import re
            updated_content = re.sub(
                r'fill="#[A-Fa-f0-9]{3,6}"',
                f'fill="{fg_color}"',
                content
            )
            
            if updated_content != content:
                if not dry_run:
                    with open(svg_file, 'w') as f:
                        f.write(updated_content)
    
    def apply_hyprland_theme(self, theme: Dict[str, Any], dry_run: bool = False):
        """Update Hyprland colors directly in look.conf."""
        import re
        
        look_conf = self.base_dir / "hypr/hyprland/look.conf"
        colors = self.generate_hyprland(theme)
        
        if not look_conf.exists():
            print(f"  ⚠ Hyprland config not found: {look_conf}")
            return
        
        with open(look_conf, 'r') as f:
            content = f.read()
        
        # Replace color values in general block
        content = re.sub(
            r'col\.active_border\s*=\s*[^\n]+',
            f'col.active_border = {colors["active_border"]}',
            content
        )
        content = re.sub(
            r'col\.inactive_border\s*=\s*[^\n]+',
            f'col.inactive_border = {colors["inactive_border"]}',
            content
        )
        
        # Replace color values in group block
        content = re.sub(
            r'col\.border_active\s*=\s*[^\n]+',
            f'col.border_active = {colors["group_active"]}',
            content
        )
        content = re.sub(
            r'col\.border_inactive\s*=\s*[^\n]+',
            f'col.border_inactive = {colors["group_inactive"]}',
            content
        )
        
        # Replace groupbar colors
        content = re.sub(
            r'(groupbar\s*\{[^}]*col\.active\s*=\s*)[^\n]+',
            f'\\1{colors["groupbar_active"]}',
            content,
            flags=re.DOTALL
        )
        content = re.sub(
            r'(groupbar\s*\{[^}]*col\.inactive\s*=\s*)[^\n]+',
            f'\\1{colors["groupbar_inactive"]}',
            content,
            flags=re.DOTALL
        )
        
        if not dry_run:
            with open(look_conf, 'w') as f:
                f.write(content)
    
    def update_gtk_main_css(self, theme: Dict[str, Any], dry_run: bool = False):
        """Update the main gtk.css file to use the theme's popover color with alpha."""
        import re
        
        gtk_css_file = self.base_dir / "gtk-4.0/gtk.css"
        colors = theme["colors"]
        popover_color = colors["ui"]["popover"]
        
        if not gtk_css_file.exists():
            print(f"  ⚠ Main GTK CSS file not found: {gtk_css_file}")
            return
        
        with open(gtk_css_file, 'r') as f:
            content = f.read()
        
        # Replace the popover_bg_color line with the new color and alpha
        new_line = f'@define-color popover_bg_color alpha({popover_color}, 0.6);'
        updated_content = re.sub(
            r'@define-color popover_bg_color alpha\([^)]+\);',
            new_line,
            content
        )
        
        if updated_content != content:
            if not dry_run:
                with open(gtk_css_file, 'w') as f:
                    f.write(updated_content)
            print(f"  ✓ Updated main GTK CSS: {gtk_css_file}")
        else:
            print(f"  ! No changes needed in main GTK CSS: {gtk_css_file}")

    def apply_theme(self, theme_name: str, dry_run: bool = False):
        """Apply theme across all applications."""
        theme = self.load_theme(theme_name)
        
        print(f"Applying theme: {theme['name']}")
        print("=" * 50)
        
        # Generate all theme files
        generators = {
            "Ghostty": (
                self.base_dir / "ghostty/themes/hypaurora",
                self.generate_ghostty(theme)
            ),
            "GTK": (
                self.base_dir / "gtk-4.0/themes/hypaurora.css",
                self.generate_gtk(theme)
            ),
            "Rofi": (
                self.base_dir / "rofi/themes/hypaurora.rasi",
                self.generate_rofi(theme)
            ),
            "EWW": (
                self.base_dir / "eww/themes/hypaurora.scss",
                self.generate_eww(theme)
            ),
            "Dunst": (
                self.base_dir / "dunst/dunstrc",
                self.update_dunst_config(theme)
            ),
        }
        
        for app_name, (file_path, content) in generators.items():
            if app_name == "Dunst":
                # Special handling for Dunst since it modifies existing file
                if dry_run:
                    print(f"  [DRY RUN] Would update {app_name}: {file_path}")
                else:
                    # update_dunst_config already writes the file when not dry_run
                    print(f"  ✓ Updated {app_name}: {file_path}")
            else:
                if dry_run:
                    print(f"  [DRY RUN] Would write {app_name}: {file_path}")
                else:
                    file_path.parent.mkdir(parents=True, exist_ok=True)
                    with open(file_path, 'w') as f:
                        f.write(content)
                    print(f"  ✓ Generated {app_name}: {file_path}")
        
        # Handle Hyprland separately (updates look.conf directly)
        if dry_run:
            print(f"  [DRY RUN] Would update Hyprland: hypr/hyprland/look.conf")
        else:
            self.apply_hyprland_theme(theme, dry_run)
            print(f"  ✓ Updated Hyprland: hypr/hyprland/look.conf")
        
        # Update main GTK CSS file to use theme's popover color with alpha
        if dry_run:
            print(f"  [DRY RUN] Would update main GTK CSS: gtk-4.0/gtk.css")
        else:
            self.update_gtk_main_css(theme, dry_run=False)
        
        # Update SVG icon colors
        if dry_run:
            print(f"  [DRY RUN] Would update SVG icon colors")
        else:
            self.update_svg_colors(theme, dry_run)
            print(f"  ✓ Updated SVG icon colors in eww/icons/")
        
        if not dry_run:
            # Save current theme to config
            config = self.load_config()
            config["current_theme"] = theme_name
            self.save_config(config)
            
            # Kill dunst to apply the new theme
            import subprocess
            try:
                subprocess.run(["pkill", "dunst"], check=False)
                print("  ✓ Killed dunst to apply new theme")
            except Exception as e:
                print(f"  ⚠ Could not kill dunst: {e}")
        
            print()
            print(f"✓ Theme '{theme_name}' applied successfully!")
            print()
            print("To reload applications:")
            print("  • Ghostty: Restart terminal")
            print("  • GTK: Applications will reload automatically")
            print("  • Rofi: Next launch will use new theme")
            print("  • EWW: Run 'eww reload'")
            print("  • Hyprland: Run 'hyprctl reload'")
            print("  • Dunst: Automatically restarted with new theme")
        else:
            print()
            print("Dry run complete. No files were modified.")


def main():
    parser = argparse.ArgumentParser(
        description="Hypaurora Theme Manager",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s list                          List all themes
  %(prog)s preview bearded_arc           Preview theme colors
  %(prog)s apply bearded_monokai_stone   Apply theme
  %(prog)s apply --dry-run bearded_arc   Test without applying
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Commands')
    
    # List command
    subparsers.add_parser('list', help='List all available themes')
    
    # Preview command
    preview_parser = subparsers.add_parser('preview', help='Preview theme colors')
    preview_parser.add_argument('theme', help='Theme name to preview')
    
    # Apply command
    apply_parser = subparsers.add_parser('apply', help='Apply theme')
    apply_parser.add_argument('theme', help='Theme name to apply')
    apply_parser.add_argument('--dry-run', action='store_true', 
                             help='Show what would be done without applying')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    manager = ThemeManager()
    
    try:
        if args.command == 'list':
            manager.list_themes()
        elif args.command == 'preview':
            manager.preview_theme(args.theme)
        elif args.command == 'apply':
            manager.apply_theme(args.theme, dry_run=args.dry_run)
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
