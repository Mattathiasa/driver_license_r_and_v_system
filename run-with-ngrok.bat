@echo off
echo ========================================
echo  Driver License System - Ngrok Setup
echo ========================================
echo.

REM Set ngrok path
set NGROK_PATH=%~dp0ngrok.exe

REM Check if ngrok exists in project folder
if exist "%NGROK_PATH%" (
    echo [INFO] Using ngrok from project folder
    goto :start_services
)

REM Check if ngrok is in PATH
where ngrok >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    set NGROK_PATH=ngrok
    echo [INFO] Using ngrok from PATH
    goto :start_services
)

REM Check if ngrok zip exists in Downloads
if exist "%USERPROFILE%\Downloads\ngrok-v3-stable-windows-amd64.zip" (
    echo [INFO] Found ngrok zip file in Downloads. Extracting...
    powershell -Command "Expand-Archive -Path '%USERPROFILE%\Downloads\ngrok-v3-stable-windows-amd64.zip' -DestinationPath '%~dp0' -Force"
    if exist "%NGROK_PATH%" (
        echo [SUCCESS] Ngrok extracted successfully!
        goto :start_services
    )
)

echo [ERROR] ngrok not found!
echo.
echo Please do ONE of the following:
echo   1. Extract ngrok.exe from the zip file in your Downloads folder
echo   2. Download ngrok from https://ngrok.com/download
echo   3. Add ngrok to your system PATH
echo.
pause
exit /b 1

:start_services

echo [1/3] Starting .NET API on port 5182...
echo.

REM Start the .NET API in a new window
start "Driver License API" cmd /k "cd /d %~dp0backend-dotnet\DAFTech.DriverLicenseSystem.Api && dotnet run"

echo Waiting for API to start (15 seconds)...
timeout /t 15 /nobreak >nul

echo.
echo [2/3] Starting ngrok tunnel...
echo.

REM Start ngrok in a new window
start "Ngrok Tunnel" cmd /k "%NGROK_PATH% http 5182 --log=stdout"

echo.
echo [3/3] Setup complete!
echo.
echo ========================================
echo  Your API is now publicly accessible!
echo ========================================
echo.
echo Two windows have been opened:
echo   1. Driver License API - Your .NET backend
echo   2. Ngrok Tunnel - Public URL tunnel
echo.
echo Check the Ngrok window for your public URL.
echo It will look like: https://xxxx-xx-xx-xx-xx.ngrok-free.app
echo.
echo IMPORTANT: Update your Flutter app's API URL to use the ngrok URL!
echo.
echo Press any key to exit this window (API and ngrok will keep running)...
pause >nul
