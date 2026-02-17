# Troubleshooting: "Unexpected character <!DOCTYPE html>"

## Error Message

```
Login Failed: Format Exception: Unexpected character (at character 1)
<!DOCTYPE html>
```

## What This Means

The mobile app is receiving an **HTML page** instead of **JSON data** from the API. This typically happens when:

1. ❌ The .NET API is not running
2. ❌ The ngrok tunnel is down
3. ❌ Wrong API URL configured
4. ❌ Ngrok browser warning page is being returned

---

## Quick Fix Checklist

### ✅ Step 1: Check if API is Running

**Open Command Prompt:**
```cmd
cd C:\Users\matta\Desktop\DAFTech\backend-dotnet\DAFTech.DriverLicenseSystem.Api
dotnet run
```

**Look for:**
```
Now listening on: http://localhost:5182
Application started. Press Ctrl+C to shut down.
```

If you see errors, the API is not running properly.

### ✅ Step 2: Check Ngrok Tunnel

**Open another Command Prompt:**
```cmd
cd C:\Users\matta\Desktop\DAFTech
restart-api-with-ngrok.bat
```

**Look for:**
```
Forwarding  https://xxxxx.ngrok-free.app -> http://localhost:5182
```

Copy the `https://xxxxx.ngrok-free.app` URL.

### ✅ Step 3: Verify API URL in Flutter

**Check the URL:**
```cmd
cd C:\Users\matta\Desktop\DAFTech\mobile-flutter
type lib\config\api_config.dart
```

**Should show:**
```dart
class ApiConfig {
  static const String baseUrl = 'https://xxxxx.ngrok-free.app/api';
}
```

**If URL is wrong, update it:**
1. Open `mobile-flutter/lib/config/api_config.dart`
2. Replace with your ngrok URL
3. Save file
4. Restart Flutter app

### ✅ Step 4: Test API Manually

**Test with curl:**
```cmd
curl -X POST https://your-ngrok-url.ngrok-free.app/api/Auth/login ^
  -H "Content-Type: application/json" ^
  -H "ngrok-skip-browser-warning: true" ^
  -d "{\"username\":\"admin\",\"password\":\"Admin@123\"}"
```

**Expected response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGc...",
    "expiresAt": "2024-02-18T10:00:00",
    "userId": 1,
    "username": "admin"
  }
}
```

**If you get HTML:**
- API is not running
- Wrong URL
- Ngrok tunnel is down

---

## Common Causes & Solutions

### Cause 1: API Not Running

**Symptoms:**
- Error immediately on login
- No API console output
- Can't access http://localhost:5182

**Solution:**
```cmd
cd C:\Users\matta\Desktop\DAFTech
restart-api-with-ngrok.bat
```

Wait for:
- API to start on port 5182
- Ngrok tunnel to connect
- Both running successfully

### Cause 2: Ngrok Tunnel Down

**Symptoms:**
- API running locally (http://localhost:5182 works)
- Ngrok URL returns HTML error page
- "Tunnel not found" message

**Solution:**
```cmd
# Stop ngrok (Ctrl+C)
# Restart with:
cd C:\Users\matta\Desktop\DAFTech
run-with-ngrok.bat
```

**Get new URL:**
- Look for: `https://xxxxx.ngrok-free.app`
- Update Flutter config with new URL
- Restart Flutter app

### Cause 3: Wrong API URL

**Symptoms:**
- API and ngrok both running
- Still getting HTML error
- URL in Flutter doesn't match ngrok URL

**Solution:**
1. Check ngrok console for current URL
2. Open `mobile-flutter/lib/config/api_config.dart`
3. Update `baseUrl` with correct ngrok URL
4. Must include `/api` at the end
5. Save and restart Flutter app

**Correct format:**
```dart
static const String baseUrl = 'https://xxxxx.ngrok-free.app/api';
//                                                            ^^^^
//                                                         Must have /api
```

### Cause 4: Ngrok Browser Warning

**Symptoms:**
- API running
- Ngrok tunnel active
- Still getting HTML

**Solution:**
The app already includes the `ngrok-skip-browser-warning` header, but verify:

1. Open `mobile-flutter/lib/services/api_service.dart`
2. Check `getHeaders()` method includes:
   ```dart
   'ngrok-skip-browser-warning': 'true',
   ```
3. If missing, add it and restart app

### Cause 5: Firewall Blocking

**Symptoms:**
- Everything configured correctly
- Still can't connect
- Timeout errors

