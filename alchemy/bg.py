import os
import subprocess
import time
from PIL import Image
from statistics import mean
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from gi.repository import Gio, GLib
import signal
import threading

HOME = os.path.expanduser("~")
CONFIG_DIR = os.path.join(HOME, ".config")
BG_FILE = os.path.join(CONFIG_DIR, "background")
BG_LIGHT_FILE = os.path.join(CONFIG_DIR, "background-light")
BG_DARK_FILE = os.path.join(CONFIG_DIR, "background-dark")

last_update_time = 0


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
  settings = Gio.Settings.new("org.gnome.desktop.background")
  settings.set_string(key, value)


def copy_current_background(background: str):
  current_bg = get_gsettings_value("picture-uri")
  if current_bg.startswith("file://"):
    current_bg = current_bg[7:]

  if not os.path.exists(BG_FILE) or os.path.realpath(current_bg) != os.path.realpath(BG_FILE):
    subprocess.run(["cp", current_bg, BG_FILE])

  if background == 'light':
    subprocess.run(["cp", current_bg, BG_LIGHT_FILE])
  else:
    subprocess.run(["cp", current_bg, BG_DARK_FILE])


def create_dark_background():
  with Image.open(BG_FILE) as img:
    dark_img = img.point(lambda p: p * 0.6)
    dark_img.save(BG_DARK_FILE, 'PNG')


def create_light_background():
  with Image.open(BG_DARK_FILE) as img:
    dark_img = img.point(lambda p: min(p * 1.3, 255))
    dark_img.save(BG_LIGHT_FILE, 'PNG')


def update_backgrounds():
  global last_update_time

  if time.time() - last_update_time < 5:
    last_update_time = time.time()
    return

  last_update_time = time.time()

  print(f"Updating background...")

  background_brightness = calculate_brightness(BG_FILE)
  print("brightness: {}".format(background_brightness))

  if background_brightness > 40:
    print("Background Image is Light")
    copy_current_background('light')
    create_dark_background()
  else:
    print("Background Image is Dark")
    copy_current_background('dark')
    create_light_background()

  set_gsettings_value("picture-uri", f"file://{BG_LIGHT_FILE}")
  set_gsettings_value("picture-uri-dark", f"file://{BG_DARK_FILE}")
  print("Background Updated")
  last_update_time = time.time()


class BackgroundChangeHandler(FileSystemEventHandler):
  def on_modified(self, event):
    if event.src_path == BG_FILE:
      time.sleep(1)
      update_backgrounds()


def monitor_gsettings(mainloop):
  settings = Gio.Settings.new("org.gnome.desktop.background")

  def on_changed(settings, key):
    time.sleep(1)
    if key in ["picture-uri", "picture-uri-dark"]:
      current_bg = settings.get_string("picture-uri")
      current_bg_dark = settings.get_string("picture-uri-dark")
      if (current_bg == "'file:///usr/share/backgrounds/gnome/adwaita-l.jxl'"
        or current_bg_dark == "'file:///usr/share/backgrounds/gnome/adwaita-d.jxl'"):
        return
      if (current_bg == "'file:///home/mahdi/.config/background-light'"
        and current_bg_dark == "'file:///home/mahdi/.config/background-dark'"):
        return
      update_backgrounds()

  settings.connect("changed", on_changed)
  mainloop.run()


if __name__ == "__main__":
  update_backgrounds()

  observer = Observer()
  observer.schedule(BackgroundChangeHandler(), CONFIG_DIR, recursive=False)
  observer.start()

  mainloop = GLib.MainLoop()

  # Create a separate thread for monitoring gsettings
  gsettings_thread = threading.Thread(target=monitor_gsettings, args=(mainloop,))
  gsettings_thread.start()


  def signal_handler(sig, frame):
    print("Stopping...")
    observer.stop()
    mainloop.quit()  # Stop the GLib main loop
    gsettings_thread.join()  # Wait for the gsettings thread to terminate
    observer.join()  # Ensure observer stops before exiting
    print("Stopped successfully")


  # Catch SIGINT (Ctrl+C)
  signal.signal(signal.SIGINT, signal_handler)

  try:
    observer.join()
  except KeyboardInterrupt:
    pass
