#!/usr/bin/env python3
"""Temporarily switch every XFCE desktop to the rescue wallpaper."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


CHANNEL = "xfce4-desktop"
RESCUE_IMAGE = Path("/home/mahdi/Pictures/rescue.jpg")


def query(*args):
    return subprocess.run(
        ["xfconf-query", "-c", CHANNEL, *args], check=True,
        text=True, stdout=subprocess.PIPE,
    ).stdout.strip()


def state_path(lock_state=False):
    state_home = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
    if not state_home.is_absolute():
        raise RuntimeError("XDG_STATE_HOME must be an absolute path")
    suffix = "-lock" if lock_state else ""
    return state_home / f"hypaurora/xfce-wallpaper{suffix}.json"


def save_state(path, properties):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", dir=path.parent, delete=False
    ) as stream:
        temporary = Path(stream.name)
        json.dump(properties, stream)
        stream.write("\n")
    temporary.chmod(0o600)
    temporary.replace(path)


def list_backdrop_properties():
    return [name for name in query("-l").splitlines()
            if name.startswith("/backdrop/")]


def set_property(name, value):
    subprocess.run(
        ["xfconf-query", "-c", CHANNEL, "-p", name, "-s", value], check=True
    )


def rescue(path):
    if not RESCUE_IMAGE.is_file():
        raise RuntimeError(f"Rescue wallpaper not found: {RESCUE_IMAGE}")
    backdrop = list_backdrop_properties()
    if not backdrop:
        raise RuntimeError("No XFCE desktop backdrop properties were found")
    if not path.exists():
        original = {name: query("-p", name) for name in backdrop}
        save_state(path, original)
    for name in backdrop:
        if name.endswith("/last-image"):
            set_property(name, str(RESCUE_IMAGE))
        elif name.endswith("/image-style"):
            set_property(name, "5")


def restore(path):
    if not path.is_file():
        return
    original = json.loads(path.read_text(encoding="utf-8"))
    for name, value in original.items():
        set_property(name, value)
    path.unlink()


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in {"rescue", "restore", "lock", "unlock"}:
        raise RuntimeError(
            "Usage: hypaurora-xfce-wallpaper {rescue|restore|lock|unlock}"
        )
    lock_state = sys.argv[1] in {"lock", "unlock"}
    path = state_path(lock_state)
    if sys.argv[1] in {"rescue", "lock"}:
        rescue(path)
    else:
        restore(path)


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.CalledProcessError, json.JSONDecodeError) as error:
        raise SystemExit(f"Wallpaper shortcut failed: {error}") from error
