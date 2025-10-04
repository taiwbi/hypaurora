#!/usr/bin/env python3
"""
Hypaurora Theme Manager
Manages themes across Ghostty, GTK, Rofi, EWW, and Hyprland from a central theme registry.
Supports generating themes from wallpaper images.
"""

import json
import sys
import time
import hashlib
from pathlib import Path
from typing import Dict, Any, List, Tuple
from collections import Counter
import argparse

try:
    from PIL import Image
    import numpy as np
    IMAGING_AVAILABLE = True
except ImportError:
    IMAGING_AVAILABLE = False


class ImageThemeGenerator:
    """Generate theme colors from an image."""
    
    @staticmethod
    def hex_to_rgb(hex_color: str) -> Tuple[int, int, int]:
        """Convert hex color to RGB tuple."""
        hex_color = hex_color.lstrip('#')
        return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))
    
    @staticmethod
    def rgb_to_hex(rgb: Tuple[int, int, int]) -> str:
        """Convert RGB tuple to hex color."""
        return f"#{rgb[0]:02x}{rgb[1]:02x}{rgb[2]:02x}"
    
    @staticmethod
    def get_luminance(rgb: Tuple[int, int, int]) -> float:
        """Calculate relative luminance of a color."""
        r, g, b = [x / 255.0 for x in rgb]
        r = r / 12.92 if r <= 0.03928 else ((r + 0.055) / 1.055) ** 2.4
        g = g / 12.92 if g <= 0.03928 else ((g + 0.055) / 1.055) ** 2.4
        b = b / 12.92 if b <= 0.03928 else ((b + 0.055) / 1.055) ** 2.4
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    
    @staticmethod
    def get_contrast_ratio(color1: str, color2: str) -> float:
        """Calculate contrast ratio between two colors."""
        lum1 = ImageThemeGenerator.get_luminance(ImageThemeGenerator.hex_to_rgb(color1))
        lum2 = ImageThemeGenerator.get_luminance(ImageThemeGenerator.hex_to_rgb(color2))
        lighter = max(lum1, lum2)
        darker = min(lum1, lum2)
        return (lighter + 0.05) / (darker + 0.05)
    
    @staticmethod
    def adjust_brightness(rgb: Tuple[int, int, int], factor: float) -> Tuple[int, int, int]:
        """Adjust brightness of RGB color."""
        return tuple(max(0, min(255, int(c * factor))) for c in rgb)
    
    @staticmethod
    def adjust_saturation(rgb: Tuple[int, int, int], factor: float) -> Tuple[int, int, int]:
        """Adjust saturation of RGB color."""
        r, g, b = rgb
        gray = int(0.299 * r + 0.587 * g + 0.114 * b)
        r = int(gray + (r - gray) * factor)
        g = int(gray + (g - gray) * factor)
        b = int(gray + (b - gray) * factor)
        return (max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)))
    
    @staticmethod
    def extract_dominant_colors(image_path: str, n_colors: int = 12) -> List[str]:
        """Extract dominant colors from an image."""
        try:
            from sklearn.cluster import KMeans
            use_kmeans = True
        except ImportError:
            use_kmeans = False
        
        img = Image.open(image_path)
        img = img.convert('RGB')
        img = img.resize((150, 150))
        
        pixels = np.array(img).reshape(-1, 3)
        pixels = pixels[::10]  # Sample every 10th pixel
        
        if use_kmeans:
            kmeans = KMeans(n_clusters=n_colors, random_state=42, n_init=10)
            kmeans.fit(pixels)
            colors = kmeans.cluster_centers_.astype(int)
            colors = [tuple(c) for c in colors]
            labels = kmeans.labels_
            counts = Counter(labels)
            sorted_colors = [colors[i] for i, _ in counts.most_common()]
        else:
            # Fallback: simple quantization
            pixels_list = [tuple(p) for p in pixels]
            quantized = []
            step = 32
            for r, g, b in pixels_list:
                qr = (r // step) * step
                qg = (g // step) * step
                qb = (b // step) * step
                quantized.append((qr, qg, qb))
            
            color_counts = Counter(quantized)
            dominant = [color for color, _ in color_counts.most_common(n_colors * 2)]
            
            sorted_colors = [dominant[0]]
            for color in dominant[1:]:
                if len(sorted_colors) >= n_colors:
                    break
                if all(sum(abs(c1 - c2) for c1, c2 in zip(color, s)) > 60 for s in sorted_colors):
                    sorted_colors.append(color)
        
        return [ImageThemeGenerator.rgb_to_hex(c) for c in sorted_colors]
    
    @staticmethod
    def ensure_contrast(fg_color: str, bg_color: str, min_ratio: float = 4.5) -> str:
        """Ensure foreground color has sufficient contrast with background."""
        ratio = ImageThemeGenerator.get_contrast_ratio(fg_color, bg_color)
        
        if ratio >= min_ratio:
            return fg_color
        
        fg_rgb = ImageThemeGenerator.hex_to_rgb(fg_color)
        bg_lum = ImageThemeGenerator.get_luminance(ImageThemeGenerator.hex_to_rgb(bg_color))
        
        if bg_lum > 0.5:
            factor = 0.7
            while ratio < min_ratio and factor > 0.1:
                adjusted = ImageThemeGenerator.adjust_brightness(fg_rgb, factor)
                fg_color = ImageThemeGenerator.rgb_to_hex(adjusted)
                ratio = ImageThemeGenerator.get_contrast_ratio(fg_color, bg_color)
                factor -= 0.05
        else:
            factor = 1.3
            while ratio < min_ratio and factor < 3.0:
                adjusted = ImageThemeGenerator.adjust_brightness(fg_rgb, factor)
                fg_color = ImageThemeGenerator.rgb_to_hex(adjusted)
                ratio = ImageThemeGenerator.get_contrast_ratio(fg_color, bg_color)
                factor += 0.1
        
        return fg_color
    
    @classmethod
    def generate_theme_from_image(cls, image_path: str, theme_name: str = "wallpaper",
                                 variant: str = "dark") -> Dict[str, Any]:
        """Generate complete theme from image."""
        colors = cls.extract_dominant_colors(image_path, n_colors=12)
        is_dark = variant == "dark"
        
        colors_sorted = sorted(colors, key=lambda c: cls.get_luminance(cls.hex_to_rgb(c)))
        
        if is_dark:
            background = colors_sorted[0]
            foreground = colors_sorted[-1]
            
            bg_rgb = cls.hex_to_rgb(background)
            if cls.get_luminance(bg_rgb) > 0.1:
                background = cls.rgb_to_hex(cls.adjust_brightness(bg_rgb, 0.5))
            
            foreground = cls.ensure_contrast(foreground, background, min_ratio=7.0)
        else:
            background = colors_sorted[-1]
            foreground = colors_sorted[0]
            
            bg_rgb = cls.hex_to_rgb(background)
            if cls.get_luminance(bg_rgb) < 0.9:
                background = cls.rgb_to_hex(cls.adjust_brightness(bg_rgb, 1.3))
            
            foreground = cls.ensure_contrast(foreground, background, min_ratio=7.0)
        
        accent_colors = colors_sorted[3:9] if len(colors_sorted) > 9 else colors_sorted[2:6]
        
        ansi_colors = [background, colors_sorted[1]] + accent_colors[:6]
        ansi_colors = ansi_colors[:8] + [cls.rgb_to_hex(cls.adjust_brightness(cls.hex_to_rgb(c), 1.3))
                                          for c in ansi_colors[:8]]
        
        while len(ansi_colors) < 16:
            ansi_colors.append(foreground)
        ansi_colors = ansi_colors[:16]
        
        accent = accent_colors[0] if accent_colors else colors_sorted[len(colors_sorted)//2]
        cursor = accent_colors[1] if len(accent_colors) > 1 else accent
        cursor = cls.ensure_contrast(cursor, background, min_ratio=3.0)
        
        sel_bg_rgb = cls.hex_to_rgb(accent)
        if is_dark:
            selection_bg = cls.rgb_to_hex(cls.adjust_brightness(sel_bg_rgb, 0.4))
        else:
            selection_bg = cls.rgb_to_hex(cls.adjust_brightness(sel_bg_rgb, 1.6))
        
        bg_rgb = cls.hex_to_rgb(background)
        card = cls.rgb_to_hex(cls.adjust_brightness(bg_rgb, 0.9 if is_dark else 1.02))
        popover = cls.rgb_to_hex(cls.adjust_brightness(bg_rgb, 1.1 if is_dark else 0.98))
        headerbar = cls.rgb_to_hex(cls.adjust_brightness(bg_rgb, 0.7 if is_dark else 1.05))
        
        fg_rgb = cls.hex_to_rgb(foreground)
        sidebar_fg = cls.rgb_to_hex(cls.adjust_brightness(fg_rgb, 0.7))
        headerbar_fg = cls.rgb_to_hex(cls.adjust_brightness(fg_rgb, 0.6))
        
        theme = {
            "name": f"{theme_name.title()} (Auto-generated)",
            "author": "Hypaurora Theme Manager",
            "variant": variant,
            "colors": {
                "base": {
                    "background": background,
                    "foreground": foreground,
                    "cursor": cursor,
                    "cursor_text": background,
                    "selection_bg": selection_bg,
                    "selection_fg": foreground
                },
                "palette": ansi_colors,
                "semantic": {
                    "accent": accent,
                    "accent_fg": cls.ensure_contrast(foreground, accent, min_ratio=4.5),
                    "border": cls.ensure_contrast(accent, background, min_ratio=3.0),
                    "success": ansi_colors[2],
                    "warning": ansi_colors[3],
                    "error": ansi_colors[1]
                },
                "ui": {
                    "card": card,
                    "card_fg": foreground,
                    "popover": popover,
                    "popover_fg": foreground,
                    "sidebar": card,
                    "sidebar_fg": sidebar_fg,
                    "headerbar": headerbar,
                    "headerbar_fg": headerbar_fg
                }
            }
        }
        
        return theme


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
        
        for i, color in enumerate(colors["palette"]):
            lines.append(f"palette = {i}={color}")
        
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
        ]
        
        return "\n".join(lines)
    
    def generate_rofi(self, theme: Dict[str, Any]) -> str:
        """Generate Rofi theme content."""
        colors = theme["colors"]
        base = colors["base"]
        semantic = colors["semantic"]
        palette = colors["palette"]
        
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
        
        if not dunstrc_file.exists():
            print(f"  ⚠ Dunst config not found: {dunstrc_file}")
            return ""
        
        with open(dunstrc_file, 'r') as f:
            content = f.read()
        
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
        fg_color = colors["base"]["foreground"]
        
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

    def generate_wallpaper_theme(self, variant: str = "dark") -> Dict[str, Any]:
        """Generate theme from wallpaper image."""
        if not IMAGING_AVAILABLE:
            print("Error: PIL (Pillow) and numpy are required for wallpaper theme generation")
            print("Install with: pip install Pillow numpy scikit-learn")
            sys.exit(1)
        
        wallpaper_path = Path.home() / ".config/background"
        
        if not wallpaper_path.exists():
            raise FileNotFoundError(f"Wallpaper not found at {wallpaper_path}")
        
        print(f"Generating theme from wallpaper: {wallpaper_path}")
        theme = ImageThemeGenerator.generate_theme_from_image(
            str(wallpaper_path),
            theme_name="wallpaper",
            variant=variant
        )
        
        # Save theme to themes directory
        theme_file = self.themes_dir / "wallpaper.json"
        self.themes_dir.mkdir(parents=True, exist_ok=True)
        
        with open(theme_file, 'w') as f:
            json.dump(theme, f, indent=2)
        
        print(f"  ✓ Saved wallpaper theme to {theme_file}")
        
        return theme

    def apply_theme(self, theme_name: str, dry_run: bool = False, variant: str = "dark"):
        """Apply theme across all applications."""
        # Handle wallpaper theme specially
        if theme_name == "wallpaper":
            theme = self.generate_wallpaper_theme(variant=variant)
        else:
            theme = self.load_theme(theme_name)
        
        print(f"Applying theme: {theme['name']}")
        print("=" * 50)
        
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
                if dry_run:
                    print(f"  [DRY RUN] Would update {app_name}: {file_path}")
                else:
                    print(f"  ✓ Updated {app_name}: {file_path}")
            else:
                if dry_run:
                    print(f"  [DRY RUN] Would write {app_name}: {file_path}")
                else:
                    file_path.parent.mkdir(parents=True, exist_ok=True)
                    with open(file_path, 'w') as f:
                        f.write(content)
                    print(f"  ✓ Generated {app_name}: {file_path}")
        
        if dry_run:
            print(f"  [DRY RUN] Would update Hyprland: hypr/hyprland/look.conf")
        else:
            self.apply_hyprland_theme(theme, dry_run)
            print(f"  ✓ Updated Hyprland: hypr/hyprland/look.conf")
        
        if dry_run:
            print(f"  [DRY RUN] Would update main GTK CSS: gtk-4.0/gtk.css")
        else:
            self.update_gtk_main_css(theme, dry_run=False)
        
        if dry_run:
            print(f"  [DRY RUN] Would update SVG icon colors")
        else:
            self.update_svg_colors(theme, dry_run)
            print(f"  ✓ Updated SVG icon colors in eww/icons/")
        
        if not dry_run:
            config = self.load_config()
            config["current_theme"] = theme_name
            self.save_config(config)
            
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

    def watch_wallpaper(self, variant: str = "dark", check_interval: float = 2.0):
        """Watch wallpaper file for changes and auto-apply theme."""
        if not IMAGING_AVAILABLE:
            print("Error: PIL (Pillow) and numpy are required for wallpaper theme generation")
            print("Install with: pip install Pillow numpy scikit-learn")
            sys.exit(1)
        
        wallpaper_path = Path.home() / ".config/background"
        
        if not wallpaper_path.exists():
            print(f"Waiting for wallpaper at {wallpaper_path}...")
        
        print("👁️  Watching wallpaper for changes...")
        print("Press Ctrl+C to stop")
        print()
        
        last_hash = None
        last_mtime = None
        stable_count = 0
        required_stable_checks = 3  # File must be stable for 3 consecutive checks
        
        def get_file_hash(path: Path) -> str:
            """Get MD5 hash of file."""
            if not path.exists():
                return None
            try:
                with open(path, 'rb') as f:
                    return hashlib.md5(f.read()).hexdigest()
            except (IOError, PermissionError):
                return None
        
        try:
            while True:
                if not wallpaper_path.exists():
                    time.sleep(check_interval)
                    continue
                
                try:
                    current_mtime = wallpaper_path.stat().st_mtime
                    
                    # If mtime changed, reset stability counter
                    if last_mtime is None or current_mtime != last_mtime:
                        last_mtime = current_mtime
                        stable_count = 0
                        time.sleep(check_interval)
                        continue
                    
                    # File hasn't been modified, increment stability counter
                    stable_count += 1
                    
                    # Only check hash once file is stable
                    if stable_count >= required_stable_checks:
                        current_hash = get_file_hash(wallpaper_path)
                        
                        if current_hash and current_hash != last_hash:
                            print(f"🎨 Wallpaper changed detected at {time.strftime('%H:%M:%S')}")
                            print("   Generating and applying new theme...")
                            print()
                            
                            try:
                                self.apply_theme("wallpaper", variant=variant)
                                last_hash = current_hash
                                print()
                                print("✓ Theme applied successfully!")
                                print()
                            except Exception as e:
                                print(f"✗ Error applying theme: {e}")
                                print()
                        
                        # Reset counter after checking
                        stable_count = required_stable_checks
                
                except (IOError, PermissionError) as e:
                    # File might be in the process of being written
                    stable_count = 0
                
                time.sleep(check_interval)
        
        except KeyboardInterrupt:
            print()
            print("Stopped watching wallpaper")


def main():
    parser = argparse.ArgumentParser(
        description="Hypaurora Theme Manager",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s list                                List all themes
  %(prog)s preview bearded_arc                 Preview theme colors
  %(prog)s apply bearded_monokai_stone         Apply theme
  %(prog)s apply wallpaper                     Generate and apply theme from wallpaper
  %(prog)s apply wallpaper --variant light     Generate light theme from wallpaper
  %(prog)s apply wallpaper --listen            Watch wallpaper and auto-apply theme
  %(prog)s apply --dry-run bearded_arc         Test without applying
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
    apply_parser.add_argument('theme', help='Theme name to apply (use "wallpaper" for auto-generation)')
    apply_parser.add_argument('--dry-run', action='store_true', 
                             help='Show what would be done without applying')
    apply_parser.add_argument('--variant', choices=['dark', 'light'], default='dark',
                             help='Theme variant (for wallpaper theme generation)')
    apply_parser.add_argument('--listen', action='store_true',
                             help='Watch wallpaper file for changes (only for wallpaper theme)')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    manager = ThemeManager(base_dir=Path("~/Documents/hypaurora").expanduser())
    
    try:
        if args.command == 'list':
            manager.list_themes()
        elif args.command == 'preview':
            manager.preview_theme(args.theme)
        elif args.command == 'apply':
            if args.listen:
                if args.theme != "wallpaper":
                    print("Error: --listen can only be used with 'wallpaper' theme")
                    sys.exit(1)
                if args.dry_run:
                    print("Error: --listen cannot be used with --dry-run")
                    sys.exit(1)
                manager.watch_wallpaper(variant=args.variant)
            else:
                manager.apply_theme(args.theme, dry_run=args.dry_run, variant=args.variant)
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()