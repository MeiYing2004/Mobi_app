# Shared guard: ensure scripts run from Fuel Tracker project root (dot-source only).

function Get-MobiappProjectRoot {
    param([string]$ScriptsDirectory = $PSScriptRoot)
    return (Resolve-Path (Join-Path $ScriptsDirectory '..')).Path
}

function Assert-MobiappProjectRoot {
    param([string]$ScriptsDirectory = $PSScriptRoot)

    $root = Get-MobiappProjectRoot -ScriptsDirectory $ScriptsDirectory
    $pubspec = Join-Path $root 'pubspec.yaml'

    if (-not (Test-Path -LiteralPath $pubspec)) {
        Write-Host ''
        Write-Host 'ERROR: Wrong working directory or project path.' -ForegroundColor Red
        Write-Host "  Missing: $pubspec" -ForegroundColor Red
        Write-Host ''
        Write-Host '  Run from the project root, for example:' -ForegroundColor Yellow
        Write-Host "    cd `"$root`"" -ForegroundColor Cyan
        Write-Host '    .\scripts\run_web_lan.ps1' -ForegroundColor Cyan
        Write-Host '    .\scripts\fix_lan_firewall.ps1' -ForegroundColor Cyan
        Write-Host ''
        exit 1
    }

    Set-Location -LiteralPath $root
    return $root
}
