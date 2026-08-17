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

# Check if they have run the installer before
if (Test-Path $CredFile) {
    $Creds = Get-Content $CredFile
    $User = $Creds[0]
    $Pass = $Creds[1]
    Write-Host "Welcome back! Found saved credentials for: $User" -ForegroundColor Green
    Write-Host "Skipping username and password setup.`n" -ForegroundColor Yellow
} else {
    # First time setup
    While ([string]::IsNullOrWhiteSpace($User)) {
        $User = Read-Host "Enter your NITS Username (e.g., student_ug_23@cse.nits.ac.in)"
        if ([string]::IsNullOrWhiteSpace($User)) { Write-Host "Error: Username cannot be blank." -ForegroundColor Red }
    }

    While ([string]::IsNullOrWhiteSpace($Pass)) {
        $Pass = Read-Host "Enter your NITS Password"
        if ([string]::IsNullOrWhiteSpace($Pass)) { Write-Host "Error: Password cannot be blank." -ForegroundColor Red }
    }
    
    # Save credentials for future resets
    Set-Content -Path $CredFile -Value "$User`n$Pass"
}

# Always ask for the Network Name, since this is what changes after a reset
$NetName = ""
While ([string]::IsNullOrWhiteSpace($NetName)) {
    Write-Host "`nOpen your PC Settings > Network & internet > Ethernet." -ForegroundColor Cyan
    Write-Host "Look right under the word 'Ethernet'. You will see a name (e.g., 'Network', 'Ethernet 1', 'NITS-LAN')." -ForegroundColor Cyan
    $NetName = Read-Host "Enter that exact name here (MANDATORY)"
    if ([string]::IsNullOrWhiteSpace($NetName)) { Write-Host "Error: Ethernet name is required for the setup to work." -ForegroundColor Red }
}

Write-Host "`n[1/5] Installing required Python libraries..." -ForegroundColor Yellow
py -m pip install selenium

Write-Host "`n[2/5] Creating background files..." -ForegroundColor Yellow

# Generate the PowerShell Fixer (Dynamically uses their specific Network Name)
$PSCode = @"
`$ProfileName = (Get-NetConnectionProfile -InterfaceAlias "Ethernet" -ErrorAction SilentlyContinue).Name

# Looks for bugged patterns like "TheirNetworkName 2" or "Unidentified network"
While (`$ProfileName -match "^$NetName \d+`$" -or `$ProfileName -match "Unidentified") {
    ipconfig /release | Out-Null
    ipconfig /renew | Out-Null
    Start-Sleep -Seconds 5
    `$ProfileName = (Get-NetConnectionProfile -InterfaceAlias "Ethernet" -ErrorAction SilentlyContinue).Name
}
"@
Set-Content -Path "$Dir\FixNetwork.ps1" -Value $PSCode

# Generate the Python Script (Injecting their credentials automatically)
$PyCode = @"
import urllib.request
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time

PORTAL_URL = "http://10.10.10.1:8090/httpclient.html"

def is_internet_active():
    try:
        response = urllib.request.urlopen("http://clients3.google.com/generate_204", timeout=5)
        if response.getcode() == 204:
            return True
    except Exception:
        pass
    return False

def auto_login():
    options = webdriver.ChromeOptions()
    options.add_argument('--headless') 
    driver = webdriver.Chrome(options=options)

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
        time.sleep(3) 
    except Exception:
        pass 
    finally:
        driver.quit()

if __name__ == "__main__":
    if not is_internet_active():
        auto_login()
"@
Set-Content -Path "$Dir\PortalLogin.py" -Value $PyCode

# Generate the Batch Controller
$BatCode = @"
@echo off
powershell.exe -Command "if ((Get-NetAdapter -Name 'Ethernet' -ErrorAction SilentlyContinue).Status -ne 'Up') { exit 1 }"
if %errorlevel% neq 0 exit /b
powershell.exe -ExecutionPolicy Bypass -File "C:\Scripts\FixNetwork.ps1"
py "C:\Scripts\PortalLogin.py"
"@
Set-Content -Path "$Dir\AutoConnect.bat" -Value $BatCode

Write-Host "`n[4/5] Disabling Windows active probing pop-ups..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet" -Name "EnableActiveProbing" -Value 0

Write-Host "`n[5/5] Registering Task Scheduler Event Trigger..." -ForegroundColor Yellow
$TaskXML = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers>
    <EventTrigger>
      <Enabled>true</Enabled>
      <Subscription>&lt;QueryList&gt;&lt;Query Id="0" Path="Microsoft-Windows-NetworkProfile/Operational"&gt;&lt;Select Path="Microsoft-Windows-NetworkProfile/Operational"&gt;*[System[(EventID=10000)]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
    </EventTrigger>
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
    <ExecutionTimeLimit>PT1H</ExecutionTimeLimit>
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

Write-Host "`nInstallation Complete! The automation will now run silently in the background whenever an Ethernet cable is connected." -ForegroundColor Green