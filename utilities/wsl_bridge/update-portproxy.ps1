# WSL Bridge - PowerShell script for updating port proxy rules
# This script is run by a scheduled task with elevated privileges

$configPath = "$env:USERPROFILE\.wsl-bridge\config.json"

if (-not (Test-Path $configPath)) {
    Write-Error "Config file not found: $configPath"
    exit 1
}

$config = Get-Content $configPath | ConvertFrom-Json

if (-not $config.ip -or -not $config.ports) {
    Write-Error "Invalid config: missing ip or ports"
    exit 1
}

# Clear existing rules for managed ports
foreach ($port in $config.ports) {
    netsh interface portproxy delete v4tov4 listenport=$port listenaddress=0.0.0.0 2>$null
}

# Add new rules
foreach ($port in $config.ports) {
    netsh interface portproxy add v4tov4 listenport=$port listenaddress=0.0.0.0 connectport=$port connectaddress=$($config.ip)
    Write-Host "Added port forward: 0.0.0.0:$port -> $($config.ip):$port"
}
