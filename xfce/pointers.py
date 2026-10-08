#!/usr/bin/env python3
"""Apply the XFCE acceleration value to this machine's mice and touchpads."""

import os
import re
import subprocess


def output(*command):
    return subprocess.run(command, check=True, text=True, capture_output=True).stdout


def set_property(device, name, values, kind, array=False):
    command = ["xfconf-query", "-c", "pointers", "-p", f"/{device}/{name}", "-n"]
    if array:
        command.append("--force-array")
    for value in values:
        command.extend(("-t", kind, "-s", str(value)))
    subprocess.run(command, check=True)


def main():
    if not os.environ.get("DISPLAY") or os.environ.get("XDG_SESSION_TYPE") == "wayland":
        return
    for line in output("xinput", "list", "--short").splitlines():
        match = re.search(r"id=(\d+).*\[slave\s+pointer", line)
        if not match:
            continue
        device_id = match.group(1)
        try:
            properties = output("xinput", "list-props", device_id)
            if "libinput Accel Speed (" not in properties:
                continue
            name = output("xinput", "list", "--name-only", device_id).strip()
            # Match xfce4-settings' device_xfconf_name conversion exactly.
            device = re.sub(r"[^A-Za-z0-9_-]", "", name.replace(" ", "_"))
            if not device:
                continue
            profile = re.search(
                r"libinput Accel Profiles Available \(\d+\):\s*([0-9,\s]+)",
                properties,
            )
            if profile:
                available = [value.strip() for value in profile.group(1).strip().split(",")]
                if len(available) >= 2 and available[1] == "1":
                    values = [0] * len(available)
                    values[1] = 1
                    set_property(device, "Properties/libinput_Accel_Profile_Enabled",
                                 values, "int", array=True)
            set_property(device, "Acceleration", ["8.0"], "double")
            # XFCE maps its 0..10 slider to libinput -1..1: (8 / 5) - 1 = 0.6.
            # Apply directly too, including when xfconf already has the same value.
            if profile and len(available) >= 2 and available[1] == "1":
                subprocess.run(["xinput", "set-prop", device_id,
                                "libinput Accel Profile Enabled", *map(str, values)], check=True)
            subprocess.run(["xinput", "set-prop", device_id,
                            "libinput Accel Speed", "0.6"], check=True)
        except subprocess.CalledProcessError as error:
            # A device may be disconnected while being enumerated.
            print(f"Could not configure pointer {device_id}: {error}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, subprocess.CalledProcessError) as error:
        raise SystemExit(f"Pointer setup failed: {error}") from error
