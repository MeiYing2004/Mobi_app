$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

$replacements = [ordered]@{
  'package:fuel_tracker_app/shared/shared/' = 'package:fuel_tracker_app/shared/'
  'features/fuel/data/core/config/' = 'core/config/'
  'features/fuel/data/core/network/' = 'core/network/'
  'features/fuel/data/features/fuel/data/' = 'features/fuel/data/'
  'features/fuel/data/features/navigation/core/' = 'features/navigation/core/'
  'features/fuel/data/features/location/core/' = 'features/location/core/'
  'features/fuel/features/fuel/data/services/' = 'features/fuel/data/services/'
  'features/fuel/features/fuel/data/models/' = 'features/fuel/data/models/'
  'features/fuel/features/fuel/data/' = 'features/fuel/data/'
  'features/geocoding/features/geocoding/data/' = 'features/geocoding/data/'
  'features/geocoding/presentation/features/geocoding/data/' = 'features/geocoding/data/'
  'features/geocoding/presentation/features/geocoding/data/services/' = 'features/geocoding/data/services/'
  'features/geocoding/data/features/geocoding/data/' = 'features/geocoding/data/'
  'features/navigation/data/features/navigation/' = 'features/navigation/'
  'features/navigation/data/features/location/' = 'features/location/'
  'features/navigation/data/features/fuel/' = 'features/fuel/'
  'features/navigation/presentation/features/navigation/' = 'features/navigation/'
  'features/navigation/presentation/features/fuel/' = 'features/fuel/'
  'features/map/presentation/features/map/' = 'features/map/'
  'features/map/presentation/features/fuel/' = 'features/fuel/'
  'features/map/presentation/features/location/' = 'features/location/'
  'features/location/data/features/location/' = 'features/location/'
  'features/home_ios/features/fuel/' = 'features/fuel/'
  'features/fuel/data/services/notification_service.dart' = 'shared/services/notification_service.dart'
}

$files = Get-ChildItem lib, test -Recurse -Filter '*.dart' -ErrorAction SilentlyContinue
foreach ($file in $files) {
  $c = Get-Content $file.FullName -Raw -Encoding UTF8
  $o = $c
  foreach ($k in $replacements.Keys) {
    $c = $c.Replace($k, $replacements[$k])
  }
  if ($c -ne $o) {
    Set-Content $file.FullName $c -Encoding UTF8 -NoNewline
    Write-Host "FIX $($file.Name)"
  }
}
