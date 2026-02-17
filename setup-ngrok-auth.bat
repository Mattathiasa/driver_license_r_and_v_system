@echo off
echo ========================================
echo  Ngrok Authentication Setup
echo ========================================
echo.
echo Ngrok requires a free account to use.
echo.
echo Step 1: Sign up for a free account
echo   Visit: https://dashboard.ngrok.com/signup
echo.
echo Step 2: Get your authtoken
echo   After signing up, visit: https://dashboard.ngrok.com/get-started/your-authtoken
echo   Copy your authtoken from the page
echo.
echo Step 3: Enter your authtoken below
echo.
set /p AUTHTOKEN="Paste your authtoken here and press Enter: "

if "%AUTHTOKEN%"=="" (
    echo [ERROR] No authtoken provided!
    pause
    exit /b 1
)

echo.
echo [INFO] Configuring ngrok with your authtoken...

REM Set ngrok path
set NGROK_PATH=%~dp0ngrok.exe

REM Check if ngrok exists in project folder
if not exist "%NGROK_PATH%" (
    where ngrok >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        set NGROK_PATH=ngrok
    ) else (
        echo [ERROR] ngrok.exe not found!
        echo Please run run-with-ngrok.bat first to extract ngrok.
        pause
        exit /b 1
    )
)

REM Add authtoken
"%NGROK_PATH%" config add-authtoken %AUTHTOKEN%

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo  SUCCESS! Ngrok is now authenticated!
    echo ========================================
    echo.
    echo You can now run: run-with-ngrok.bat
    echo.
) else (
    echo.
    echo [ERROR] Failed to configure authtoken.
    echo Please check if the token is correct.
    echo.
)

pause
