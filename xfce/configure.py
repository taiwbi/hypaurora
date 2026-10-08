#!/usr/bin/env python3
"""Install portable XFCE snapshots while its settings daemon is stopped."""

import argparse
import copy
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET


SOURCE = Path(__file__).resolve().parent
CHANNEL_PATH = Path("xfconf/xfce-perchannel-xml")
MERGE_CHANNELS = {
    "xsettings", "xfce4-desktop", "xfce4-power-manager", "xfce4-terminal",
}


def check_session():
    for process in ("xfce4-session",):
        result = subprocess.run(
            ["pgrep", "-u", str(os.getuid()), "-x", process],
            stdout=subprocess.DEVNULL, check=False,
        )
        if result.returncode == 0:
            raise RuntimeError(
                f"{process} is running. Log out of XFCE and run this from a TTY "
                "(Ctrl+Alt+F3). Do not stop xfconfd inside a running desktop."
            )
        if result.returncode != 1:
            raise RuntimeError(f"Cannot check whether {process} is running.")


def merge_properties(target, source):
    for prop in source.findall("property"):
        existing = next(
            (node for node in target.findall("property")
             if node.get("name") == prop.get("name")), None,
        )
        if existing is not None and prop.get("type") == "empty":
            merge_properties(existing, prop)
        else:
            if existing is not None:
                target.remove(existing)
            target.append(copy.deepcopy(prop))


def wireless_interface():
    interfaces = sorted(
        path for path in Path("/sys/class/net").iterdir()
        if (path / "wireless").exists() or (path / "phy80211").exists()
    )
    for interface in interfaces:
        if (interface / "operstate").read_text().strip() == "up":
            return interface.name
    # An explicit empty interface keeps Wavelan hidden on machines without Wi-Fi.
    return interfaces[0].name if interfaces else ""


def atomic_write(path, data, mode=0o644):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as stream:
        temporary = Path(stream.name)
        stream.write(data)
    try:
        temporary.chmod(mode)
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--backup-dir", type=Path)
    parser.add_argument("--gtk-theme", default="Skeuos-Blue-Dark")
    parser.add_argument("--wm-theme", default="Skeuos-Blue-Dark-XFWM")
    parser.add_argument("--icon-theme", default="Flat-Remix-Blue-Dark")
    args = parser.parse_args()
    home = Path.home()
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", home / ".config"))
    if not config_home.is_absolute():
        raise RuntimeError("XDG_CONFIG_HOME must be an absolute path.")
    destination = config_home / "xfce4"
    bin_dir = home / ".local/bin"
    for path in (destination, destination / "xfconf", destination / CHANNEL_PATH,
                 destination / "panel", config_home / "autostart", bin_dir):
        if path.is_symlink():
            raise RuntimeError(f"Refusing to write through directory symlink: {path}")
    for theme in (args.gtk_theme, args.wm_theme, args.icon_theme):
        if not re.fullmatch(r"[A-Za-z0-9_+.-]+", theme) or theme in (".", ".."):
            raise RuntimeError(f"Invalid theme directory name: {theme}")
    replacements = {
        "@HOME@": str(home),
        "@CENTER_COMMAND@": '"' + str(bin_dir / "hypaurora-center-window") + '"',
        "@GTK_THEME@": args.gtk_theme,
        "@WM_THEME@": args.wm_theme,
        "@ICON_THEME@": args.icon_theme,
    }
    writes = []
    for source in sorted((SOURCE / CHANNEL_PATH).glob("*.xml")):
        tree = ET.parse(source)
        for node in tree.iter():
            value = node.get("value")
            if value in replacements:
                node.set("value", replacements[value])
        target = destination / CHANNEL_PATH / source.name
        if source.stem in MERGE_CHANNELS and target.exists():
            existing = ET.parse(target)
            merge_properties(existing.getroot(), tree.getroot())
            tree = existing
        ET.indent(tree, space="  ")
        data = ET.tostring(tree.getroot(), encoding="UTF-8", xml_declaration=True)
        writes.append((target, data + b"\n", 0o644))
    for source in sorted((SOURCE / "panel").rglob("*")):
        if source.is_file():
            data = source.read_bytes().replace(
                b"@WIFI_INTERFACE@", wireless_interface().encode()
            )
            writes.append((destination / source.relative_to(SOURCE), data, 0o644))
    for name, source in (("hypaurora-center-window", "center-window.sh"),
                         ("hypaurora-xfce-pointers", "pointers.py")):
        writes.append((bin_dir / name, (SOURCE / source).read_bytes(), 0o755))
    # Desktop Entry quoting requires backslashes to be escaped twice.
    executable = str(bin_dir / "hypaurora-xfce-pointers")
    executable = executable.replace("\\", "\\\\\\\\").replace('"', '\\\\"')
    executable = executable.replace("`", "\\\\`").replace("$", "\\\\$").replace("%", "%%")
    autostart = (
        "[Desktop Entry]\nType=Application\nName=Hypaurora XFCE pointer settings\n"
        f'Exec="{executable}"\nOnlyShowIn=XFCE;\nTerminal=false\n'
        "X-XFCE-Autostart-Phase=Applications\n"
    )
    writes.append((config_home / "autostart/hypaurora-xfce-pointers.desktop",
                   autostart.encode(), 0o644))
    for source in sorted((SOURCE / "autostart").glob("*.desktop")):
        writes.append((config_home / "autostart" / source.name,
                       source.read_bytes(), 0o644))
    for path, _, _ in writes:
        for parent in path.parents:
            if parent == home:
                break
            if parent.is_symlink():
                raise RuntimeError(f"Refusing to write through directory symlink: {parent}")
    if args.dry_run:
        for path, _, _ in writes:
            print(f"Would install {path}")
        return
    check_session()
    if args.check:
        return
    if args.backup_dir is None:
        parser.error("--backup-dir is required when installing")
    backup = args.backup_dir.expanduser().resolve()
    backup.mkdir(parents=True, exist_ok=True)
    if destination.exists():
        shutil.copytree(destination, backup / "xfce4", symlinks=True)
    for path, _, _ in writes:
        if path.is_relative_to(destination):
            continue
        if path.exists() or path.is_symlink():
            saved = backup / ("bin" if path.parent == bin_dir else "autostart") / path.name
            saved.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, saved, follow_symlinks=False)
    for path, data, mode in writes:
        atomic_write(path, data, mode)
    print(f"XFCE configuration installed. Backups: {backup}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, ET.ParseError) as error:
        raise SystemExit(f"Error: {error}") from error
