# Screen Mirroring App - Quick User Guide

## Overview
This app allows you to share your phone's screen with another phone in real-time over Wi-Fi. No internet connection is required - both devices just need to be on the same local network.

## Quick Setup

### Step 1: Install the App
- Install the APK on both devices that you want to use
- Both devices must be connected to the same Wi-Fi network

### Step 2: Choose Your Role

#### Device A (Source/Sender):
1. Open the app and tap **"Share My Screen"**
2. Note the IP address shown at the bottom
3. Share this IP address with Device B

#### Device B (Viewer/Receiver):
1. Open the app and tap **"View Remote Screen"**
2. Enter the IP address from Device A
3. Tap **"Connect"**

### Step 3: Start Sharing
1. On Device A, wait until you see **"Client connected"**
2. Tap **"Start Sharing"**
3. Grant screen capture permission when prompted
4. Device B will now show Device A's screen in real-time

## Features

### For Source Device (Sender):
- Share your screen with one other device
- See connection status and connected client IP
- Start/stop sharing at any time
- Automatic reconnection if connection drops

### For Viewer Device (Receiver):
- View remote screen in real-time
- Tap screen to enter fullscreen mode
- Automatic reconnection when source comes back online
- Last frame is preserved if connection drops

## Troubleshooting

### "Cannot connect" errors:
- Make sure both devices are on the same Wi-Fi network
- Check that the IP address is entered correctly
- Try restarting both apps
- Ensure no firewall is blocking the connection

### Poor performance:
- Close other apps on both devices
- Move closer to your Wi-Fi router
- Restart the sharing session

### Permission issues:
- Allow all permissions when prompted
- On some devices, you may need to enable "Display over other apps"

## Technical Notes
- Streaming quality: 10-15 fps (optimized for battery life)
- Network port used: 8888 (TCP)
- Only works on Android devices
- Requires Android 5.0 (API 21) or higher

## Privacy & Security
- All communication happens locally (no internet required)
- No data is stored or logged
- Screen capture permission is temporary and revoked when app closes
- Direct device-to-device communication only
