# Diagnose LAN / firewall / Flutter Web (run from project root).
$ErrorActionPreference = 'Continue'

. (Join-Path $PSScriptRoot '_project_root.ps1')
. (Join-Path $PSScriptRoot 'get_lan_ip.ps1')
. (Join-Path $PSScriptRoot 'port_utils.ps1')

$ProjectRoot = Assert-MobiappProjectRoot -ScriptsDirectory $PSScriptRoot

$LanIp = Get-LanIPv4
$wifiCat = Get-WiFiNetworkCategory
$adapter = Get-ActiveWiFiAdapter
$activePorts = @(Get-ActiveLanWebPorts)

Write-Host ''
Write-Host '========== LAN diagnostic ==========' -ForegroundColor Cyan
Write-Host "Project root  : $ProjectRoot"
Write-Host "PC LAN IP     : $(if ($LanIp) { $LanIp } else { 'NOT FOUND' })"
if ($adapter) {
    Write-Host "Wi-Fi adapter : $($adapter.Name)"
}
Write-Host "Wi-Fi category: $wifiCat"

if ($wifiCat -eq 'Public') {
    Write-Host ''
    Write-Host 'PROBLEM: Wi-Fi is PUBLIC — phone inbound often blocked.' -ForegroundColor Red
    Write-Host 'FIX: .\scripts\fix_lan_firewall.ps1 -SetWiFiPrivate' -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'Ports on 0.0.0.0 (8080-8099):' $(if ($activePorts.Count) { $activePorts -join ', ' } else { 'none' })

foreach ($p in $activePorts) {
    $url = "http://${LanIp}:${p}/"
    try {
        $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3
        Write-Host "  Port $p : OK ($($r.StatusCode)) -> http://${LanIp}:${p}" -ForegroundColor Green
    } catch {
        Write-Host "  Port $p : FAIL from PC via LAN IP" -ForegroundColor Red
    }
}

if ($activePorts.Count -eq 0) {
    Write-Host ''
    Write-Host 'PROBLEM: No web server on 8080-8099.' -ForegroundColor Red
    Write-Host 'FIX: .\scripts\run_web_lan.ps1' -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'If PC OK but phone fails: fix_lan_firewall.ps1 (Admin) or lab AP isolation.' -ForegroundColor Yellow
Write-Host '==================================' -ForegroundColor Cyan
Write-Host ''
