# Convert relative lib imports to package:fuel_tracker_app/...
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$libRoot = Join-Path $root 'lib'

function Resolve-LibImport([string]$fromFile, [string]$importPath) {
  if ($importPath.StartsWith('package:') -or $importPath.StartsWith('dart:')) { return $null }
  $fromDir = Split-Path $fromFile -Parent
  $target = [System.IO.Path]::GetFullPath((Join-Path $fromDir $importPath))
  $libNorm = [System.IO.Path]::GetFullPath($libRoot)
  if (-not $target.StartsWith($libNorm)) { return $null }
  $rel = $target.Substring($libNorm.Length).TrimStart('\', '/').Replace('\', '/')
  return "package:fuel_tracker_app/$rel"
}

$files = Get-ChildItem -Path $libRoot -Recurse -Filter '*.dart'
foreach ($file in $files) {
  $text = Get-Content $file.FullName -Raw -Encoding UTF8
  $changed = $false
  $newText = [regex]::Replace($text, "import\s+'([^']+)';", {
    param($m)
    $path = $m.Groups[1].Value
    if ($path.StartsWith('package:') -or $path.StartsWith('dart:')) { return $m.Value }
    $resolved = Resolve-LibImport $file.FullName $path
    if ($null -eq $resolved) { return $m.Value }
    $script:changed = $true
    return "import '$resolved';"
  })
  if ($changed) {
    Set-Content -Path $file.FullName -Value $newText -Encoding UTF8 -NoNewline
    Write-Host "FIXED $($file.FullName)"
  }
}
Write-Host 'Done.'
