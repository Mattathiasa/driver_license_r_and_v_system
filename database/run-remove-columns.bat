@echo off
echo =====================================================
echo Removing DriverName, ExpiryDate, and Notes columns
echo from VerificationLogs table
echo =====================================================
echo.

sqlcmd -S localhost -d DriverLicenseDB -E -i remove-verification-log-columns.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo =====================================================
    echo Columns removed successfully!
    echo =====================================================
) else (
    echo.
    echo =====================================================
    echo Error occurred while removing columns
    echo =====================================================
)

echo.
pause
