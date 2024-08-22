import os
import subprocess
import time
from PIL import Image
from statistics import mean
from gi.repository import Gio, GLib

HOME = os.path.expanduser("~")
CONFIG_DIR = os.path.join(HOME, ".config")
BG_FILE = os.path.join(CONFIG_DIR, "background")
BG_DARK_FILE = os.path.join(CONFIG_DIR, "background-dark")


def calculate_brightness(image_path):
  with Image.open(image_path) as img:
    # Convert image to grayscale
    grayscale_image = img.convert('L')

    # Get pixel data
    pixel_data = list(grayscale_image.getdata())

    # Calculate average brightness
    avg_brightness = mean(pixel_data)

    # Normalize to 0-100 scale
    normalized_brightness = (avg_brightness / 255) * 100

    return round(normalized_brightness, 2)


def get_gsettings_value(key):
  settings = Gio.Settings.new("org.gnome.desktop.background")
  return settings.get_string(key)


def set_gsettings_value(key, value):
  subprocess.run(["gsettings", "set", "org.gnome.desktop.background", key, value])


def copy_current_background(background: str):
  current_bg = get_gsettings_value("picture-uri")
  if current_bg.startswith("file://"):
    current_bg = current_bg[7:]
  if background == 'light':
    if not os.path.exists(BG_FILE) or os.path.realpath(current_bg) != os.path.realpath(BG_FILE):
      subprocess.run(["cp", current_bg, BG_FILE])
  else:
    if not os.path.exists(BG_DARK_FILE) or os.path.realpath(current_bg) != os.path.realpath(BG_DARK_FILE):
      subprocess.run(["cp", current_bg, BG_DARK_FILE])


def create_dark_background():
  with Image.open(BG_FILE) as img:
    dark_img = img.point(lambda p: p * 0.6)
    dark_img.save(BG_DARK_FILE, 'PNG')


def create_light_background():
  with Image.open(BG_DARK_FILE) as img:
    # TODO: Make image a little brighter instead of darker
    dark_img = img.point(lambda p: min(p * 1.4, 255))
    dark_img.save(BG_FILE, 'PNG')


def update_backgrounds():
  print("Updating background...")

  background_brightness = calculate_brightness(BG_FILE)
  print("brightness: {}".format(background_brightness))

  if background_brightness > 35:
    print("Background Image is Light")
    copy_current_background('light')
    create_dark_background()
  else:
    print("Background Image is Dark")
    copy_current_background('dark')
    create_light_background()

  time.sleep(0.3)
  set_gsettings_value("picture-uri", f"file://{BG_FILE}")
  set_gsettings_value("picture-uri-dark", f"file://{BG_DARK_FILE}")
  time.sleep(2)
  print("Background Updated")


def monitor_gsettings():
  settings = Gio.Settings.new("org.gnome.desktop.background")
  def on_changed(settings, key):
    if key in ["picture-uri", "picture-uri-dark"]:
      current_bg = settings.get_string("picture-uri")
      current_bg_dark = settings.get_string("picture-uri-dark")
      if (current_bg == "'file:///usr/share/backgrounds/gnome/adwaita-l.jxl'"
        or current_bg_dark == "'file:///usr/share/backgrounds/gnome/adwaita-d.jxl'"):
        return
      update_backgrounds()

  handler_id = settings.connect("changed", on_changed)
  GLib.MainLoop().run()


if __name__ == "__main__":
  monitor_gsettings()
