import subprocess
import cv2
import numpy as np
import os
import time
from gi.repository import Gio
import argparse
import random
import string
from statistics import mean
from PIL import Image

parser = argparse.ArgumentParser(description='Adjust screen brightness.')
parser.add_argument('--once', action='store_true', help='Run the adjustment only once')
args = parser.parse_args()

run_id = ''.join(random.choices(string.ascii_letters + string.digits, k=5))

# Set the range for brightness values for the screen
MIN_SCREEN_BRIGHTNESS = 10  # Minimum screen brightness level (0-100)
MAX_SCREEN_BRIGHTNESS = 100  # Maximum screen brightness level (0-100)

# Set the brightness threshold for the room
MIN_ROOM_BRIGHTNESS = 30  # Minimum room brightness (can be adjusted)
MAX_ROOM_BRIGHTNESS = 200  # Maximum room brightness (can be adjusted)

# Temporary file to store the frame capture
FRAME_CAPTURE_FILE = f"/tmp/frame_capture{run_id}.jpg"


def get_color_scheme():
  return Gio.Settings.new("org.gnome.desktop.interface").get_string("color-scheme")


def capture_frame():
  """Capture a single frame from the webcam using ffmpeg."""
  try:
    # Capture a single frame from the webcam and save it as a jpeg file
    subprocess.run(['ffmpeg', '-y', '-f', 'video4linux2', '-i', '/dev/video0',
                    '-frames:v', '1', FRAME_CAPTURE_FILE], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
  except Exception as e:
    print(f"Error capturing frame: {e}")
    return False
  return True


def calculate_brightness():
  # Read the image
  img = cv2.imread(FRAME_CAPTURE_FILE)

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


def set_screen_brightness(brightness):
  """Set the screen brightness using brightnessctl."""
  brightness = max(MIN_SCREEN_BRIGHTNESS, min(MAX_SCREEN_BRIGHTNESS, brightness))

  subprocess.run(['brightnessctl', 'set', f"{format(brightness)}%"], check=True, stderr=subprocess.DEVNULL,
                 stdout=subprocess.DEVNULL)


def map_brightness(room_brightness):
  """Map the room brightness to a screen brightness value."""
  # Use different formulas for dark & light mode
  color = get_color_scheme()
  # Calculate the screen brightness based on room brightness
  if color == 'default':
    return int(3087726 + (20.65669 - 3087726) / (1 + (room_brightness / 7224040) ** 0.9656249))
  else:
    return int(103.9079 + (30.1668 - 103.9079) / (1 + (room_brightness / 18.80933) ** 3.021715))


def main():
  try:
    # Calibrate webcam
    if not args.once:
      subprocess.run(["ffmpeg", "-f", "v4l2", "-t", "8", "-i", "/dev/video0", f"/tmp/brightness_record{run_id}.mp4"],
                     stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)

    while True:
      # Capture a frame from the webcam
      if not capture_frame():
        break

      # Calculate room brightness
      room_brightness = calculate_brightness()
      print(f"The room brightness is: {room_brightness}")
      print(f"This is considered: {interpret_brightness(room_brightness)}")

      # Map room brightness to screen brightness
      screen_brightness = map_brightness(room_brightness)
      print(f"Setting screen brightness: {screen_brightness}")

      # Set screen brightness
      set_screen_brightness(screen_brightness)

      # Exit the while loop if --once is set
      if args.once:
        break

      # Wait for 8 minutes before the next adjustment
      time.sleep(480)

  finally:
    # Clean up temporary files
    if os.path.exists(FRAME_CAPTURE_FILE):
      os.remove(FRAME_CAPTURE_FILE)
    if os.path.exists(f"/tmp/brightness_record{run_id}.mp4"):
      os.remove(f"/tmp/brightness_record{run_id}.mp4")


if __name__ == "__main__":
  main()
