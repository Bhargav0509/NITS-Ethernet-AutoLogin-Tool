@echo off
:: Request Administrator Privileges
NET SESSION >nul 2>nul
if %errorLevel% neq 0 (
    echo Requesting Administrative Privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ---------------------------------------------------
echo   NIT Silchar Auto-Login - UNINSTALLER
echo ---------------------------------------------------
echo.
echo Removing background tasks and restoring default Windows settings...
echo.

echo [1/3] Stopping and removing background tasks...
schtasks /End /TN "Network Automation" >nul 2>&1
schtasks /Delete /TN "Network Automation" /F >nul 2>&1

echo [2/3] Deleting background scripts and saved credentials...
if exist "C:\Scripts" (
    rmdir /s /q "C:\Scripts"
)

echo [3/3] Restoring Windows default browser popup settings...
:: Delete the registry tweaks that blocked the Captive Portal popups
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet" /v "CaptivePortalBrowser" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\NetworkConnectivityStatusIndicator" /v "CaptivePortalBrowser" /f >nul 2>&1

:: Ensure Active Probing is enabled (Windows Default)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet" /v "EnableActiveProbing" /t REG_DWORD /d 1 /f >nul 2>&1

echo.
echo Uninstall Complete! Your PC has been completely restored to normal.
echo (If you want to test it, unplug your cable and plug it back in. 
echo The manual login popup will appear normally).
echo.
pause