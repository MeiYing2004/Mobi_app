# Returns LAN IPv4 (prefers active Wi-Fi adapter). Dot-source or run directly.
if (-not (Get-Command Get-WiFiLanIPv4 -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'port_utils.ps1')
}

function Get-LanIPv4 {
    $wifiIp = Get-WiFiLanIPv4
    if ($wifiIp) { return $wifiIp }

    $addrs = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object {
            $_.IPAddress -notmatch '^127\.' -and
            $_.IPAddress -notmatch '^169\.254\.' -and
            $_.PrefixOrigin -ne 'WellKnown'
        } |
        Sort-Object -Property InterfaceMetric, SkipAsSource |
        Select-Object -ExpandProperty IPAddress -First 1

    if ($addrs) { return $addrs }

    $line = (ipconfig | Select-String -Pattern 'IPv4.*:\s*(\d+\.\d+\.\d+\.\d+)' -AllMatches |
        ForEach-Object { $_.Matches[0].Groups[1].Value } |
        Where-Object { $_ -notmatch '^127\.' -and $_ -notmatch '^169\.254\.' } |
        Select-Object -First 1)
    return $line
}

if ($MyInvocation.InvocationName -ne '.') {
    . (Join-Path $PSScriptRoot '_project_root.ps1')
    $null = Assert-MobiappProjectRoot -ScriptsDirectory $PSScriptRoot
    $ip = Get-LanIPv4
    if (-not $ip) {
        Write-Error 'No LAN IPv4 address found. Connect Wi-Fi/Ethernet.'
        exit 1
    }
    Write-Output $ip
}
