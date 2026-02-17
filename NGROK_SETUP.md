# Ngrok Setup Guide for Driver License System

## Quick Start

### First Time Setup (Required)

1. **Authenticate ngrok (one-time setup):**
   ```cmd
   setup-ngrok-auth.bat
   ```
   - This will open your browser to sign up for a free ngrok account
   - Copy your authtoken from the dashboard
   - Paste it when prompted in the script

### Running Your API with Ngrok

2. **Run the setup script:**
   ```cmd
   run-with-ngrok.bat
   ```

3. **Get your public URL:**
   - Check the "Ngrok Tunnel" window that opens
   - Look for the "Forwarding" line, e.g., `https://abcd-1234.ngrok-free.app -> http://localhost:5182`
   - Copy the HTTPS URL (the part before the arrow)

4. **Update your Flutter app:**
   - Open `mobile-flutter/lib/services/api_service.dart` (or wherever your API base URL is defined)
   - Replace `http://localhost:5182` with your ngrok URL
   - Example: `https://abcd-1234.ngrok-free.app`

## What the Script Does

1. Checks if ngrok is installed and accessible
2. Starts your .NET API on port 5182
3. Creates an ngrok tunnel to expose it publicly
4. Opens two command windows:
   - One for the .NET API
   - One for the ngrok tunnel

## Manual Setup (Alternative)

If you prefer to run commands manually:

### Step 1: Start the .NET API
```cmd
cd backend-dotnet\DAFTech.DriverLicenseSystem.Api
dotnet run
```

### Step 2: Start ngrok (in a new terminal)
```cmd
ngrok http 5182
```

### Step 3: Copy the public URL
Look for the "Forwarding" line in the ngrok terminal output.

## Ngrok Authentication (REQUIRED)

Ngrok now requires authentication for all users (free):

### Automated Setup (Recommended)
```cmd
setup-ngrok-auth.bat
```

### Manual Setup
1. Sign up at https://dashboard.ngrok.com/signup
2. Get your auth token from https://dashboard.ngrok.com/get-started/your-authtoken
3. Run:
   ```cmd
   ngrok config add-authtoken YOUR_AUTH_TOKEN
   ```

Benefits of free account:
- Unlimited tunnels
- HTTPS support
- Stable connections
- Web inspection interface at http://localhost:4040

## Troubleshooting

### "ngrok is not found in PATH"
- Find where ngrok.exe is installed (usually in Downloads or Program Files)
- Add that folder to your system PATH:
  1. Search "Environment Variables" in Windows
  2. Edit "Path" under System Variables
  3. Add the folder containing ngrok.exe
  4. Restart your terminal

### API not starting
- Make sure SQL Server is running
- Check if port 5182 is already in use
- Verify database connection in `appsettings.json`

### Ngrok tunnel not working
- Check if you're on a restricted network (some corporate networks block ngrok)
- Try authenticating with ngrok (see above)
- Restart ngrok if the tunnel expires

### Flutter app can't connect
- Make sure you're using HTTPS (not HTTP) from the ngrok URL
- Update the API base URL in your Flutter app
- Rebuild/restart your Flutter app after changing the URL
- Check CORS settings in your .NET API if you get CORS errors

## Current Configuration

- **API Port:** 5182
- **API URL (local):** http://localhost:5182
- **API URL (ngrok):** Will be generated when you run ngrok

## Stopping the Services

To stop everything:
1. Close the "Driver License API" window (or press Ctrl+C)
2. Close the "Ngrok Tunnel" window (or press Ctrl+C)

## Notes

- The ngrok URL changes each time you restart ngrok (unless you have a paid plan with reserved domains)
- Remember to update your Flutter app's API URL whenever the ngrok URL changes
- Don't commit the ngrok URL to your repository - it's temporary
- For production, use a proper hosting service (Azure, AWS, etc.)
