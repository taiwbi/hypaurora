#!/usr/bin/env python3
"""Remind the XFCE user to take a short eye break every 20 minutes."""

import re
import signal
import subprocess
import time


WORK_SECONDS = 20 * 60
BREAK_SECONDS = 90
SNOOZE_SECONDS = 3 * 60
MAX_SNOOZES = 2
DIM_FACTOR = 0.2
SNOOZE_LABEL = "Postpone 3 minutes"


def gtk_modules():
    import gi

    gi.require_version("Gtk", "3.0")
    from gi.repository import GLib, Gtk
    return GLib, Gtk


def connected_outputs():
    result = subprocess.run(
        ["xrandr", "--verbose"], capture_output=True, text=True, check=True,
    )
    outputs = []
    current_name = None
    current_lines = []
    for line in result.stdout.splitlines():
        if not line[:1].isspace():
            if current_name is not None:
                outputs.append((current_name, "\n".join(current_lines)))
            match = re.match(r"^(\S+) connected\b", line)
            current_name = match.group(1) if match else None
            current_lines = [line] if current_name else []
        elif current_name is not None:
            current_lines.append(line)
    if current_name is not None:
        outputs.append((current_name, "\n".join(current_lines)))
    return outputs


def run_xrandr(output, *arguments):
    subprocess.run(
        ["xrandr", "--output", output, *arguments],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True,
    )


def dim_outputs():
    """Dim connected outputs and return the values needed to restore them."""
    saved = []
    for output, details in connected_outputs():
        backlight = re.search(
            r"\bBacklight:\s*(-?\d+).*?\brange:\s*\((-?\d+),\s*(-?\d+)\)",
            details, re.DOTALL,
        )
        if backlight:
            original, minimum, maximum = map(int, backlight.groups())
            target = round(minimum + (maximum - minimum) * DIM_FACTOR)
            try:
                run_xrandr(output, "--set", "Backlight", str(target))
                saved.append((output, ("--set", "Backlight", str(original))))
                continue
            except subprocess.CalledProcessError:
                pass

        brightness = re.search(r"^\s+Brightness:\s*([0-9.]+)\s*$", details, re.M)
        if brightness:
            original = brightness.group(1)
            try:
                run_xrandr(output, "--brightness", str(DIM_FACTOR))
                saved.append((output, ("--brightness", original)))
            except subprocess.CalledProcessError:
                continue
    return saved


def restore_outputs(saved):
    for output, arguments in reversed(saved):
        try:
            run_xrandr(output, *arguments)
        except (OSError, subprocess.CalledProcessError):
            pass


def show_reminder(snoozes):
    _, Gtk = gtk_modules()
    window = Gtk.Window(type=Gtk.WindowType.TOPLEVEL)
    window.set_title("Eye break")
    window.set_resizable(False)
    window.set_position(Gtk.WindowPosition.CENTER)
    window.set_keep_above(True)
    window.set_modal(True)

    content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=18)
    content.set_border_width(22)
    content.pack_start(
        Gtk.Label(label="Look away from your monitor for 90 seconds."),
        True, True, 0,
    )
    buttons = Gtk.ButtonBox(orientation=Gtk.Orientation.HORIZONTAL)
    buttons.set_layout(Gtk.ButtonBoxStyle.CENTER)
    content.pack_start(buttons, False, False, 0)
    window.add(content)

    result = {"snooze": False, "finished": False}

    def finish(snooze=False):
        if result["finished"]:
            return
        result["finished"] = True
        result["snooze"] = snooze
        window.destroy()
        if Gtk.main_level():
            Gtk.main_quit()

    window.connect("delete-event", lambda *_: (finish(), True)[1])

    start_button = Gtk.Button(label="Start 90-second break")
    start_button.connect("clicked", lambda *_: finish())
    buttons.add(start_button)
    if snoozes < MAX_SNOOZES:
        snooze_button = Gtk.Button(label=SNOOZE_LABEL)
        snooze_button.connect("clicked", lambda *_: finish(snooze=True))
        buttons.add(snooze_button)

    window.show_all()
    Gtk.main()
    if result["snooze"]:
        try:
            subprocess.run(
                ["notify-send", "Eye break", "Postponed for 3 minutes."],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False,
            )
        except OSError:
            pass
        return True
    return False


def gtk_break_dialog():
    GLib, Gtk = gtk_modules()
    started = time.monotonic()
    window = Gtk.Window(type=Gtk.WindowType.TOPLEVEL)
    window.set_title("Eye break")
    window.set_resizable(False)
    window.set_position(Gtk.WindowPosition.CENTER)
    window.set_keep_above(True)

    content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
    content.set_border_width(22)
    content.pack_start(
        Gtk.Label(label="Look at something about 20 feet away."),
        False, False, 0,
    )
    countdown = Gtk.Label()
    content.pack_start(countdown, False, False, 0)
    window.add(content)

    finished = {"value": False}

    def finish(*_):
        if finished["value"]:
            return
        finished["value"] = True
        window.destroy()
        if Gtk.main_level():
            Gtk.main_quit()

    window.connect("delete-event", lambda *_: (finish(), True)[1])

    def update_countdown():
        remaining = max(0, BREAK_SECONDS - int(time.monotonic() - started))
        countdown.set_text(
            f"Your screen brightness returns in {remaining} seconds."
        )
        if remaining == 0:
            finish()
            return False
        return True

    update_countdown()
    GLib.timeout_add_seconds(1, update_countdown)
    window.show_all()
    Gtk.main()
    # If the user closes the countdown window early, keep the screen dimmed
    # until the full break has elapsed. No GTK window remains during this wait.
    remaining = BREAK_SECONDS - (time.monotonic() - started)
    if remaining > 0:
        time.sleep(remaining)


def take_break():
    saved = dim_outputs()
    try:
        gtk_break_dialog()
    finally:
        restore_outputs(saved)


def stop_on_sigterm(_signal_number, _frame):
    raise KeyboardInterrupt


def main():
    signal.signal(signal.SIGTERM, stop_on_sigterm)
    while True:
        time.sleep(WORK_SECONDS)
        snoozes = 0
        while show_reminder(snoozes):
            snoozes += 1
            time.sleep(SNOOZE_SECONDS)
        take_break()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
    except (OSError, subprocess.CalledProcessError) as error:
        raise SystemExit(f"Eye break reminder stopped: {error}") from error
