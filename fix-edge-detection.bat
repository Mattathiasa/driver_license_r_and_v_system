@echo off
echo ========================================
echo  Fixing edge_detection Package
echo ========================================
echo.

set PACKAGE_PATH=%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\edge_detection-1.1.3\android

echo Looking for edge_detection package...
if not exist "%PACKAGE_PATH%\build.gradle" (
    echo [ERROR] Package not found at: %PACKAGE_PATH%
    echo.
    echo Please make sure you've run 'flutter pub get' first.
    pause
    exit /b 1
)

echo Found package at: %PACKAGE_PATH%
echo.
echo Creating backup...
copy "%PACKAGE_PATH%\build.gradle" "%PACKAGE_PATH%\build.gradle.backup" >nul

echo.
echo Checking AndroidManifest.xml for package name...
findstr /C:"package=" "%PACKAGE_PATH%\..\src\main\AndroidManifest.xml" > temp_package.txt
set /p PACKAGE_LINE=<temp_package.txt
del temp_package.txt

echo Found: %PACKAGE_LINE%
echo.

echo Restoring from backup first...
copy "%PACKAGE_PATH%\build.gradle.backup" "%PACKAGE_PATH%\build.gradle" >nul

echo Adding namespace to build.gradle...
powershell -Command "$content = Get-Content '%PACKAGE_PATH%\build.gradle' -Raw; if ($content -notmatch 'namespace') { $content = $content -replace '(android\s*\{)', ('$1' + [Environment]::NewLine + '    namespace ''com.sample.edgedetection''' + [Environment]::NewLine); Set-Content '%PACKAGE_PATH%\build.gradle' -Value $content -NoNewline; Write-Host 'Namespace added successfully!' } else { Write-Host 'Namespace already exists.' }"

echo.
echo ========================================
echo  Fix Applied!
echo ========================================
echo.
echo Now try building again:
echo   flutter clean
echo   flutter pub get
echo   flutter build apk --debug
echo.
pause
