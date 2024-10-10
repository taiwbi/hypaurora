import time
import subprocess
from datetime import datetime, timedelta

def send_notification(icon, title, message):
  subprocess.run(['notify-send', '-a', 'Alchemy', '-i', icon, title, message])

def main():
  interval = 20 * 60 # 20 minutes in seconds

  print("Eye rest reminder started. Press Ctrl+C to exit.")

  while True:
    next_reminder = datetime.now() + timedelta(seconds=interval)
    print(f"Next reminder at: {next_reminder.strftime('%H:%M:%S')}")
    time.sleep(interval)
    send_notification("document-open-recent-symbolic", "Eye Rest Reminder", "Take a 20-second break and look at something 20 feet away!")

if __name__ == "__main__":
  main()
