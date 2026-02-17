@echo off
echo ========================================
echo  Restarting API and Ngrok
echo ========================================
echo.

echo [1/3] Stopping existing processes...
echo.

REM Kill any existing dotnet processes running the API
taskkill /F /IM dotnet.exe /FI "WINDOWTITLE eq Driver License API*" 2>nul
if %ERRORLEVEL% EQU 0 (
    echo Stopped .NET API
) else (
    echo No running .NET API found
)

REM Kill any existing ngrok processes
taskkill /F /IM ngrok.exe 2>nul
if %ERRORLEVEL% EQU 0 (
    echo Stopped ngrok
) else (
    echo No running ngrok found
)

echo.
echo Waiting 3 seconds for processes to fully stop...
timeout /t 3 /nobreak >nul

echo.
echo [2/3] Starting .NET API...
echo.

REM Start the .NET API in a new window
start "Driver License API" cmd /k "cd /d %~dp0backend-dotnet\DAFTech.DriverLicenseSystem.Api && dotnet run"

echo Waiting for API to start (15 seconds)...
timeout /t 15 /nobreak >nul

echo.
echo [3/3] Starting ngrok tunnel...
echo.

REM Set ngrok path
set NGROK_PATH=%~dp0ngrok.exe

REM Check if ngrok exists
if not exist "%NGROK_PATH%" (
    where ngrok >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        set NGROK_PATH=ngrok
    ) else (
        echo [ERROR] ngrok.exe not found!
        pause
        exit /b 1
    )
)

REM Start ngrok in a new window
start "Ngrok Tunnel" cmd /k "%NGROK_PATH% http 5182 --log=stdout"

echo.
echo ========================================
echo  Restart Complete!
echo ========================================
echo.
echo Your API is now running with ngrok.
echo Check the Ngrok window for your public URL.
echo.
echo URL should be: https://uncontortive-atheistically-sebastian.ngrok-free.dev
echo.
pause
