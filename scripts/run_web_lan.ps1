# Single command: Flutter Web on LAN (0.0.0.0) + firewall prep + phone URL.
param(
    [switch]$ExternalProxy,
    [switch]$SkipFirewallFix
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '_project_root.ps1')
. (Join-Path $PSScriptRoot 'get_lan_ip.ps1')
. (Join-Path $PSScriptRoot 'port_utils.ps1')

$ProjectRoot = Assert-MobiappProjectRoot -ScriptsDirectory $PSScriptRoot

$LanIp = Get-LanIPv4
if (-not $LanIp) {
    Write-Error 'No LAN IPv4 address found. Connect Wi-Fi/Ethernet.'
    exit 1
}

$cfg = Get-LanWebConfig -ProjectRoot $ProjectRoot
$preferredWeb = $cfg.PreferredWebPort
$preferredProxy = $cfg.PreferredProxyPort
$scanRange = $cfg.PortScanRange

try {
    $WebPort = Find-AvailablePort -PreferredPort $preferredWeb -ScanRange $scanRange
} catch {
    Write-Error $_
    exit 1
}

$portChanged = $WebPort -ne $preferredWeb
$ProxyPort = 0
$proxyJob = $null

if ($ExternalProxy) {
    try {
        $ProxyPort = Find-AvailablePort -PreferredPort $preferredProxy -ScanRange $scanRange
    } catch {
        Write-Error $_
        exit 1
    }
}

if (-not $SkipFirewallFix) {
    $repair = Repair-LanAccess -Port $WebPort
    if (-not $repair.FirewallRuleOk) {
        Write-Host '[Firewall] Could not add all inbound rules (Administrator required).' -ForegroundColor Yellow
        Write-Host '  Run: .\scripts\fix_lan_firewall.ps1 -SetWiFiPrivate' -ForegroundColor Yellow
    } elseif ($repair.WiFiCategory -eq 'Public' -and -not $repair.SetPrivateOk) {
        Write-Host '[Network] Wi-Fi still Public — run: .\scripts\fix_lan_firewall.ps1 -SetWiFiPrivate' -ForegroundColor Yellow
    } else {
        Write-Host "[Firewall] Opened ports: $($repair.PortsOpened -join ', ')" -ForegroundColor DarkGray
    }
}

$activePorts = @(Get-ActiveLanWebPorts)
if ($activePorts.Count -gt 0) {
    Write-Host '[Info] Already listening on 0.0.0.0:' ($activePorts -join ', ') -ForegroundColor DarkGray
}

Show-FirewallHint -WebPort $WebPort
Write-LanAccessBanner -LanIp $LanIp -WebPort $WebPort -ProxyPort $ProxyPort `
    -ExternalProxy:$ExternalProxy -PreferredWebPort $preferredWeb -PortChanged:$portChanged

$ProxyUrl = "http://${LanIp}:${ProxyPort}"
$WebUrl = "http://${LanIp}:${WebPort}"

if ($ExternalProxy) {
    $proxyJob = Start-Job -ScriptBlock {
        param($Root, $Port)
        Set-Location -LiteralPath $Root
        dart run tool/dev_cors_proxy.dart $Port
    } -ArgumentList $ProjectRoot, $ProxyPort

    Start-Sleep -Seconds 2
    if ($proxyJob.State -eq 'Failed') {
        Receive-Job $proxyJob
        Write-Error 'CORS proxy failed to start.'
        exit 1
    }
}

$corsMode = if ($ExternalProxy) { 'external' } else { 'builtin' }

$flutterArgs = @(
    'run', '-d', 'web-server',
    '--web-hostname=0.0.0.0',
    "--web-port=$WebPort",
    "--web-launch-url=$WebUrl",
    "--dart-define=WEB_LAN_HOST=$LanIp",
    "--dart-define=WEB_LAN_PORT=$WebPort",
    "--dart-define=WEB_CORS_MODE=$corsMode"
)

if ($ExternalProxy) {
    $flutterArgs += "--dart-define=OSM_DEV_PROXY=$ProxyUrl"
}

try {
    & flutter @flutterArgs
} finally {
    if ($null -ne $proxyJob) {
        Stop-Job $proxyJob -ErrorAction SilentlyContinue
        Remove-Job $proxyJob -Force -ErrorAction SilentlyContinue
    }
}
