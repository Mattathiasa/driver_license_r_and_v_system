# Quick Phone Setup Guide

## 🚀 Quick Start (3 Steps)

### Step 1: Find Your Computer's IP Address

**Windows:**
```cmd
ipconfig
```
Look for "IPv4 Address" (e.g., `192.168.1.100`)

### Step 2: Update Flutter App Configuration

Open `mobile-flutter/lib/config/api_config.dart` and update:

```dart
static const String environment = 'physical';  // Change from 'usb' to 'physical'
static const String physicalDeviceIP = '192.168.1.100';  // YOUR IP HERE
```

### Step 3: Configure Backend & Firewall

**A. Add Firewall Rule (Run as Administrator):**
```cmd
netsh advfirewall firewall add rule name="ASP.NET Core Web API" dir=in action=allow protocol=TCP localport:5182
```

**B. Run Backend:**
```cmd
cd backend-dotnet/DAFTech.DriverLicenseSystem.Api
dotnet run --urls "http://0.0.0.0:5182"
```

### Step 4: Build & Install App

**Build APK:**
```cmd
cd mobile-flutter
flutter build apk --debug
```

**Install on Phone:**
- Copy `mobile-flutter/build/app/outputs/flutter-apk/app-debug.apk` to your phone
- Install it (allow unknown sources if needed)

## ✅ Test Connection

**From phone browser, open:**
```
http://YOUR_IP:5182/swagger
```

Replace `YOUR_IP` with your computer's IP address.

## 🔧 Alternative: USB Debugging (Easier!)

If WiFi doesn't work, use USB:

1. **Keep config as:**
   ```dart
   static const String environment = 'usb';
   ```

2. **Connect phone via USB**

3. **Enable USB Debugging** on phone

4. **Run port forwarding:**
   ```cmd
   adb reverse tcp:5182 tcp:5182
   ```

5. **Run backend normally:**
   ```cmd
   dotnet run
   ```

6. **Install app:**
   ```cmd
   flutter install
   ```

## 📱 Configuration Options

Your app supports 4 connection modes in `api_config.dart`:

| Mode | Use Case | IP/URL |
|------|----------|--------|
| `emulator` | Android Emulator | `10.0.2.2:5182` |
| `ios` | iOS Simulator | `localhost:5182` |
| `physical` | Phone via WiFi | `YOUR_IP:5182` |
| `usb` | Phone via USB | `localhost:5182` (with adb reverse) |

## 🐛 Troubleshooting

### "Connection Refused"
- ✅ Check both devices on same WiFi
- ✅ Verify firewall rule added
- ✅ Confirm backend running on `0.0.0.0:5182`

### "Network Error"
- ✅ Update IP in `api_config.dart`
- ✅ Test from phone browser: `http://YOUR_IP:5182/swagger`

### Backend not accessible
```cmd
# Verify backend listening on all interfaces
netstat -an | findstr :5182
```
Should show `0.0.0.0:5182` (not `127.0.0.1:5182`)

## 📚 Full Documentation

See `docs/PHONE_SETUP_GUIDE.md` for detailed instructions.
