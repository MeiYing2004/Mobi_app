# Opens Windows Firewall for Flutter Web LAN (run from project root).
# Adds named inbound rules only — does NOT disable firewall or remove existing rules.
param(
    [int]$Port = 0,
    [switch]$SetWiFiPrivate,
    [switch]$OpenScanRange
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '_project_root.ps1')
. (Join-Path $PSScriptRoot 'port_utils.ps1')
. (Join-Path $PSScriptRoot 'get_lan_ip.ps1')

$ProjectRoot = Assert-MobiappProjectRoot -ScriptsDirectory $PSScriptRoot

function Invoke-FixLanFirewallCore {
    $ports = Get-LanFirewallPortSet -ExtraPort $Port -IncludeScanRange:$OpenScanRange -ProjectRoot $ProjectRoot
    $adapter = Get-ActiveWiFiAdapter
    $profile = Get-ActiveWiFiConnectionProfile

    Write-Host ''
    Write-Host 'Fuel Tracker — LAN firewall fix' -ForegroundColor Cyan
    Write-Host "Project root : $ProjectRoot"
    if ($adapter) {
        Write-Host "Wi-Fi adapter: $($adapter.Name) ($($adapter.InterfaceDescription))"
    } else {
        Write-Host 'Wi-Fi adapter: (not detected — using connection profile fallback)' -ForegroundColor Yellow
    }
    if ($profile) {
        Write-Host "Network      : $($profile.Name) [$($profile.NetworkCategory)]"
    }
    Write-Host "Wi-Fi category: $(Get-WiFiNetworkCategory)"
    Write-Host "Ports to allow : $($ports -join ', ')"
    Write-Host ''

    if ($SetWiFiPrivate -or (Get-WiFiNetworkCategory) -eq 'Public') {
        if (Set-WiFiNetworkPrivate) {
            Write-Host 'Network profile: Public -> Private (active Wi-Fi).' -ForegroundColor Green
        } else {
            Write-Host 'Could not set Private (set manually: Settings > Wi-Fi > network > Private).' -ForegroundColor Yellow
        }
    }

    $failed = @()
    foreach ($p in $ports) {
        if (Add-LanFirewallRule -Port $p) {
            Write-Host "Firewall rule OK: TCP inbound $p (Fuel Tracker Web LAN)" -ForegroundColor Green
        } else {
            Write-Host "Firewall rule FAILED: TCP $p" -ForegroundColor Red
            $failed += $p
        }
    }

    Write-Host ''
    if ($failed.Count -gt 0) {
        Write-Host 'Some rules failed. Re-run this script as Administrator.' -ForegroundColor Red
    } else {
        Write-Host 'Firewall rules ready. Firewall remains ON; only new allow rules were added.' -ForegroundColor Green
    }

    $ip = Get-LanIPv4
    if ($ip) {
        Write-Host ''
        Write-Host 'On phone (same Wi-Fi), try:' -ForegroundColor Green
        foreach ($p in (Get-ActiveLanWebPorts)) {
            Write-Host "  http://${ip}:${p}"
        }
        foreach ($p in @(8080, 8081)) {
            if ($p -notin (Get-ActiveLanWebPorts)) {
                Write-Host "  http://${ip}:${p}  (if Flutter uses this port)"
            }
        }
        if ($Port -gt 0) {
            Write-Host "  http://${ip}:${Port}"
        }
    }
    Write-Host ''
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host 'Re-launching as Administrator (UAC)...' -ForegroundColor Yellow
    $argList = @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-Command',
        "Set-Location -LiteralPath '$ProjectRoot'; & '$PSCommandPath' -SetWiFiPrivate$(if ($Port -gt 0) { " -Port $Port" })$(if ($OpenScanRange) { ' -OpenScanRange' })"
    )
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $argList | Out-Null
    exit 0
}

Invoke-FixLanFirewallCore
