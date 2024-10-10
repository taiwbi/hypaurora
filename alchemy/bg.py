import argparse
import os
import threading
import time

import cv2
import numpy as np
from PIL import Image
from gi.repository import Gio

HOME = os.path.expanduser("~")
CONFIG_DIR = os.path.join(HOME, ".config")
BG_FILE = os.path.join(CONFIG_DIR, "background")
BG_LIGHT_FILE = os.path.join(CONFIG_DIR, "background-light.jpg")
BG_DARK_FILE = os.path.join(CONFIG_DIR, "background-dark.jpg")

last_update_time = 0
settings = Gio.Settings.new("org.gnome.desktop.background")
lock = threading.Lock()

parser = argparse.ArgumentParser(description='Adjust screen brightness.')
parser.add_argument('--once', action='store_true', help='Run the adjustment only once')
args = parser.parse_args()


def calculate_brightness(image_path):
  # Read the image
  img = cv2.imread(image_path)

  if img is None:
    raise ValueError("Unable to read the image. Please check the file path.")

  # Convert the image to grayscale
  gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

  # Calculate the average pixel intensity
  average_brightness = np.mean(gray)

  # Normalize the brightness value to a 0-100 scale
  normalized_brightness = (average_brightness / 255) * 100

  return normalized_brightness


def interpret_brightness(brightness_value):
  if brightness_value < 20:
    return "Very Dark"
  elif brightness_value < 40:
    return "Dark"
  elif brightness_value < 60:
    return "Moderate"
  elif brightness_value < 80:
    return "Bright"
  else:
    return "Very Bright"


def get_gsettings_value(key):
  global settings

  settings = Gio.Settings.new("org.gnome.desktop.background")
  return settings.get_string(key)


def set_gsettings_value(key, value):
  global settings

  settings = Gio.Settings.new("org.gnome.desktop.background")
  settings.set_string(key, value)


def resize_image(img):
  img = img.convert("RGB")
  width, height = img.size
  aspect_ratio = width / height
  if aspect_ratio > 16 / 9:
    new_width = int(height * 16 / 9)
    img = img.crop(((width - new_width) // 2, 0, (width + new_width) // 2, height))
  elif aspect_ratio < 16 / 9:
    new_height = int(width * 9 / 16)
    img = img.crop((0, (height - new_height) // 2, width, (height + new_height) // 2))
  img = img.resize((1920, 1080))
  return img


def copy_current_background(destination: str):
  with Image.open(BG_FILE) as img:
    img = resize_image(img)
    img.save(destination, 'JPEG')


def create_var_background(x, save_to):
  with Image.open(BG_FILE) as img:
    img = resize_image(img)
    img = img.point(lambda p: min(p * x, 255))
    img.save(save_to, 'JPEG')


def update_backgrounds():
  global last_update_time, settings

  if time.time() - last_update_time < 3:
    last_update_time = time.time()
    return

  current_bg = settings.get_string("picture-uri")
  current_bg_dark = settings.get_string("picture-uri-dark")
  if current_bg != current_bg_dark:
    return  # Return if background already has variations

  last_update_time = time.time()

  print(f"Updating background...")

  background_brightness = calculate_brightness(BG_FILE)
  print(f"The image brightness is: {background_brightness}")
  print(f"This is considered: {interpret_brightness(background_brightness)}")

  if background_brightness < 20:
    copy_current_background(BG_DARK_FILE)
    create_var_background(1.5, BG_LIGHT_FILE)
  elif background_brightness < 40:
    create_var_background(0.8, BG_DARK_FILE)
    create_var_background(1.35, BG_LIGHT_FILE)
  elif background_brightness < 60:
    create_var_background(0.77, BG_DARK_FILE)
    create_var_background(1.2, BG_LIGHT_FILE)
  elif background_brightness < 80:
    create_var_background(0.75, BG_DARK_FILE)
    create_var_background(1.1, BG_LIGHT_FILE)
  else:
    copy_current_background(BG_LIGHT_FILE)
    create_var_background(0.5, BG_DARK_FILE)

  set_gsettings_value("picture-uri", f"file://{BG_LIGHT_FILE}")
  set_gsettings_value("picture-uri-dark", f"file://{BG_DARK_FILE}")
  print("Background Updated")
  last_update_time = time.time()


if __name__ == "__main__":
  while True:
    update_backgrounds()
    if args.once:
      break
    # Wait for 8 minutes before checking for new background
    time.sleep(480)
