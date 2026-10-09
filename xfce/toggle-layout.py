#!/usr/bin/env python3
"""Toggle between the two active XKB groups in an X11 session."""

import ctypes
import sys


XKB_USE_CORE_KBD = 0x0100
LAYOUT_COUNT = 2


class XkbState(ctypes.Structure):
    """Layout and modifier state returned by XkbGetState."""

    _fields_ = [
        (name, ctypes.c_ubyte)
        for name in (
            "group locked_group base_group latched_group mods base_mods "
            "latched_mods locked_mods compat_state grab_mods "
            "compat_grab_mods lookup_mods compat_lookup_mods"
        ).split()
    ] + [("ptr_buttons", ctypes.c_ushort)]


def main():
    try:
        x11 = ctypes.CDLL("libX11.so.6")
    except OSError as error:
        raise SystemExit(f"Cannot load libX11: {error}") from error

    x11.XOpenDisplay.restype = ctypes.c_void_p
    x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
    x11.XCloseDisplay.argtypes = [ctypes.c_void_p]
    x11.XkbGetState.argtypes = [
        ctypes.c_void_p, ctypes.c_uint, ctypes.POINTER(XkbState),
    ]
    x11.XkbLockGroup.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_uint]
    x11.XkbLockGroup.restype = ctypes.c_int
    x11.XSync.argtypes = [ctypes.c_void_p, ctypes.c_int]

    display = x11.XOpenDisplay(None)
    if not display:
        raise SystemExit("Cannot connect to the X11 display.")

    try:
        state = XkbState()
        status = x11.XkbGetState(display, XKB_USE_CORE_KBD, ctypes.byref(state))
        if status != 0:
            raise SystemExit(f"XkbGetState failed with status {status}.")

        target_group = (state.group + 1) % LAYOUT_COUNT
        if not x11.XkbLockGroup(display, XKB_USE_CORE_KBD, target_group):
            raise SystemExit(f"Could not switch to XKB group {target_group}.")
        x11.XSync(display, 0)
    finally:
        x11.XCloseDisplay(display)


if __name__ == "__main__":
    main()
