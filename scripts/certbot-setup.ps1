# Certbot SSL Setup for Windows
# Uses DNS-01 challenge (works on Windows without special network requirements)
# Configures nginx SSL paths and sets up Windows Task Scheduler for auto-renewal

param(
    [Parameter(Mandatory=$true)]
    [string]$Domain,

    [Parameter(Mandatory=$true)]
    [string]$Email,

    [string]$NginxSslPath = "C:\stash\nginx\ssl",
    [string]$CertbotPath = ""
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param($Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message" -ForegroundColor Green
}

function Write-ErrorLog {
    param($Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ERROR: $Message" -ForegroundColor Red
}

Write-Log "Starting Certbot SSL setup for domain: $Domain"

# Step 1: Check if Certbot is installed, install if not
if (-not $CertbotPath) {
    $CertbotPath = "certbot"
    try {
        $null = & certbot --version 2>$null
        Write-Log "Certbot is already installed"
    } catch {
        Write-Log "Certbot not found. Installing via winget..."
        try {
            winget install --id Certbot.Certbot -e --source winget
            Write-Log "Certbot installed successfully via winget"
        } catch {
            Write-ErrorLog "Failed to install Certbot. Please install manually from https://certbot.eff.org/"
            exit 1
        }
    }
}

# Step 2: Create SSL directory if it doesn't exist
if (-not (Test-Path $NginxSslPath)) {
    New-Item -ItemType Directory -Path $NginxSslPath -Force | Out-Null
    Write-Log "Created SSL directory: $NginxSslPath"
}

# Step 3: Get certificate using DNS-01 challenge
# Note: User must manually add the TXT record to their DNS when prompted
Write-Log "Requesting certificate using DNS-01 challenge..."
Write-Log "You will be prompted to add a TXT record to your DNS. Follow the instructions from certbot."

$certbotCmd = "certbot certonly --manual --preferred-challenges dns -d $Domain -d www.$Domain --email $Email --agree-tos --no-eff-email"
Write-Log "Running: $certbotCmd"

try {
    Invoke-Expression $certbotCmd

    # Certbot stores certificates in C:\Certbot\live\$Domain\ on Windows
    $certbotLivePath = "C:\Certbot\live\$Domain"
    if (Test-Path $certbotLivePath) {
        Write-Log "Certificate obtained successfully at: $certbotLivePath"

        # Step 4: Copy certificates to nginx SSL path
        Copy-Item "$certbotLivePath\fullchain.pem" "$NginxSslPath\fullchain.pem" -Force
        Copy-Item "$certbotLivePath\privkey.pem" "$NginxSslPath\privkey.pem" -Force
        Copy-Item "$certbotLivePath\chain.pem" "$NginxSslPath\chain.pem" -Force
        Copy-Item "$certbotLivePath\cert.pem" "$NginxSslPath\cert.pem" -Force

        Write-Log "Certificates copied to nginx SSL path: $NginxSslPath"
        Write-Log "  - fullchain.pem (for ssl_certificate)"
        Write-Log "  - privkey.pem (for ssl_certificate_key)"
        Write-Log "  - chain.pem"
        Write-Log "  - cert.pem"
    } else {
        Write-ErrorLog "Certificate path not found: $certbotLivePath"
        exit 1
    }
} catch {
    Write-ErrorLog "Failed to obtain certificate: $_"
    Write-ErrorLog "Make sure you have added the correct TXT record to your DNS"
    exit 1
}

# Step 5: Set up Windows Task Scheduler for auto-renewal
Write-Log "Setting up Windows Task Scheduler for certificate auto-renewal..."

$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -Command `"& { certbot renew --quiet; Copy-Item C:\Certbot\live\$Domain\fullchain.pem $NginxSslPath\fullchain.pem -Force; Copy-Item C:\Certbot\live\$Domain\privkey.pem $NginxSslPath\privkey.pem -Force; Copy-Item C:\Certbot\live\$Domain\chain.pem $NginxSslPath\chain.pem -Force; Copy-Item C:\Certbot\live\$Domain\cert.pem $NginxSslPath\cert.pem -Force; docker restart nginx-proxy }`""

$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "03:00"

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -WakeToRun

$taskName = "CertbotRenewal_$Domain"
$taskDesc = "Automatically renews Let's Encrypt SSL certificate for $Domain and restarts nginx"

try {
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Log "Removed existing scheduled task: $taskName"
    }

    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings `
        -Description $taskDesc `
        -Force

    Write-Log "Scheduled task '$taskName' created successfully"
    Write-Log "  - Runs every Sunday at 03:00 AM"
    Write-Log "  - Will renew certificate, copy to nginx, and restart nginx container"
} catch {
    Write-ErrorLog "Failed to create scheduled task: $_"
    Write-Log "You can manually set up renewal with: certbot renew --quiet"
    exit 1
}

# Step 6: Verify nginx SSL configuration
Write-Log ""
Write-Log "=========================================="
Write-Log "SSL Setup Complete!"
Write-Log "=========================================="
Write-Log ""
Write-Log "Nginx SSL Configuration:"
Write-Log "  ssl_certificate:     $NginxSslPath\fullchain.pem"
Write-Log "  ssl_certificate_key: $NginxSslPath\privkey.pem"
Write-Log ""
Write-Log "Add this to your nginx server block:"
Write-Log ""
Write-Log "    listen 443 ssl http2;"
Write-Log "    listen [::]:443 ssl http2;"
Write-Log "    ssl_certificate /etc/nginx/ssl/fullchain.pem;"
Write-Log "    ssl_certificate_key /etc/nginx/ssl/privkey.pem;"
Write-Log "    ssl_protocols TLSv1.2 TLSv1.3;"
Write-Log "    ssl_ciphers HIGH:!aNULL:!MD5;"
Write-Log "    ssl_prefer_server_ciphers on;"
Write-Log ""
Write-Log "Auto-renewal: Scheduled task '$taskName' is active"
Write-Log "Manual renewal command: certbot renew --quiet"
Write-Log ""
