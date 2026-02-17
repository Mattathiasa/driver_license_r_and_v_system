@echo off
echo ========================================
echo DAFTech Phone Connection Setup
echo ========================================
echo.

echo Step 1: Finding your computer's IP address...
echo.
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set IP=%%a
    set IP=!IP:~1!
    echo Found IP Address: !IP!
    goto :found
)
:found
echo.

echo Step 2: Adding Windows Firewall rule...
echo (This requires Administrator privileges)
echo.
netsh advfirewall firewall delete rule name="ASP.NET Core Web API" >nul 2>&1
netsh advfirewall firewall add rule name="ASP.NET Core Web API" dir=in action=allow protocol=TCP localport=5182
if %errorlevel% equ 0 (
    echo ✓ Firewall rule added successfully!
) else (
    echo ✗ Failed to add firewall rule. Please run as Administrator.
)
echo.

echo Step 3: Configuration Instructions
echo ========================================
echo.
echo To connect your phone via WiFi:
echo.
echo 1. Open: mobile-flutter\lib\config\api_config.dart
echo.
echo 2. Change these lines:
echo    static const String environment = 'physical';
echo    static const String physicalDeviceIP = '%IP%';
echo.
echo 3. Build and install the app:
echo    cd mobile-flutter
echo    flutter build apk --debug
echo.
echo 4. Copy app-debug.apk to your phone and install
echo.
echo ========================================
echo.
echo To connect your phone via USB (easier):
echo.
echo 1. Keep environment = 'usb' in api_config.dart
echo.
echo 2. Connect phone via USB and enable USB debugging
echo.
echo 3. Run: adb reverse tcp:5182 tcp:5182
echo.
echo 4. Run: flutter install
echo.
echo ========================================
echo.
echo Your computer's IP: %IP%
echo Backend URL: http://%IP%:5182
echo Test URL: http://%IP%:5182/swagger
echo.
echo Press any key to start the backend...
pause >nul

echo.
echo Starting .NET Backend...
cd backend-dotnet\DAFTech.DriverLicenseSystem.Api
dotnet run
