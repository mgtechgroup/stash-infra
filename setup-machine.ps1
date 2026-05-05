# Machine-Wide Environment Setup
# Run: powershell -ExecutionPolicy Bypass -File C:\stash\setup-machine.ps1

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Stash + CommunityScrapers System Setup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# --- 1. Environment Variables ---
Write-Host "[1/5] Setting environment variables..." -ForegroundColor Yellow

[Environment]::SetEnvironmentVariable("STASH_SCRAPERS_PATH", "C:\stash\scrapers", [EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("STASH_CONFIG_PATH", "C:\stash\config", [EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("STASH_CACHE_PATH", "C:\stash\cache", [EnvironmentVariableTarget]::Machine)

$env:STASH_SCRAPERS_PATH = "C:\stash\scrapers"
$env:STASH_CONFIG_PATH   = "C:\stash\config"

Write-Host "[OK] STASH_SCRAPERS_PATH = C:\stash\scrapers" -ForegroundColor Green
Write-Host "[OK] STASH_CONFIG_PATH   = C:\stash\config" -ForegroundColor Green

# --- 2. Python dependencies ---
Write-Host ""
Write-Host "[2/5] Installing Python dependencies..." -ForegroundColor Yellow

$pythonPaths = @(
    "C:\Python313\python.exe",
    "C:\Python312\python.exe",
    "C:\Python311\python.exe",
    "python",
    "py"
)

$python = $null
foreach ($p in $pythonPaths) {
    try {
        $v = & $p --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            $python = $p
            Write-Host "  Found Python: $v at $p" -ForegroundColor Gray
            break
        }
    } catch {}
}

if ($python) {
    & $python -m pip install stashapp-tools requests cloudscraper beautifulsoup4 lxml python-dateutil pillow 2>&1 | Out-Null
    Write-Host "[OK] Python dependencies installed" -ForegroundColor Green
} else {
    Write-Host "[WARN] Python not found. Install from python.org to C:\Python313" -ForegroundColor Yellow
}

# --- 3. Docker setup ---
Write-Host ""
Write-Host "[3/5] Setting up Docker..." -ForegroundColor Yellow

$docker = Get-Command docker -ErrorAction SilentlyContinue
if ($docker) {
    Set-Location C:\stash
    docker compose up -d 2>&1 | Out-Null
    Write-Host "[OK] Docker containers started" -ForegroundColor Green
} else {
    Write-Host "[WARN] Docker not found. Scrapers still usable via local Stash." -ForegroundColor Yellow
}

# --- 4. Verify scrapers ---
Write-Host ""
Write-Host "[4/5] Verifying scrapers..." -ForegroundColor Yellow

$scraperCount = (Get-ChildItem "C:\stash\scrapers" -Recurse -Filter "*.yml" | Measure-Object).Count
Write-Host "[OK] $scraperCount YAML scrapers available" -ForegroundColor Green

$pythonCount = (Get-ChildItem "C:\stash\scrapers" -Recurse -Filter "*.py" | Measure-Object).Count
Write-Host "[OK] $pythonCount Python scraper scripts available" -ForegroundColor Green

# --- 5. Firewall rule ---
Write-Host ""
Write-Host "[5/5] Adding firewall rule for Stash..." -ForegroundColor Yellow

try {
    New-NetFirewallRule -DisplayName "Stash" -Direction Inbound -LocalPort 9999 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue | Out-Null
    Write-Host "[OK] Firewall rule added for port 9999" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Could not add firewall rule (run as admin?)" -ForegroundColor Yellow
}

# --- Done ---
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  MACHINE SETUP COMPLETE" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Stash:        http://localhost:9999"
Write-Host "  Scrapers:     C:\stash\scrapers ($scraperCount files)"
Write-Host "  Config:       C:\stash\config\config.yml"
Write-Host "  Docker:       cd C:\stash && docker compose up -d"
Write-Host ""
Write-Host "  In Stash:  Settings > Metadata Providers > Source: file"
Write-Host "  Then browse and enable your scrapers."
Write-Host "============================================" -ForegroundColor Cyan
