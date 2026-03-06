<#
.SYNOPSIS
    Sets up uBlock Origin on Chrome with the Manifest V2 workaround.
.DESCRIPTION
    - Creates desktop shortcut with --disable-features=ExtensionManifestV2Unsupported,ExtensionManifestV2Disabled
    - Downloads uBlock Origin from GitHub and extracts it
    - Enables Developer mode in Chrome preferences
    - Launches Chrome and opens extensions page for "Load unpacked"
    
    Run in PowerShell. Close Chrome before running. Admin not required.
.NOTES
    Chrome removed --load-extension in v137, so you must manually click "Load unpacked" once.
#>

$ErrorActionPreference = "Stop"
Write-Host "uBlock Chrome Setup v2 (Downloads folder, Developer mode)" -ForegroundColor Magenta

# --- Config ---
$uBlockRepo = "gorhill/uBlock"
# Use Shell to get actual Downloads path (handles OneDrive, redirected folders)
try {
    $shell = New-Object -ComObject Shell.Application
    $uBlockInstallDir = Join-Path $shell.Namespace('shell:Downloads').Self.Path "uBlock0"
} catch {
    $uBlockInstallDir = Join-Path $env:USERPROFILE "Downloads\uBlock0"
}
$ChromePaths = @(
    "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
)
$ChromeUserData = "$env:LOCALAPPDATA\Google\Chrome\User Data"
$ChromePreferences = "$ChromeUserData\Default\Preferences"
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$ShortcutPath = Join-Path $DesktopPath "Chrome (uBlock).lnk"

# --- Find Chrome ---
$ChromeExe = $ChromePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $ChromeExe) {
    Write-Host "Chrome not found. Checked: $($ChromePaths -join ', ')" -ForegroundColor Red
    exit 1
}
Write-Host "Using Chrome: $ChromeExe" -ForegroundColor Cyan

# --- Kill Chrome ---
$chromeProcs = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
if ($chromeProcs) {
    Write-Host "Stopping Chrome processes..." -ForegroundColor Yellow
    $chromeProcs | Stop-Process -Force
    Start-Sleep -Seconds 2
}

# --- Create shortcut ---
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $ChromeExe
$Shortcut.Arguments = "--disable-features=ExtensionManifestV2Unsupported,ExtensionManifestV2Disabled"
$Shortcut.WorkingDirectory = Split-Path $ChromeExe
$Shortcut.Description = "Chrome with uBlock Origin (MV2 workaround)"
$Shortcut.Save()
Write-Host "Created shortcut: $ShortcutPath" -ForegroundColor Green

# --- Download uBlock ---
Write-Host "Fetching latest uBlock release..." -ForegroundColor Cyan
$releaseJson = Invoke-RestMethod -Uri "https://api.github.com/repos/$uBlockRepo/releases/latest" -Headers @{
    "Accept" = "application/vnd.github.v3+json"
    "User-Agent" = "uBlock-Installer"
}
$chromiumAsset = $releaseJson.assets | Where-Object { $_.name -match "\.chromium\.zip$" } | Select-Object -First 1
if (-not $chromiumAsset) {
    Write-Host "No Chromium build found in release." -ForegroundColor Red
    exit 1
}

$zipPath = "$env:TEMP\uBlock0.chromium.zip"
Write-Host "Downloading $($chromiumAsset.name)..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $chromiumAsset.browser_download_url -OutFile $zipPath -UseBasicParsing

# --- Extract ---
if (Test-Path $uBlockInstallDir) { Remove-Item $uBlockInstallDir -Recurse -Force }
New-Item -ItemType Directory -Path $uBlockInstallDir -Force | Out-Null
Expand-Archive -Path $zipPath -DestinationPath $uBlockInstallDir -Force
Remove-Item $zipPath -Force

# Find the extracted folder (zip may contain uBlock0.chromium or similar)
$extractedFolder = Get-ChildItem $uBlockInstallDir -Directory | Select-Object -First 1
if ($extractedFolder) {
    $uBlockFolder = $extractedFolder.FullName
} else {
    $uBlockFolder = $uBlockInstallDir
}
Write-Host "uBlock extracted to: $uBlockFolder" -ForegroundColor Green

# --- Enable Developer mode in Chrome preferences ---
if (Test-Path $ChromePreferences) {
    $prefsBackup = "$ChromePreferences.uBlock-backup"
    try {
        Copy-Item $ChromePreferences $prefsBackup -Force
        $json = Get-Content $ChromePreferences -Raw
        $prefs = $json | ConvertFrom-Json
        if (-not $prefs.PSObject.Properties["extensions"]) {
            $prefs | Add-Member -NotePropertyName "extensions" -NotePropertyValue ([PSCustomObject]@{}) -Force
        }
        if (-not $prefs.extensions.PSObject.Properties["ui"]) {
            $prefs.extensions | Add-Member -NotePropertyName "ui" -NotePropertyValue ([PSCustomObject]@{}) -Force
        }
        $prefs.extensions.ui | Add-Member -NotePropertyName "developer_mode" -NotePropertyValue $true -Force
        $prefs | ConvertTo-Json -Depth 100 | Set-Content $ChromePreferences -Encoding UTF8
        Write-Host "Developer mode enabled in Chrome preferences." -ForegroundColor Green
    } catch {
        if ($prefsBackup -and (Test-Path $prefsBackup)) { Copy-Item $prefsBackup $ChromePreferences -Force }
        Write-Host "Could not modify Chrome preferences: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "Chrome preferences not found. Developer mode will need to be enabled manually." -ForegroundColor Yellow
}

# --- Copy path to clipboard ---
Set-Clipboard -Value $uBlockFolder
Write-Host "`nPath copied to clipboard. Use it when selecting folder for 'Load unpacked'." -ForegroundColor Cyan

# --- Launch Chrome ---
Write-Host "Launching Chrome with uBlock workaround..." -ForegroundColor Cyan
Start-Process $ChromeExe -ArgumentList "--disable-features=ExtensionManifestV2Unsupported,ExtensionManifestV2Disabled", "chrome://extensions"
Start-Sleep -Seconds 2
explorer.exe $uBlockFolder

Write-Host "`n=== DONE ===" -ForegroundColor Green
Write-Host "1. In Chrome (chrome://extensions/), turn on Developer mode in the top right corner"
Write-Host "2. Click 'Load unpacked'"
Write-Host "3. Select the folder that just opened (or paste from clipboard)"
Write-Host "4. Always launch Chrome from the new shortcut: $ShortcutPath"
Write-Host "5. After Chrome updates, close ALL Chrome tasks and launch from the shortcut again."
