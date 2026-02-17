# Phone Setup Guide - Connect to Local .NET Backend

## Overview
This guide explains how to connect your physical phone to the .NET backend running on your computer over the same network.

## Prerequisites
- Your computer and phone must be on the same WiFi network
- .NET backend must be configured to accept external connections
- Windows Firewall must allow the connection

## Step 1: Find Your Computer's IP Address

### On Windows:
1. Open Command Prompt (cmd)
2. Run: `ipconfig`
3. Look for "IPv4 Address" under your active network adapter (usually WiFi or Ethernet)
4. Example: `192.168.1.100`

```cmd
ipconfig
```

Look for something like:
```
Wireless LAN adapter Wi-Fi:
   IPv4 Address. . . . . . . . . . . : 192.168.1.100
```

## Step 2: Configure .NET Backend to Accept External Connections

### Update `appsettings.json`

Open `backend-dotnet/DAFTech.DriverLicenseSystem.Api/appsettings.json` and ensure it has:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Urls": "http://0.0.0.0:5000;https://0.0.0.0:5001"
}
```

### Update `Program.cs` (if needed)

Ensure your `Program.cs` has:

```csharp
var builder = WebApplication.CreateBuilder(args);

// Configure Kestrel to listen on all network interfaces
builder.WebHost.ConfigureKestrel(options =>
{
    options.ListenAnyIP(5000); // HTTP
    options.ListenAnyIP(5001, listenOptions =>
    {
        listenOptions.UseHttps(); // HTTPS (optional)
    });
});
```

Or simpler approach in `Program.cs`:

```csharp
builder.WebHost.UseUrls("http://0.0.0.0:5000");
```

## Step 3: Configure Windows Firewall

### Option A: Using Command Prompt (Recommended)

Run Command Prompt as Administrator and execute:

```cmd
netsh advfirewall firewall add rule name="ASP.NET Core Web API" dir=in action=allow protocol=TCP localport=5000
```

### Option B: Using Windows Defender Firewall GUI

1. Open "Windows Defender Firewall with Advanced Security"
2. Click "Inbound Rules" → "New Rule"
3. Select "Port" → Next
4. Select "TCP" and enter port `5000` → Next
5. Select "Allow the connection" → Next
6. Check all profiles (Domain, Private, Public) → Next
7. Name it "ASP.NET Core Web API" → Finish

## Step 4: Update Flutter App Configuration

### Update `api_service.dart`

Open `mobile-flutter/lib/services/api_service.dart` and update the base URL:

```dart
class ApiService {
  // Replace with your computer's IP address
  static const String baseUrl = 'http://192.168.1.100:5000/api';
  
  // For Android Emulator use: 'http://10.0.2.2:5000/api'
  // For iOS Simulator use: 'http://localhost:5000/api'
  // For Physical Device use: 'http://YOUR_COMPUTER_IP:5000/api'
```

**Important:** Replace `192.168.1.100` with YOUR computer's actual IP address from Step 1.

## Step 5: Update Android Network Security Configuration

### Create/Update `android/app/src/main/res/xml/network_security_config.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">192.168.1.100</domain>
        <domain includeSubdomains="true">localhost</domain>
        <domain includeSubdomains="true">10.0.2.2</domain>
    </domain-config>
</network-security-config>
```

### Update `AndroidManifest.xml`

Ensure `android/app/src/main/AndroidManifest.xml` has:

```xml
<application
    android:label="DAFTech Driver License"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:networkSecurityConfig="@xml/network_security_config"
    android:usesCleartextTraffic="true">
```

## Step 6: Start the Backend

### Run the .NET Backend

```cmd
cd backend-dotnet/DAFTech.DriverLicenseSystem.Api
dotnet run
```

You should see:
```
Now listening on: http://0.0.0.0:5000
Application started. Press Ctrl+C to shut down.
```

## Step 7: Test the Connection

### From Your Computer's Browser

Open: `http://localhost:5000/api/auth/health` or `http://192.168.1.100:5000/api/auth/health`

### From Your Phone's Browser

Open: `http://192.168.1.100:5000/api/auth/health`

You should see a response from the API.

## Step 8: Build and Install Flutter App on Phone

### Build the APK

```cmd
cd mobile-flutter
flutter build apk --debug
```

The APK will be at: `mobile-flutter/build/app/outputs/flutter-apk/app-debug.apk`

### Install on Phone

**Option A: USB Cable**
1. Enable USB Debugging on your phone
2. Connect phone via USB
3. Run: `flutter install`

**Option B: Transfer APK**
1. Copy `app-debug.apk` to your phone (via USB, email, cloud storage)
2. Open the APK on your phone
3. Allow installation from unknown sources if prompted
4. Install the app

## Troubleshooting

### Issue: "Connection Refused" or "Network Error"

**Solutions:**
1. Verify both devices are on the same WiFi network
2. Check firewall settings (Step 3)
3. Verify the IP address is correct
4. Try disabling Windows Firewall temporarily to test
5. Ensure backend is running and listening on `0.0.0.0:5000`

### Issue: "Unable to connect to localhost"

**Solution:**
- Don't use `localhost` on physical devices
- Use your computer's actual IP address (e.g., `192.168.1.100`)

### Issue: "Cleartext HTTP traffic not permitted"

**Solution:**
- Ensure network security config is properly set (Step 5)
- Verify `usesCleartextTraffic="true"` in AndroidManifest.xml

### Issue: Backend not accessible from phone

**Check:**
```cmd
# On your computer, verify backend is listening on all interfaces
netstat -an | findstr :5000
```

Should show: `0.0.0.0:5000` (not `127.0.0.1:5000`)

### Issue: IP Address keeps changing

**Solution:**
- Set a static IP for your computer in router settings
- Or use a dynamic DNS service
- Or update the app each time IP changes

## Quick Reference

### Computer IP Address
```cmd
ipconfig
```

### Add Firewall Rule
```cmd
netsh advfirewall firewall add rule name="ASP.NET Core Web API" dir=in action=allow protocol=TCP localport=5000
```

### Run Backend
```cmd
cd backend-dotnet/DAFTech.DriverLicenseSystem.Api
dotnet run --urls "http://0.0.0.0:5000"
```

### Build Flutter APK
```cmd
cd mobile-flutter
flutter build apk --debug
```

### Install on Connected Phone
```cmd
flutter install
```

## Production Deployment (Optional)

For production deployment over the internet:

1. **Use HTTPS** - Configure SSL certificates
2. **Deploy to Cloud** - Azure, AWS, or other cloud providers
3. **Use Domain Name** - Instead of IP address
4. **Update API URL** - Point to production domain
5. **Build Release APK** - `flutter build apk --release`

## Security Notes

⚠️ **Important:**
- The setup above is for development/testing only
- Don't expose your development server to the internet
- Use HTTPS in production
- Implement proper authentication and authorization
- Don't commit IP addresses or sensitive data to Git

## Summary

1. Find your computer's IP address (`ipconfig`)
2. Configure backend to listen on `0.0.0.0:5000`
3. Add Windows Firewall rule for port 5000
4. Update Flutter app with your computer's IP
5. Configure Android network security
6. Build and install APK on phone
7. Test the connection

Your phone should now be able to connect to your local .NET backend!
