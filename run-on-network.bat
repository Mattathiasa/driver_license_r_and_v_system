@echo off
echo ========================================
echo  Driver License System - Local Network
echo ========================================
echo.

echo [1/2] Getting your local IP address...
echo.

for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set IP=%%a
    goto :found_ip
)

:found_ip
set IP=%IP:~1%

echo Your local IP address: %IP%
echo.
echo [2/2] Starting .NET API...
echo.

cd /d "%~dp0backend-dotnet\DAFTech.DriverLicenseSystem.Api"

echo ========================================
echo  API is now running!
echo ========================================
echo.
echo Local access: http://localhost:5182
echo Network access: http://%IP%:5182
echo.
echo Use the network URL in your Flutter app to access from your phone.
echo Make sure your phone is on the same WiFi network!
echo.
echo Press Ctrl+C to stop the server.
echo ========================================
echo.

dotnet run
