#!/usr/bin/env python3
"""
Hypaurora Theme Manager
Manages themes across Ghostty, GTK, Rofi, EWW, Hyprland, and GNOME Shell from a central theme registry.
Supports generating themes from wallpaper images.
"""

import json
import sys
import time
import hashlib
import subprocess
import shutil
import re
from pathlib import Path
from typing import Dict, Any, List, Tuple, Optional
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
        
        img = Image.open(image_path).convert('RGB').resize((150, 150))
        pixels = np.array(img).reshape(-1, 3)[::10]  # Sample every 10th pixel
        
        if use_kmeans:
            kmeans = KMeans(n_clusters=n_colors, random_state=42, n_init=10)
            kmeans.fit(pixels)
            colors = [tuple(c) for c in kmeans.cluster_centers_.astype(int)]
            labels = kmeans.labels_
            counts = Counter(labels)
            sorted_colors = [colors[i] for i, _ in counts.most_common()]
        else:
            # Fallback: simple quantization
            step = 32
            quantized = [((r // step) * step, (g // step) * step, (b // step) * step) 
                        for r, g, b in pixels]
            
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
            step = -0.05
            min_factor = 0.1
        else:
            factor = 1.3
            step = 0.1
            min_factor = 3.0
        
        while ratio < min_ratio and (step < 0 and factor > min_factor or step > 0 and factor < min_factor):
            adjusted = ImageThemeGenerator.adjust_brightness(fg_rgb, factor)
            fg_color = ImageThemeGenerator.rgb_to_hex(adjusted)
            ratio = ImageThemeGenerator.get_contrast_ratio(fg_color, bg_color)
            factor += step
        
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
        ansi_colors = (ansi_colors + [foreground] * 16)[:16]
        
        accent = accent_colors[0] if accent_colors else colors_sorted[len(colors_sorted)//2]
        cursor = accent_colors[1] if len(accent_colors) > 1 else accent
        cursor = cls.ensure_contrast(cursor, background, min_ratio=3.0)
        
        sel_bg_rgb = cls.hex_to_rgb(accent)
        selection_bg = cls.rgb_to_hex(cls.adjust_brightness(sel_bg_rgb, 0.4 if is_dark else 1.6))
        
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
        
        print("Available themes:\n")
        for theme in themes:
            marker = "→" if theme == current else " "
            print(f"  {marker} {theme}")
        print(f"\nTotal: {len(themes)} themes")
    
    def preview_theme(self, theme_name: str):
        """Preview theme colors."""
        theme = self.load_theme(theme_name)
        colors = theme["colors"]
        
        print(f"\n{theme['name']} ({theme['variant']})")
        print("=" * 50)
        
        sections = [
            ("📦 Base Colors:", colors["base"]),
            ("✨ Semantic Colors:", colors["semantic"]),
            ("🖼️  UI Colors:", colors["ui"])
        ]
        
        for title, section in sections:
            print(f"\n{title}")
            for key, value in section.items():
                print(f"  {key:20s} {value}")
        
        print("\n🎨 Palette:")
        for i, color in enumerate(colors["palette"]):
            print(f"  color{i:2d}              {color}")
        print()
    
    def update_ghostty(self, theme: Dict[str, Any]) -> bool:
        """Updates Ghostty theme file."""
        colors = theme["colors"]
        lines = [f"palette = {i}={color}" for i, color in enumerate(colors["palette"])]
        
        base_mappings = {
            "background": "background",
            "foreground": "foreground",
            "cursor": "cursor-color",
            "cursor_text": "cursor-text",
            "selection_bg": "selection-background",
            "selection_fg": "selection-foreground"
        }
        
        for key, ghostty_key in base_mappings.items():
            lines.append(f"{ghostty_key} = {colors['base'][key]}")
        
        with open(self.base_dir / "ghostty/themes/hypaurora", 'w') as f:
            f.write("\n".join(lines))
        
        return True
    
    def update_gtk(self, theme: Dict[str, Any]) -> bool:
        """Updates GTK theme CSS content."""
        colors = theme["colors"]
        base = colors["base"]
        semantic = colors["semantic"]
        ui = colors["ui"]
        
        replacements = [
            (r'(@define-color destructive_bg_color\s+)[^;]+;', 
            rf'\1{semantic["error"]};'),
            (r'(@define-color destructive_fg_color\s+)[^;]+;', 
            rf'\1{base["background"]};'),
            (r'(@define-color destructive_color\s+)[^;]+;', 
            rf'\1{semantic["error"]};'),
            (r'(@define-color success_bg_color\s+)[^;]+;', 
            rf'\1{semantic["success"]};'),
            (r'(@define-color success_fg_color\s+)[^;]+;', 
            rf'\1{base["foreground"]};'),
            (r'(@define-color success_color\s+)[^;]+;', 
            rf'\1{semantic["success"]};'),
            (r'(@define-color warning_bg_color\s+)[^;]+;', 
            rf'\1{semantic["warning"]};'),
            (r'(@define-color warning_fg_color\s+)[^;]+;', 
            rf'\1{base["foreground"]};'),
            (r'(@define-color warning_color\s+)[^;]+;', 
            rf'\1{semantic["warning"]};'),
            (r'(@define-color error_bg_color\s+)[^;]+;', 
            rf'\1{semantic["error"]};'),
            (r'(@define-color error_fg_color\s+)[^;]+;', 
            rf'\1{base["foreground"]};'),
            (r'(@define-color error_color\s+)[^;]+;', 
            rf'\1{semantic["error"]};'),
            (r'(@define-color window_bg_color\s+)[^;]+;', 
            rf'\1{base["background"]};'),
            (r'(@define-color window_fg_color\s+)[^;]+;', 
            rf'\1{base["foreground"]};'),
            (r'(@define-color view_bg_color\s+)[^;]+;', 
            rf'\1{base["background"]};'),
            (r'(@define-color view_fg_color\s+)[^;]+;', 
            rf'\1{base["foreground"]};'),
            (r'(@define-color headerbar_bg_color\s+)[^;]+;', 
            rf'\1{ui["headerbar"]};'),
            (r'(@define-color headerbar_fg_color\s+)[^;]+;', 
            rf'\1{ui["headerbar_fg"]};'),
            (r'(@define-color headerbar_backdrop_color\s+)[^;]+;', 
            rf'\1{ui["headerbar"]};'),
            (r'(@define-color headerbar_shade_color\s+)[^;]+;', 
            rf'\1{ui["headerbar"]};'),
            (r'(@define-color card_bg_color\s+)[^;]+;', 
            rf'\1{ui["card"]};'),
            (r'(@define-color card_fg_color\s+)[^;]+;', 
            rf'\1{ui["card_fg"]};'),
            (r'(@define-color card_shade_color\s+)[^;]+;', 
            rf'\1{ui["card"]};'),
            (r'(@define-color popover_bg_color\s+)(?!alpha)[^;]+;', 
            rf'\1{ui["popover"]};'),
            (r'(@define-color popover_fg_color\s+)[^;]+;', 
            rf'\1{ui["popover_fg"]};'),
            (r'(@define-color sidebar_backdrop_color\s+)[^;]+;', 
            rf'\1{ui["sidebar"]};'),
            (r'(@define-color sidebar_bg_color\s+)[^;]+;', 
            rf'\1{ui["sidebar"]};'),
            (r'(@define-color sidebar_fg_color\s+)[^;]+;', 
            rf'\1{ui["sidebar_fg"]};'),
            (r'(@define-color popover_bg_color\s+alpha\()[^)]+(\)[^;]*;)', 
            rf'\1{ui["popover"]}, 0.6\2'),
        ]
        
        self.update_file_with_regex(
            self.base_dir / "gtk-4.0/themes/hypaurora.css", 
            replacements
        )

        self.apply_gtk_theme(theme)
        
        return True
    
    def update_rofi(self, theme: Dict[str, Any]) -> bool:
        """Updates Rofi theme content."""
        colors = theme["colors"]
        base = colors["base"]
        semantic = colors["semantic"]
        ui = colors["ui"]

        # The new colors block we want to inject (the '*' selector block).
        new_colors = """* {{
    bg0:    {bg}D4;
    bg1:    {bg}D4;
    bg2:    {card}D4;
    bg3:    {card}D4;
    fg0:    {fg};
    fg1:    {fg}E6;
    fg2:    {fg}CC;
    fg3:    {fg}B3;
    border: {border};
    accent: {accent};

    font:   "Dank Mono SemiBold 11";

    background-color:   transparent;
    text-color:         @fg0;

    margin:     0px;
    padding:    0px;
    spacing:    0px;
}}""".format(
            bg=base["background"],
            fg=base["foreground"],
            card=ui["card"],
            border=semantic["border"],
            accent=semantic["accent"],
        )

        rofi_file = self.base_dir / "rofi/themes/hypaurora.rasi"
        rofi_file.parent.mkdir(parents=True, exist_ok=True)

        pattern = r'(?m)^\*\s*\{.*?^\}'
        if self.update_file_with_regex(rofi_file, [(pattern, new_colors)]):
            return True
    
    def update_eww(self, theme: Dict[str, Any]) -> bool:
        """Updates EWW theme SCSS content."""
        colors = theme["colors"]
        palette = colors["palette"]
        semantic = colors["semantic"]
        ui = colors["ui"]
        base = colors["base"]
        
        scss_vars = [
            ("// Background colors", "", ""),
            ("bg-base", base['background'], "Base background from theme"),
            ("bg-popover", ui['popover'], "Popover background from theme"),
            ("bg-active", palette[10], "Active/highlighted background"),
            ("bg-hover", palette[8], "Hover state background"),
            ("", "", ""),
            ("// Foreground/text colors", "", ""),
            ("fg-base", base['foreground'], "Base foreground text"),
            ("fg-popover", ui['popover_fg'], "Popover text from theme"),
            ("fg-sidebar", ui['sidebar_fg'], "Sidebar text from theme"),
            ("fg-active", base['background'], "Text on active background"),
            ("", "", ""),
            ("// Border colors", "", ""),
            ("border-base", semantic['border'], "Main border color"),
            ("border-popup", palette[6], "Popup window borders"),
            ("border-osd", palette[5], "On-screen display borders"),
            ("", "", ""),
            ("// Accent and functional colors", "", ""),
            ("accent-color", semantic['accent'], "General accent color"),
            ("accent-logo", palette[6], "Logo/brand color"),
            ("accent-slider", semantic['warning'], "Slider/progress color"),
        ]
        
        lines = []
        for name, value, comment in scss_vars:
            if not name:
                lines.append("")
            elif name.startswith("//"):
                lines.append(name)
            else:
                lines.append(f"${name}: {value};{' ' * (max(0, 20 - len(name)))}// {comment}")
        
        eww_file = self.base_dir / "eww/themes/hypaurora.scss"
        with open(eww_file, "w") as f:
            f.write("\n".join(lines))
        return True
    
    def generate_hyprland(self, theme: Dict[str, Any]) -> Dict[str, str]:
        """Generate Hyprland theme colors to inject into look.conf."""
        palette = theme["colors"]["palette"]
        
        return {
            "active_border": f"rgb({palette[4][1:]}) rgb({palette[2][1:]}) 25deg",
            "inactive_border": f"rgb({palette[8][1:]}) rgb({palette[0][1:]}) 25deg",
            "group_active": f"rgb({palette[1][1:]}) rgb({palette[5][1:]}) 25deg",
            "group_inactive": f"rgb({palette[3][1:]}) rgb({palette[8][1:]}) 25deg",
            "groupbar_active": f"rgb({palette[1][1:]})",
            "groupbar_inactive": f"rgba({palette[0][1:]}80)",
        }
    
    def update_gnome_shell(self, theme: Dict[str, Any]) -> bool:
        """Update only the variable color assignments in the existing
        _colors-override.scss using regex. Does NOT write a full template."""
        colors = theme["colors"]
        base = colors["base"]
        semantic = colors["semantic"]
        ui = colors["ui"]

        colors_file = (self.base_dir / "gnome-shell-theme" /
                    "gnome-shell-sass" / "_colors-override.scss")

        # Only replace the explicit assignment lines (leave computed lines like mix(...) untouched).
        replacements = [
            (r'(?m)^\s*\$_base_color_dark\s*:\s*[^;]+;',
            f'$_base_color_dark: {base["background"]};'),
            (r'(?m)^\s*\$_base_color_light\s*:\s*[^;]+;',
            f'$_base_color_light: {base["foreground"]};'),
            (r'(?m)^\s*\$base_color\s*:\s*[^;]+;',
            f'$base_color: {base["background"]};'),
            (r'(?m)^\s*\$bg_color\s*:\s*[^;]+;',
            f'$bg_color: {base["background"]};'),
            (r'(?m)^\s*\$fg_color\s*:\s*[^;]+;',
            f'$fg_color: {base["foreground"]};'),
            (r'(?m)^\s*\$osd_bg_color\s*:\s*[^;]+;',
            f'$osd_bg_color: {base["background"]};'),
            (r'(?m)^\s*\$osd_fg_color\s*:\s*[^;]+;',
            f'$osd_fg_color: {base["foreground"]};'),
            (r'(?m)^\s*\$panel_bg_color\s*:\s*[^;]+;',
            f'$panel_bg_color: {ui["headerbar"]};'),
            (r'(?m)^\s*\$panel_fg_color\s*:\s*[^;]+;',
            f'$panel_fg_color: {base["foreground"]};'),
            (r'(?m)^\s*\$card_bg_color\s*:\s*[^;]+;',
            f'$card_bg_color: {ui["card"]};'),
            (r'(?m)^\s*\$system_base_color\s*:\s*[^;]+;',
            f'$system_base_color: {base["background"]};'),
            (r'(?m)^\s*\$system_fg_color\s*:\s*[^;]+;',
            f'$system_fg_color: {base["foreground"]};'),
            (r'(?m)^\s*\$success_color\s*:\s*[^;]+;',
            f'$success_color: {semantic["success"]};'),
            (r'(?m)^\s*\$warning_color\s*:\s*[^;]+;',
            f'$warning_color: {semantic["warning"]};'),
            (r'(?m)^\s*\$error_color\s*:\s*[^;]+;',
            f'$error_color: {semantic["error"]};'),
            (r'(?m)^\s*\$destructive_color\s*:\s*[^;]+;',
            f'$destructive_color: {semantic["error"]};'),
            (r'(?m)^\s*\$selected_bg_color\s*:\s*[^;]+;',
            f'$selected_bg_color: {base["selection_bg"]};'),
            (r'(?m)^\s*\$selected_fg_color\s*:\s*[^;]+;',
            f'$selected_fg_color: {base["selection_fg"]};'),
        ]

        # Apply replacements in-place (file existence is guaranteed per your note).
        self.update_file_with_regex(colors_file, replacements)

        # No template returned — this function updates the file directly.
        return True
    
    def update_file_with_regex(self, file_path: Path, replacements: List[Tuple[str, str]]) -> bool:
        """Generic method to update file content using regex replacements."""
        if not file_path.exists():
            print(f"  ⚠ File not found: {file_path}")
            return False
        
        with open(file_path, 'r') as f:
            content = f.read()
        
        updated_content = content
        for pattern, replacement in replacements:
            updated_content = re.sub(pattern, replacement, updated_content, flags=re.DOTALL)
        
        if updated_content != content:
            with open(file_path, 'w') as f:
                f.write(updated_content)
            return True
        
        return updated_content != content
    
    def update_dunst_config(self, theme: Dict[str, Any]):
        """Update the existing dunstrc file with theme colors."""
        dunstrc_file = self.base_dir / "dunst/dunstrc"
        colors = theme["colors"]
        base = colors["base"]
        semantic = colors["semantic"]
        
        replacements = [
            (r'(frame_color\s*=\s*)"[^"]+"', f'\\1"{semantic["border"]}"'),
            (r'(highlight\s*=\s*)"[^"]+"', f'\\1"{semantic["warning"]}"'),
            (r'(\[urgency_low\]\s*\n\s*background\s*=\s*)"[^"]+"', f'\\1"{base["background"]}80"'),
            (r'(\[urgency_low\]\s*\n\s*foreground\s*=\s*)"[^"]+"', f'\\1"{base["foreground"]}"'),
            (r'(\[urgency_low\]\s*\n\s*frame_color\s*=\s*)"[^"]+"', f'\\1"{semantic["success"]}"'),
            (r'(\[urgency_normal\]\s*\n\s*background\s*=\s*)"[^"]+"', f'\\1"{base["background"]}80"'),
            (r'(\[urgency_normal\]\s*\n\s*foreground\s*=\s*)"[^"]+"', f'\\1"{base["foreground"]}"'),
            (r'(\[urgency_normal\]\s*\n\s*frame_color\s*=\s*)"[^"]+"', f'\\1"{semantic["warning"]}"'),
            (r'(\[urgency_critical\]\s*\n\s*background\s*=\s*)"[^"]+"', f'\\1"{base["background"]}80"'),
            (r'(\[urgency_critical\]\s*\n\s*foreground\s*=\s*)"[^"]+"', f'\\1"{base["foreground"]}"'),
            (r'(\[urgency_critical\]\s*\n\s*frame_color\s*=\s*)"[^"]+"', f'\\1"{semantic["error"]}"'),
        ]
        
        self.update_file_with_regex(dunstrc_file, replacements)
    
    def update_svg_colors(self, theme: Dict[str, Any]):
        """Update fill colors in SVG icon files."""
        fg_color = theme["colors"]["base"]["foreground"]
        icons_dir = self.base_dir / "eww/icons"
        
        if not icons_dir.exists():
            print(f"  ⚠ Icons directory not found: {icons_dir}")
            return
        
        svg_files = list(icons_dir.glob("*.svg"))
        for svg_file in svg_files:
            replacements = [(r'fill="#[A-Fa-f0-9]{3,6}"', f'fill="{fg_color}"')]
            self.update_file_with_regex(svg_file, replacements)
    
    def apply_hyprland_theme(self, theme: Dict[str, Any]):
        """Update Hyprland colors directly in look.conf."""
        look_conf = self.base_dir / "hypr/hyprland/look.conf"
        colors = self.generate_hyprland(theme)
        
        replacements = [
            (r'col\.active_border\s*=\s*[^\n]+', f'col.active_border = {colors["active_border"]}'),
            (r'col\.inactive_border\s*=\s*[^\n]+', f'col.inactive_border = {colors["inactive_border"]}'),
            (r'col\.border_active\s*=\s*[^\n]+', f'col.border_active = {colors["group_active"]}'),
            (r'col\.border_inactive\s*=\s*[^\n]+', f'col.border_inactive = {colors["group_inactive"]}'),
            (r'(groupbar\s*\{[^}]*col\.active\s*=\s*)[^\n]+', f'\\1{colors["groupbar_active"]}'),
            (r'(groupbar\s*\{[^}]*col\.inactive\s*=\s*)[^\n]+', f'\\1{colors["groupbar_inactive"]}'),
        ]
        
        self.update_file_with_regex(look_conf, replacements)

    def apply_gtk_theme(self, theme: Dict[str, Any]):
        """Apply GTK theme by setting color scheme and toggling high-contrast."""
        try:
            variant = theme["variant"]
            color_scheme = "'prefer-dark'" if variant == "dark" else "'default'"
            
            subprocess.run(["dconf", "write", "/org/gnome/desktop/interface/color-scheme", 
                          color_scheme], check=True)
            
            # Toggle high-contrast to force reload
            subprocess.run(["dconf", "write", "/org/gnome/desktop/a11y/interface/high-contrast", 
                          "true"], check=True)
            subprocess.run(["dconf", "write", "/org/gnome/desktop/a11y/interface/high-contrast", 
                          "false"], check=True)
        except Exception as e:
            print(f"  ⚠ Could not apply GTK CSS changes: {e}")
    
    def apply_gnome_shell_theme(self):
        """Apply GNOME Shell theme by resetting to default and then applying hypaurora."""
        try:
            subprocess.run(["dconf", "reset", "/org/gnome/shell/extensions/user-theme/name"], 
                         check=True)
            subprocess.run(["dconf", "write", "/org/gnome/shell/extensions/user-theme/name", 
                          '"hypaurora"'], check=True)
        except subprocess.CalledProcessError as e:
            print(f"  ✗ Error applying GNOME Shell theme: {e}")
        except FileNotFoundError:
            print("  ✗ dconf command not found. Please ensure dconf is installed.")
    
    def install_gnome_shell(self, theme: Dict[str, Any]) -> bool:
        """Build GNOME Shell theme and install to ~/.local/share/themes/hypaurora."""
        gnome_shell_dir = self.base_dir / "gnome-shell-theme"
        
        if not shutil.which("sassc"):
            print(f"  ⚠ sassc not found. Install it to build GNOME Shell theme:")
            print(f"     sudo dnf install sassc")
            return
        
        # Generate and write color overrides
        if not self.update_gnome_shell(theme):
            print(f"  ⚠ Could not update GNOME Shell theme colors")
            return
        
        # Build CSS using sassc
        custom_scss = gnome_shell_dir / "gnome-shell-hypaurora.scss"
        output_css = gnome_shell_dir / "gnome-shell.css"
        try:
            subprocess.run(["sassc", "-a", str(custom_scss), str(output_css)],
                         check=True, capture_output=True, text=True)
        except subprocess.CalledProcessError as e:
            print(f"  ✗ Failed to build GNOME Shell CSS:")
            print(f"    {e.stderr}")
            return
        
        # Install to theme directory
        theme_install_dir = Path.home() / ".local/share/themes/hypaurora/gnome-shell"
        theme_install_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy2(output_css, theme_install_dir / "gnome-shell.css")

        self.apply_gnome_shell_theme()
        
        return True
    
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
            str(wallpaper_path), theme_name="wallpaper", variant=variant
        )
        
        # Save theme to themes directory
        self.themes_dir.mkdir(parents=True, exist_ok=True)
        theme_file = self.themes_dir / "wallpaper.json"
        with open(theme_file, 'w') as f:
            json.dump(theme, f, indent=2)
        
        print(f"  ✓ Saved wallpaper theme to {theme_file}")
        return theme

    def apply_theme(self, theme_name: str, variant: str = "dark"):
        """Apply theme across all applications."""
        # Handle wallpaper theme specially
        theme = (self.generate_wallpaper_theme(variant=variant) 
                if theme_name == "wallpaper" else self.load_theme(theme_name))
        
        print(f"Applying theme: {theme['name']}")
        print("=" * 50)

        # Update configuration files
        config_updates = [
            ("Ghostty", lambda: self.update_ghostty(theme)),
            ("GTK", lambda: self.update_gtk(theme)),
            ("Rofi", lambda: self.update_rofi(theme)),
            ("EWW", lambda: self.update_eww(theme)),
            ("Dunst", lambda: self.update_dunst_config(theme)),
            ("Hyprland", lambda: self.apply_hyprland_theme(theme)),
            ("SVG icons", lambda: self.update_svg_colors(theme)),
            ("GNOME Shell", lambda: self.install_gnome_shell(theme)),
        ]
        
        for name, update_fn in config_updates:
            update_fn()
            print(f"  ✓ Updated {name}")
        
        # Kill dunst to apply new theme
        try:
            subprocess.run(["pkill", "dunst"], check=False)
        except Exception as e:
            print(f"  ⚠ Could not kill dunst: {e}")
        
        # Save current theme
        config = self.load_config()
        config["current_theme"] = theme_name
        self.save_config(config)
        
        print("\n✓ Theme applied successfully!\n")
        print("To reload applications:")
        print("  • Ghostty: Use Ctrl+Shift+,")
        print("  • GTK: Adwaita applications will reload automatically, Restart GTK3 applications")

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
        print("Press Ctrl+C to stop\n")
        
        last_hash = None
        last_mtime = None
        stable_count = 0
        required_stable_checks = 3  # File must be stable for 3 consecutive checks
        
        def get_file_hash(path: Path) -> Optional[str]:
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
                            print("   Generating and applying new theme...\n")
                            
                            try:
                                self.apply_theme("wallpaper", variant=variant)
                                last_hash = current_hash
                                print("\n✓ Theme applied successfully!\n")
                            except Exception as e:
                                print(f"✗ Error applying theme: {e}\n")
                        
                        # Reset counter after checking
                        stable_count = required_stable_checks
                
                except (IOError, PermissionError):
                    # File might be in the process of being written
                    stable_count = 0
                
                time.sleep(check_interval)
        
        except KeyboardInterrupt:
            print("\nStopped watching wallpaper")


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
                manager.watch_wallpaper(variant=args.variant)
            else:
                manager.apply_theme(args.theme, variant=args.variant)
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