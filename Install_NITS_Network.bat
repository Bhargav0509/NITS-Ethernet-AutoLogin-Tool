<# :
@echo off
:: Request Administrator Privileges
NET SESSION >nul 2>nul
if %errorLevel% neq 0 (
    echo Requesting Administrative Privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
:: Execute the PowerShell block below
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content '%~f0' -Raw) -replace '(?s)<#.*#>','')"
pause
exit /b
#>

Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host " NIT Silchar Auto-Login Network Tool" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host ""

# Create the directory first so we can store the config file
$Dir = "C:\Scripts"
if (!(Test-Path $Dir)) { New-Item -ItemType Directory -Path $Dir | Out-Null }

$CredFile = "$Dir\nits_creds.txt"
$User = ""
$Pass = ""

if (Test-Path $CredFile) {
    $Creds = Get-Content $CredFile
    $User = $Creds[0]
    $Pass = $Creds[1]
    Write-Host "Welcome back! Found saved credentials for: $User" -ForegroundColor Green
} else {
    While ([string]::IsNullOrWhiteSpace($User)) {
        $User = Read-Host "Enter your NITS Username"
    }
    While ([string]::IsNullOrWhiteSpace($Pass)) {
        $Pass = Read-Host "Enter your NITS Password"
    }
    Set-Content -Path $CredFile -Value "$User`n$Pass"
}

$NetName = ""
While ([string]::IsNullOrWhiteSpace($NetName)) {
    Write-Host "`nOpen your PC Settings > Network & internet > Ethernet." -ForegroundColor Cyan
    $NetName = Read-Host "Enter your exact Ethernet Name here (MANDATORY)"
}

Write-Host "`n[1/5] Installing required Python libraries..." -ForegroundColor Yellow
py -m pip install selenium -q --disable-pip-version-check | Out-Null

Write-Host "`n[2/5] Creating simplified background files..." -ForegroundColor Yellow

# Generate the PowerShell Fixer (Straightforward 60-second limit)
$PSCode = @"
`$MaxAttempts = 6
`$Attempt = 0

While (`$Attempt -lt `$MaxAttempts) {
    `$Profile = (Get-NetConnectionProfile -InterfaceAlias "Ethernet" -ErrorAction SilentlyContinue).Name
    
    if (`$Profile -eq "$NetName") {
        # Network matches! Wait 2 seconds for IP, then exit so Python can take over.
        Start-Sleep -Seconds 2
        exit 0
    }
    
    # Wait 5 seconds to see if Windows identifies it naturally
    Start-Sleep -Seconds 5
    `$Profile = (Get-NetConnectionProfile -InterfaceAlias "Ethernet" -ErrorAction SilentlyContinue).Name
    if (`$Profile -eq "$NetName") { exit 0 }
    
    # If still stuck on Unidentified, force a reset
    Restart-NetAdapter -Name "Ethernet" -Confirm:`$false -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 10
    `$Attempt++
}
exit 1
"@
Set-Content -Path "$Dir\FixNetwork.ps1" -Value $PSCode

# Generate the Python Script (Checks internet, logs in, exits cleanly)
$PyCode = @"
import urllib.request
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import sys
import subprocess

PORTAL_URL = "http://10.10.10.1:8090/httpclient.html"

def kill_captive_portal():
    try:
        subprocess.run("taskkill /f /im CaptivePortalLogin.exe", shell=True, capture_output=True)
    except Exception:
        pass

def is_internet_active():
    try:
        response = urllib.request.urlopen("http://clients3.google.com/generate_204", timeout=5)
        if response.getcode() == 204:
            return True
    except Exception:
        pass
    return False

def auto_login():
    kill_captive_portal()
    options = webdriver.ChromeOptions()
    options.add_argument('--headless') 
    driver = webdriver.Chrome(options=options)
    driver.set_page_load_timeout(15) 

    try:
        driver.get(PORTAL_URL)
        username_field = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.XPATH, "//input[@type='text' or @placeholder='Username']")) 
        )
        password_field = driver.find_element(By.XPATH, "//input[@type='password' or @placeholder='Password']")
        username_field.send_keys("$User")
        password_field.send_keys("$Pass") 
        submit_button = driver.find_element(By.XPATH, "//*[contains(text(), 'Sign in') or @value='Sign in']") 
        submit_button.click()
        time.sleep(4) 
    except Exception:
        pass 
    finally:
        driver.quit()
        kill_captive_portal()

if __name__ == "__main__":
    if not is_internet_active():
        for _ in range(3):
            auto_login()
            if is_internet_active():
                break
            time.sleep(3)
"@
Set-Content -Path "$Dir\PortalLogin.py" -Value $PyCode

# Generate the Batch Controller (NO infinite loop. Runs once, finishes, goes to sleep).
$BatCode = @"
@echo off
powershell.exe -ExecutionPolicy Bypass -File "C:\Scripts\FixNetwork.ps1"
if %errorlevel% neq 0 exit /b
py "C:\Scripts\PortalLogin.py"
exit /b
"@
Set-Content -Path "$Dir\AutoConnect.bat" -Value $BatCode

Write-Host "`n[4/5] Disabling Windows browser popups..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet" -Name "EnableActiveProbing" -Value 1
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet" -Name "CaptivePortalBrowser" -Value 0 -ErrorAction SilentlyContinue
$NCSIPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkConnectivityStatusIndicator"
if (!(Test-Path $NCSIPath)) { New-Item -Path $NCSIPath -Force | Out-Null }
Set-ItemProperty -Path $NCSIPath -Name "CaptivePortalBrowser" -Value 0

Write-Host "`n[5/5] Registering Task Scheduler Event Trigger..." -ForegroundColor Yellow
$TaskXML = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers>
    <EventTrigger>
      <Enabled>true</Enabled>
      <Subscription>&lt;QueryList&gt;&lt;Query Id="0" Path="Microsoft-Windows-NetworkProfile/Operational"&gt;&lt;Select Path="Microsoft-Windows-NetworkProfile/Operational"&gt;*[System[(EventID=10000)]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
    </EventTrigger>
    <LogonTrigger>
      <Enabled>true</Enabled>
      <Delay>PT10S</Delay>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <RunLevel>HighestAvailable</RunLevel>
      <UserId>S-1-5-18</UserId>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <ExecutionTimeLimit>PT5M</ExecutionTimeLimit>
    <Hidden>true</Hidden>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>C:\Scripts\AutoConnect.bat</Command>
    </Exec>
  </Actions>
</Task>
"@
Register-ScheduledTask -Xml $TaskXML -TaskName "Network Automation" -Force | Out-Null

Write-Host "`nInstallation Complete! Logic has been simplified." -ForegroundColor Green