**Solution:**
```cmd
# Allow .NET through firewall
netsh advfirewall firewall add rule name="DotNet API" dir=in action=allow protocol=TCP localport=5182

# Or temporarily disable firewall (not recommended)
```

---

## Step-by-Step Restart Procedure

If nothing works, follow this complete restart:

### 1. Stop Everything
```cmd
# Press Ctrl+C in all command prompts
# Close all terminals
```

### 2. Start API
```cmd
cd C:\Users\matta\Desktop\DAFTech\backend-dotnet\DAFTech.DriverLicenseSystem.Api
dotnet run
```

**Wait for:** `Now listening on: http://localhost:5182`

### 3. Start Ngrok (New Terminal)
```cmd
cd C:\Users\matta\Desktop\DAFTech
ngrok http 5182
```

**Copy the URL:** `https://xxxxx.ngrok-free.app`

### 4. Update Flutter Config
```cmd
cd C:\Users\matta\Desktop\DAFTech\mobile-flutter
notepad lib\config\api_config.dart
```

**Update:**
```dart
static const String baseUrl = 'https://xxxxx.ngrok-free.app/api';
```

Save and close.

### 5. Restart Flutter App
```cmd
# Stop app (if running)
# Then:
flutter run
```

### 6. Test Login
- Username: `admin`
- Password: `Admin@123`

---

## Verification Steps

### Test 1: API Health Check
```cmd
curl http://localhost:5182/api/health
```

**Expected:** Some response (not HTML)

### Test 2: Ngrok Tunnel
```cmd
curl https://your-ngrok-url.ngrok-free.app/api/health ^
  -H "ngrok-skip-browser-warning: true"
```

**Expected:** Same response as Test 1

### Test 3: Login Endpoint
```cmd
curl -X POST https://your-ngrok-url.ngrok-free.app/api/Auth/login ^
  -H "Content-Type: application/json" ^
  -H "ngrok-skip-browser-warning: true" ^
  -d "{\"username\":\"admin\",\"password\":\"Admin@123\"}"
```

**Expected:** JSON with token

### Test 4: Flutter App
- Open app
- Enter credentials
- Tap login
- Should succeed

---

## Debug Output

The app now shows better error messages:

**Before:**
```
Login Failed: Format Exception: Unexpected character...
```

**After:**
```
Login Failed: Received HTML instead of JSON. This usually means:
1. API is not running
2. Wrong API URL
3. Ngrok tunnel is down
Current URL: https://xxxxx.ngrok-free.app/api
```

This helps identify the exact problem.

---

## Prevention

### Use the Restart Script

Instead of manually starting everything:

```cmd
cd C:\Users\matta\Desktop\DAFTech
restart-api-with-ngrok.bat
```

This script:
1. Stops any running API
2. Starts API on port 5182
3. Starts ngrok tunnel
4. Shows the ngrok URL

### Check Before Testing

Before testing the app:
1. ✅ API console shows "listening on port 5182"
2. ✅ Ngrok console shows "Forwarding https://..."
3. ✅ Flutter config has correct ngrok URL
4. ✅ Flutter app restarted after config change

---

## Still Not Working?

### Check Logs

**API Logs:**
```cmd
# In API terminal, look for errors
# Common issues:
# - Database connection failed
# - Port already in use
# - Missing dependencies
```

**Flutter Logs:**
```cmd
# In Flutter terminal, look for:
flutter run --verbose
# Shows detailed HTTP requests and responses
```

### Network Issues

**Test connectivity:**
```cmd
# Can you reach ngrok?
ping xxxxx.ngrok-free.app

# Can you reach localhost?
curl http://localhost:5182
```

### Database Issues

**Check database:**
```cmd
sqlcmd -S localhost -E -Q "SELECT COUNT(*) FROM DriverLicenseDB.dbo.Users"
```

**Expected:** Number of users (at least 3)

---

## Quick Reference

| Issue | Solution |
|-------|----------|
| API not running | `dotnet run` in API folder |
| Ngrok down | `ngrok http 5182` |
| Wrong URL | Update `api_config.dart` |
| HTML response | Check all above |
| Timeout | Check firewall |
| 401 Unauthorized | Wrong credentials |
| 404 Not Found | Wrong endpoint URL |

---

## Contact Support

If still having issues:
1. Check API is running: http://localhost:5182
2. Check ngrok URL is correct
3. Verify Flutter config matches ngrok URL
4. Test with curl commands above
5. Check error logs in both API and Flutter

---

**Last Updated**: February 17, 2024
