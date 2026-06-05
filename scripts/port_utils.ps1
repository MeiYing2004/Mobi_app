# Port + LAN + firewall helpers (dot-source only).

function Get-ActiveWiFiAdapter {
    $adapters = @(Get-NetAdapter -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Status -eq 'Up' -and (
                $_.InterfaceDescription -match 'Wireless|Wi-?Fi|802\.11|WLAN' -or
                $_.Name -like '*Wi*Fi*' -or
                $_.PhysicalMediaType -eq 'Native 802.11'
            )
        } |
        Sort-Object -Property InterfaceMetric, Status)

    if ($adapters.Count -gt 0) { return $adapters[0] }

    # Fallback: any connected adapter with a private/LAN IPv4
    Get-NetAdapter -ErrorAction SilentlyContinue |
        Where-Object { $_.Status -eq 'Up' } |
        Select-Object -First 1
}

function Get-WiFiLanIPv4 {
    $adapter = Get-ActiveWiFiAdapter
    if (-not $adapter) { return $null }

    $addr = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object {
            $_.InterfaceIndex -eq $adapter.ifIndex -and
            $_.IPAddress -notmatch '^127\.' -and
            $_.IPAddress -notmatch '^169\.254\.'
        } |
        Sort-Object -Property SkipAsSource, PrefixOrigin |
        Select-Object -ExpandProperty IPAddress -First 1

    return $addr
}

function Get-ActiveWiFiConnectionProfile {
    $adapter = Get-ActiveWiFiAdapter
    if (-not $adapter) { return $null }

    return Get-NetConnectionProfile -ErrorAction SilentlyContinue |
        Where-Object { $_.InterfaceIndex -eq $adapter.ifIndex } |
        Select-Object -First 1
}

function Get-LanWebConfig {
    param([string]$ProjectRoot)
    $configPath = Join-Path $ProjectRoot 'config\lan_web.json'
    $preferredWeb = 8080
    $preferredProxy = 8765
    $scanRange = 30

    if (Test-Path $configPath) {
        try {
            $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
            if ($cfg.preferredWebPort) { $preferredWeb = [int]$cfg.preferredWebPort }
            if ($cfg.preferredProxyPort) { $preferredProxy = [int]$cfg.preferredProxyPort }
            if ($cfg.portScanRange) { $scanRange = [int]$cfg.portScanRange }
        } catch {
            Write-Warning "Could not parse config/lan_web.json: $_"
        }
    }

    $yamlPath = Join-Path $ProjectRoot 'web_dev_config.yaml'
    if (Test-Path $yamlPath) {
        $m = Select-String -Path $yamlPath -Pattern '^\s*port:\s*(\d+)\s*$' | Select-Object -First 1
        if ($m) { $preferredWeb = [int]$m.Matches.Groups[1].Value }
    }

    if ($env:LAN_WEB_PORT) { $preferredWeb = [int]$env:LAN_WEB_PORT }
    if ($env:LAN_PROXY_PORT) { $preferredProxy = [int]$env:LAN_PROXY_PORT }
    if ($env:LAN_PORT_SCAN_RANGE) { $scanRange = [int]$env:LAN_PORT_SCAN_RANGE }

    [PSCustomObject]@{
        PreferredWebPort   = $preferredWeb
        PreferredProxyPort = $preferredProxy
        PortScanRange      = $scanRange
    }
}

function Test-TcpPortInUse {
    param([int]$Port)
    $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    return ($null -ne $conn -and $conn.Count -gt 0)
}

function Test-CanBindPort {
    param([int]$Port)
    $listener = $null
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Port)
        $listener.Start()
        return $true
    } catch {
        return $false
    } finally {
        if ($null -ne $listener) {
            try { $listener.Stop() } catch {}
        }
    }
}

function Find-AvailablePort {
    param(
        [int]$PreferredPort,
        [int]$ScanRange = 30
    )
    for ($offset = 0; $offset -lt $ScanRange; $offset++) {
        $candidate = $PreferredPort + $offset
        if ($candidate -lt 1 -or $candidate -gt 65535) { continue }
        if (Test-TcpPortInUse -Port $candidate) { continue }
        if (-not (Test-CanBindPort -Port $candidate)) { continue }
        return $candidate
    }
    throw "No free TCP port in range $PreferredPort..$($PreferredPort + $ScanRange - 1)"
}

function Get-WiFiNetworkCategory {
    try {
        $wifi = Get-ActiveWiFiConnectionProfile
        if ($wifi) { return [string]$wifi.NetworkCategory }
        $profiles = @(Get-NetConnectionProfile -ErrorAction Stop)
        $online = $profiles | Where-Object { $_.IPv4Connectivity -eq 'Internet' } | Select-Object -First 1
        if ($online) { return [string]$online.NetworkCategory }
    } catch {}
    return 'unknown'
}

