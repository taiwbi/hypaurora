import os
import subprocess
import time
from PIL import Image
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from gi.repository import Gio, GLib

HOME = os.path.expanduser("~")
CONFIG_DIR = os.path.join(HOME, ".config")
BG_FILE = os.path.join(CONFIG_DIR, "background")
BG_DARK_FILE = os.path.join(CONFIG_DIR, "background-dark")

def get_gsettings_value(key):
    settings = Gio.Settings.new("org.gnome.desktop.background")
    return settings.get_string(key)

def set_gsettings_value(key, value):
    subprocess.run(["gsettings", "set", "org.gnome.desktop.background", key, value])

def copy_current_background():
    current_bg = get_gsettings_value("picture-uri")
    if current_bg.startswith("file://"):
        current_bg = current_bg[7:]
    if not os.path.exists(BG_FILE) or os.path.realpath(current_bg) != os.path.realpath(BG_FILE):
        subprocess.run(["cp", current_bg, BG_FILE])

def create_dark_background():
    time.sleep(1)
    with Image.open(BG_FILE) as img:
        dark_img = img.point(lambda p: p * 0.6)
        dark_img.save(BG_DARK_FILE, 'PNG')

def update_backgrounds():
    copy_current_background()
    create_dark_background()
    time.sleep(0.3)
    set_gsettings_value("picture-uri", f"file://{BG_FILE}")
    set_gsettings_value("picture-uri-dark", f"file://{BG_DARK_FILE}")

class BackgroundChangeHandler(FileSystemEventHandler):
    def on_modified(self, event):
        if event.src_path == BG_FILE:
            update_backgrounds()

def monitor_gsettings():
    settings = Gio.Settings.new("org.gnome.desktop.background")
    prev_bg = settings.get_string("picture-uri")
    prev_bg_dark = settings.get_string("picture-uri-dark")

    def on_changed(settings, key):
        nonlocal prev_bg, prev_bg_dark
        if key in ["picture-uri", "picture-uri-dark"]:
            current_bg = settings.get_string("picture-uri")
            current_bg_dark = settings.get_string("picture-uri-dark")
            if current_bg != prev_bg or current_bg_dark != prev_bg_dark:
                update_backgrounds()
                prev_bg = current_bg
                prev_bg_dark = current_bg_dark

    settings.connect("changed", on_changed)
    GLib.MainLoop().run()

if __name__ == "__main__":
    update_backgrounds()

    observer = Observer()
    observer.schedule(BackgroundChangeHandler(), CONFIG_DIR, recursive=False)
    observer.start()

    try:
        monitor_gsettings()
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
