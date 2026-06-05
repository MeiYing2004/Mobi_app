# Print LAN URLs without starting Flutter (run from project root).
param([switch]$ExternalProxy)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '_project_root.ps1')
. (Join-Path $PSScriptRoot 'get_lan_ip.ps1')
. (Join-Path $PSScriptRoot 'port_utils.ps1')

$ProjectRoot = Assert-MobiappProjectRoot -ScriptsDirectory $PSScriptRoot

$LanIp = Get-LanIPv4
if (-not $LanIp) {
    Write-Error 'No LAN IPv4 address found.'
    exit 1
}

$cfg = Get-LanWebConfig -ProjectRoot $ProjectRoot
$WebPort = Find-AvailablePort -PreferredPort $cfg.PreferredWebPort -ScanRange $cfg.PortScanRange
$ProxyPort = 0
if ($ExternalProxy) {
    $ProxyPort = Find-AvailablePort -PreferredPort $cfg.PreferredProxyPort -ScanRange $cfg.PortScanRange
}

Write-LanAccessBanner -LanIp $LanIp -WebPort $WebPort -ProxyPort $ProxyPort `
    -ExternalProxy:$ExternalProxy -PreferredWebPort $cfg.PreferredWebPort `
    -PortChanged:($WebPort -ne $cfg.PreferredWebPort)

$active = @(Get-ActiveLanWebPorts)
if ($active.Count -gt 0) {
    Write-Host 'Active Flutter/listener URLs on this PC:' -ForegroundColor Cyan
    foreach ($p in $active) {
        Write-Host "  http://${LanIp}:${p}"
    }
}
