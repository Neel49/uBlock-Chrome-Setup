# Publish uBlock-Chrome-Setup to GitHub
# Run: powershell -ExecutionPolicy Bypass -File Publish-ToGitHub.ps1

$gh = "C:\Program Files\GitHub CLI\gh.exe"
if (-not (Test-Path $gh)) {
    Write-Host "GitHub CLI not found. Install with: winget install GitHub.cli" -ForegroundColor Red
    exit 1
}

# Check auth
$auth = & $gh auth status 2>&1
if ($auth -match "not logged in") {
    Write-Host "Logging into GitHub (browser will open)..." -ForegroundColor Yellow
    & $gh auth login --web --git-protocol https
    if ($LASTEXITCODE -ne 0) { exit 1 }
}

# Create repo and push
Write-Host "Creating repo and pushing..." -ForegroundColor Cyan
& $gh repo create Neel49/uBlock-Chrome-Setup --public --source=. --remote=origin --push
if ($LASTEXITCODE -eq 0) {
    Write-Host "`nDone! Repo: https://github.com/Neel49/uBlock-Chrome-Setup" -ForegroundColor Green
} else {
    Write-Host "`nIf repo already exists, run: git push -u origin main" -ForegroundColor Yellow
}
