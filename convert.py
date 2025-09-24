#!/usr/bin/env python3
"""
Convert Ghostty terminal themes to Kitty terminal themes format.
Specifically processes all bearded_* themes from ghostty/themes/ directory
and saves them to kitty/themes/bearded/ directory.
"""

import os
import re
from pathlib import Path


def parse_ghostty_theme(content):
    """Parse Ghostty theme file content and extract color values."""
    theme_data = {}

    for line in content.strip().split("\n"):
        line = line.strip()
        if not line or line.startswith("#"):
            continue

        # Parse palette entries
        palette_match = re.match(r"palette\s*=\s*(\d+)=(#[0-9a-fA-F]{6})", line)
        if palette_match:
            color_index = int(palette_match.group(1))
            color_value = palette_match.group(2)
            theme_data[f"palette_{color_index}"] = color_value
            continue

        # Parse other properties
        prop_match = re.match(r"([^=]+)\s*=\s*(#[0-9a-fA-F]{6})", line)
        if prop_match:
            prop_name = prop_match.group(1).strip()
            prop_value = prop_match.group(2)
            theme_data[prop_name] = prop_value

    return theme_data


def convert_to_kitty_format(theme_data, theme_name):
    """Convert parsed theme data to Kitty format."""
    kitty_lines = []

    # Add header comment
    kitty_lines.append(f"# Theme - {theme_name}")
    kitty_lines.append("")

    # Basic colors
    if "foreground" in theme_data:
        kitty_lines.append(f"foreground {theme_data['foreground']}")
    if "background" in theme_data:
        kitty_lines.append(f"background {theme_data['background']}")

    # Selection colors
    if "selection-foreground" in theme_data:
        kitty_lines.append(f"selection_foreground {theme_data['selection-foreground']}")
    if "selection-background" in theme_data:
        kitty_lines.append(f"selection_background {theme_data['selection-background']}")

    kitty_lines.append("")

    # Cursor colors
    kitty_lines.append("# Cursor")
    if "cursor-color" in theme_data:
        kitty_lines.append(f"cursor {theme_data['cursor-color']}")
    if "cursor-text" in theme_data:
        kitty_lines.append(f"cursor_text_color {theme_data['cursor-text']}")

    kitty_lines.append("")

    # Color palette
    color_names = [
        ("Black", 0, 8),
        ("Red", 1, 9),
        ("Green", 2, 10),
        ("Yellow", 3, 11),
        ("Blue", 4, 12),
        ("Magenta", 5, 13),
        ("Cyan", 6, 14),
        ("White", 7, 15),
    ]

    for color_name, normal_idx, bright_idx in color_names:
        kitty_lines.append(f"# {color_name}")

        normal_key = f"palette_{normal_idx}"
        bright_key = f"palette_{bright_idx}"

        if normal_key in theme_data:
            kitty_lines.append(f"color{normal_idx} {theme_data[normal_key]}")
        if bright_key in theme_data:
            kitty_lines.append(f"color{bright_idx} {theme_data[bright_key]}")

        kitty_lines.append("")

    # Remove trailing empty line
    if kitty_lines and kitty_lines[-1] == "":
        kitty_lines.pop()

    return "\n".join(kitty_lines)


def convert_theme_file(input_path, output_path, theme_name):
    """Convert a single theme file from Ghostty to Kitty format."""
    try:
        with open(input_path, "r", encoding="utf-8") as f:
            ghostty_content = f.read()

        theme_data = parse_ghostty_theme(ghostty_content)
        kitty_content = convert_to_kitty_format(theme_data, theme_name)

        # Create output directory if it doesn't exist
        output_path.parent.mkdir(parents=True, exist_ok=True)

        with open(output_path, "w", encoding="utf-8") as f:
            f.write(kitty_content)

        print(f"✓ Converted: {input_path.name} → {output_path.name}")
        return True

    except Exception as e:
        print(f"✗ Error converting {input_path.name}: {e}")
        return False


def main():
    """Main function to process all bearded themes."""
    # Define paths
    ghostty_themes_dir = Path("ghostty/themes")
    kitty_themes_dir = Path("kitty/themes/bearded")

    if not ghostty_themes_dir.exists():
        print(f"Error: Directory '{ghostty_themes_dir}' not found!")
        print("Please make sure you're running this script from the correct location.")
        return

    # Find all bearded theme files
    bearded_files = list(ghostty_themes_dir.glob("bearded_*"))

    if not bearded_files:
        print(f"No bearded_* theme files found in '{ghostty_themes_dir}'")
        return

    print(f"Found {len(bearded_files)} bearded theme files to convert:")
    print()

    converted_count = 0

    for theme_file in sorted(bearded_files):
        # Remove 'bearded_' prefix from filename
        original_name = theme_file.stem  # filename without extension
        if original_name.startswith("bearded_"):
            new_name = original_name[8:]  # Remove 'bearded_' (8 characters)
        else:
            new_name = original_name

        # Create theme display name (capitalize and replace underscores)
        theme_display_name = new_name.replace("_", " ").title()

        # Define output path
        output_file = kitty_themes_dir / f"{new_name}.conf"

        # Convert the theme
        if convert_theme_file(theme_file, output_file, f"Bearded {theme_display_name}"):
            converted_count += 1

    print()
    print(
        f"Conversion complete! {converted_count}/{len(bearded_files)} themes converted successfully."
    )
    print(f"Kitty themes saved to: {kitty_themes_dir}")
    print()
    print("To use a theme in Kitty, add this line to your kitty.conf:")
    print("include themes/bearded/THEME_NAME.conf")


if __name__ == "__main__":
    main()
