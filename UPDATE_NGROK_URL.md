# How to Update Your Ngrok URL in Flutter

## Step 1: Get Your Ngrok URL

Look at the "Ngrok Tunnel" window that opened when you ran `run-with-ngrok.bat`.

Find the line that says:
```
Forwarding    https://xxxx-xx-xx-xx-xx.ngrok-free.app -> http://localhost:5182
```

Copy the HTTPS URL (the part before the arrow). For example:
```
https://1a2b-34-56-78-90.ngrok-free.app
```

## Step 2: Update Flutter Config

Open: `mobile-flutter/lib/config/api_config.dart`

Find this line:
```dart
static const String ngrokUrl = 'https://YOUR-NGROK-URL-HERE.ngrok-free.app';
```

Replace it with your actual ngrok URL:
```dart
static const String ngrokUrl = 'https://1a2b-34-56-78-90.ngrok-free.app';
```

**IMPORTANT:** 
- Do NOT include `/api` at the end
- Do NOT include a trailing slash
- Use HTTPS (not HTTP)

## Step 3: Rebuild Your App

The environment is already set to 'ngrok', so just rebuild:

```cmd
cd mobile-flutter
flutter run
```

Or if the app is already running, hot restart it (press 'R' in the terminal).

## Quick Reference

Your current config file location:
```
mobile-flutter/lib/config/api_config.dart
```

Current environment setting:
```dart
static const String environment = 'ngrok';
```

## Switching Back to USB/Local

If you want to switch back to local development:

1. Change environment to 'usb':
   ```dart
   static const String environment = 'usb';
   ```

2. Hot restart your app

## Notes

- The ngrok URL changes every time you restart ngrok (unless you have a paid plan)
- Remember to update the URL in Flutter each time you restart ngrok
- You can test the URL in a browser: `https://your-ngrok-url.ngrok-free.app/swagger`
