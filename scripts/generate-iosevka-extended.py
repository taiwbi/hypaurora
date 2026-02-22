#!/usr/bin/env python3
"""
Rename Dank Mono TTF internal family name so apps (e.g., Zed) can see it as a real family.

Input files expected: Dank Mono*.ttf
Output: rewritten TTFs with family "Dank Mono" and proper subfamily (Regular/Bold/Italic/...).

Usage:
  python3 rename_iosevka_extended.py \
    --in-dir ~/.local/share/fonts/Mono/Dank Mono \
    --out-dir ~/.local/share/fonts/Mono/Dank Mono

Then:
  fc-cache -f
  restart Zed
  set "buffer_font_family": "Dank Mono Extended"
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

from fontTools.ttLib import TTFont

TOKENS = [
    # weight-ish tokens (prefer longer first)
    "ExtraLight",
    "ExtraBold",
    "SemiBold",
    "Medium",
    "Light",
    "Bold",
    "Heavy",
    "Thin",
    # posture tokens
    "Italic",
    "Oblique",
]

# Expanders for nicer spacing
EXPAND = {
    "ExtraLight": "Extra Light",
    "ExtraBold": "Extra Bold",
    "SemiBold": "Semi Bold",
}


def derive_style_from_filename(ttf_path: Path) -> str:
    """
    From 'Dank Mono-ExtendedBoldItalic.ttf' -> 'Bold Italic'
    From 'Dank Mono-Extended.ttf' -> 'Regular'
    """
    stem = ttf_path.stem  # no extension
    prefix = "Dank Mono-Extended"
    if stem == prefix:
        return "Regular"

    if stem.startswith(prefix):
        tail = stem[len(prefix) :]
    else:
        # fallback: strip leading "Dank Mono-" if present
        tail = stem.replace("Dank Mono-", "", 1)

    tail = tail.lstrip("-_ ")

    if not tail or tail.lower() == "regular":
        return "Regular"

    out: list[str] = []
    s = tail
    while s:
        matched = False
        for t in TOKENS:
            if s.startswith(t):
                out.append(t)
                s = s[len(t) :]
                matched = True
                break
        if matched:
            continue

        # Unknown chunk: try to take one CamelCase word
        m = re.match(r"([A-Z][a-z0-9]+)", s)
        if m:
            out.append(m.group(1))
            s = s[len(m.group(1)) :]
        else:
            # last resort: consume 1 char to avoid infinite loop
            out.append(s[0])
            s = s[1:]

    words: list[str] = []
    for w in out:
        w = EXPAND.get(w, w)
        words.extend(w.split())

    style = " ".join(words).strip()
    return style or "Regular"


def ps_safe(s: str) -> str:
    """PostScript name must not contain spaces and should be ASCII-ish."""
    s = re.sub(r"\s+", "", s)
    s = re.sub(r"[^A-Za-z0-9\-]", "", s)
    return s


def set_name_id_for_all_platforms(font: TTFont, name_id: int, value: str) -> None:
    """
    Update all existing records for a given nameID across platforms/encodings
    (Windows/Mac; various langIDs). This improves compatibility.
    """
    name_table = font["name"]
    for rec in name_table.names:
        if rec.nameID != name_id:
            continue
        try:
            rec.string = value.encode(rec.getEncoding())
        except Exception:
            # common fallback
            rec.string = value.encode("utf-16be")


def rename_font(ttf_in: Path, ttf_out: Path, family: str) -> None:
    style = derive_style_from_filename(ttf_in)

    font = TTFont(str(ttf_in))

    if "name" not in font:
        raise RuntimeError(f"{ttf_in} has no 'name' table")

    # Name IDs:
    # 1  = Font Family
    # 2  = Font Subfamily (Regular/Bold/Italic...)
    # 4  = Full font name (Family + Subfamily)
    # 6  = PostScript name
    # 16 = Typographic Family (preferred for modern apps)
    # 17 = Typographic Subfamily
    # 18 = Compatible Full Name
    full = family if style.lower() == "regular" else f"{family} {style}"
    ps = ps_safe(f"{family}-{style}")

    # Set both classic and typographic family/subfamily
    set_name_id_for_all_platforms(font, 1, family)
    set_name_id_for_all_platforms(font, 16, family)

    set_name_id_for_all_platforms(font, 2, style)
    set_name_id_for_all_platforms(font, 17, style)

    set_name_id_for_all_platforms(font, 4, full)
    set_name_id_for_all_platforms(font, 18, full)

    set_name_id_for_all_platforms(font, 6, ps)

    ttf_out.parent.mkdir(parents=True, exist_ok=True)
    font.save(str(ttf_out))

    print(f"Wrote: {ttf_out.name:40}  (style: {style})")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--in-dir", required=True, help="Directory containing Dank Mono-Extended*.ttf"
    )
    ap.add_argument(
        "--out-dir", required=True, help="Output directory for rewritten fonts"
    )
    ap.add_argument(
        "--family",
        default="Dank Mono Extended",
        help='New family name (default: "Dank Mono Extended")',
    )
    ap.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would happen without writing files",
    )
    args = ap.parse_args()

    in_dir = Path(os.path.expanduser(args.in_dir)).resolve()
    out_dir = Path(os.path.expanduser(args.out_dir)).resolve()
    family = args.family

    if not in_dir.is_dir():
        print(f"ERROR: in-dir not found or not a directory: {in_dir}", file=sys.stderr)
        return 2

    inputs = sorted(in_dir.glob("Dank Mono-Extended*.ttf"))
    if not inputs:
        print(
            f"ERROR: no files matched {in_dir}/Dank Mono-Extended*.ttf", file=sys.stderr
        )
        return 3

    print(f"Input : {in_dir}")
    print(f"Output: {out_dir}")
    print(f"Family: {family}")
    print(f"Fonts : {len(inputs)} file(s)")
    print()

    for ttf_in in inputs:
        # Cosmetic output filename
        style = derive_style_from_filename(ttf_in)
        style_compact = ps_safe(style)
        out_name = (
            f"Dank MonoExtended-{style_compact}.ttf"
            if style_compact.lower() != "regular"
            else "Dank MonoExtended-Regular.ttf"
        )
        ttf_out = out_dir / out_name

        if args.dry_run:
            print(
                f"Would write: {ttf_out.name:40}  from {ttf_in.name}  (style: {style})"
            )
        else:
            rename_font(ttf_in, ttf_out, family)

    if not args.dry_run:
        print("\nDone. Now run:  fc-cache -f")
        print('Then restart Zed and set:  "buffer_font_family": "Dank Mono Extended"')

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