function Add-LanFirewallRule {
    param([int]$Port)
    $ruleName = "Fuel Tracker Web LAN (TCP $Port)"
    $existing = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
    if ($existing) { return $true }

    try {
        New-NetFirewallRule -DisplayName $ruleName `
            -Direction Inbound -Action Allow -Protocol TCP `
            -LocalPort $Port -Profile Any -Enabled True | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Set-WiFiNetworkPrivate {
    try {
        $profile = Get-ActiveWiFiConnectionProfile
        if (-not $profile) {
            $profile = Get-NetConnectionProfile -ErrorAction Stop |
                Where-Object { $_.InterfaceAlias -match 'Wi-?Fi' } |
                Select-Object -First 1
        }
        if (-not $profile) { return $false }
        if ([string]$profile.NetworkCategory -eq 'Private') { return $true }
        Set-NetConnectionProfile -InterfaceIndex $profile.InterfaceIndex -NetworkCategory Private
        return $true
    } catch {
        return $false
    }
}

function Get-LanFirewallPortSet {
    param(
        [int]$ExtraPort = 0,
        [switch]$IncludeScanRange,
        [string]$ProjectRoot = ''
    )
    if (-not $ProjectRoot) {
        $ProjectRoot = Get-MobiappProjectRoot -ScriptsDirectory $PSScriptRoot
    }
    $cfg = Get-LanWebConfig -ProjectRoot $ProjectRoot
    $set = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($p in @(8080, 8081, $cfg.PreferredWebPort, $ExtraPort)) {
        if ($p -gt 0 -and $p -le 65535) { [void]$set.Add($p) }
    }
    foreach ($p in (Get-ActiveLanWebPorts)) {
        if ($p -gt 0) { [void]$set.Add($p) }
    }
    if ($IncludeScanRange) {
        for ($p = $cfg.PreferredWebPort; $p -lt $cfg.PreferredWebPort + $cfg.PortScanRange; $p++) {
            if ($p -gt 0 -and $p -le 65535) { [void]$set.Add($p) }
        }
    }
    $list = [int[]]::new($set.Count)
    $set.CopyTo($list)
    [Array]::Sort($list)
    return $list
}

function Repair-LanAccess {
    param([int]$Port = 0)
    $wifiCategory = Get-WiFiNetworkCategory
    $ports = Get-LanFirewallPortSet -ExtraPort $Port -ProjectRoot (Get-Location).Path
    $failed = @()
    $ok = 0
    foreach ($p in $ports) {
        if (Add-LanFirewallRule -Port $p) { $ok++ } else { $failed += $p }
    }
    $privateOk = $false
    if ($wifiCategory -eq 'Public') {
        $privateOk = Set-WiFiNetworkPrivate
    }

    [PSCustomObject]@{
        WiFiCategory     = $wifiCategory
        PortsOpened      = $ports
        RulesOkCount     = $ok
        RulesFailedPorts = $failed
        FirewallRuleOk   = ($failed.Count -eq 0)
        SetPrivateOk     = $privateOk
    }
}

function Show-FirewallHint {
    param([int]$WebPort = 0)
    try {
        $wifiCat = Get-WiFiNetworkCategory
        $enabled = @(Get-NetFirewallProfile -ErrorAction Stop |
            Where-Object { $_.Enabled -eq $true })

        if ($enabled.Count -gt 0) {
            Write-Host ''
            Write-Host '[Firewall] Windows Firewall is ON.' -ForegroundColor Yellow
            if ($wifiCat -eq 'Public') {
                Write-Host '  Wi-Fi is PUBLIC — phones are often BLOCKED inbound.' -ForegroundColor Red
                Write-Host '  Fix: run as Admin: .\scripts\fix_lan_firewall.ps1 -Port' $WebPort -ForegroundColor Yellow
                Write-Host '  Or: Settings > Wi-Fi > your network > Private profile.' -ForegroundColor Yellow
            } else {
                Write-Host '  If the phone cannot connect, run: .\scripts\fix_lan_firewall.ps1 -Port' $WebPort -ForegroundColor Yellow
            }
            Write-Host ''
        }
    } catch {
        # Ignore on systems without NetSecurity module.
    }
}

function Write-LanAccessBanner {
    param(
        [string]$LanIp,
        [int]$WebPort,
        [int]$ProxyPort = 0,
        [bool]$ExternalProxy = $false,
        [int]$PreferredWebPort = 0,
        [switch]$PortChanged
    )
    $webUrl = "http://${LanIp}:${WebPort}"
    $localUrl = "http://127.0.0.1:${WebPort}"

    Write-Host ''
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host ' Fuel Tracker - Flutter Web (LAN)      ' -ForegroundColor Cyan
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host " LAN IP          : $LanIp"
    Write-Host " Bind address    : 0.0.0.0 (all interfaces)"
    Write-Host " Web port        : $WebPort$(if ($PortChanged) { " (preferred $PreferredWebPort was busy)" } else { '' })"
    if ($ExternalProxy) {
        Write-Host " CORS proxy port : $ProxyPort (external, tool/dev_cors_proxy.dart)"
        Write-Host " CORS proxy URL  : http://${LanIp}:${ProxyPort}"
    } else {
        Write-Host ' CORS            : built-in (web_dev_config.yaml, same port)'
    }
    Write-Host ''
    Write-Host ' Local (this PC) :' -ForegroundColor White
    Write-Host "   $localUrl"
    Write-Host ''
    Write-Host ' Phone (same Wi-Fi) — open in browser:' -ForegroundColor Green
    Write-Host "   $webUrl" -ForegroundColor Green
    Write-Host ''
    Write-Host ' In-app debug overlay shows the same URLs (debug builds).' -ForegroundColor DarkGray
    if ($PortChanged) {
        Write-Host ''
        Write-Host ' NOTE: Other apps may still use older ports (8080, 8081).' -ForegroundColor Yellow
        Write-Host '       On phone, try THIS port first:' $WebPort -ForegroundColor Yellow
    }
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host ''
}

function Get-ActiveLanWebPorts {
    param(
        [int]$FromPort = 8080,
        [int]$ToPort = 8099
    )
    Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
        Where-Object {
            $_.LocalAddress -in @('0.0.0.0', '::', '*') -and
            $_.LocalPort -ge $FromPort -and $_.LocalPort -le $ToPort
        } |
        Sort-Object LocalPort -Unique |
        ForEach-Object { $_.LocalPort }
}
