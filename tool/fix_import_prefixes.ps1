$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

$replacements = [ordered]@{
  'package:fuel_tracker_app/shared/features/' = 'package:fuel_tracker_app/features/'
  'package:fuel_tracker_app/shared/core/' = 'package:fuel_tracker_app/core/'
  'package:fuel_tracker_app/features/features/' = 'package:fuel_tracker_app/features/'
  'package:fuel_tracker_app/features/core/' = 'package:fuel_tracker_app/core/'
  'package:fuel_tracker_app/features/shared/' = 'package:fuel_tracker_app/shared/'
  'package:fuel_tracker_app/features/fuel/home_ios/' = 'package:fuel_tracker_app/features/home_ios/'
  'package:fuel_tracker_app/features/fuel/fuel_intelligence/viewmodels/' = 'package:fuel_tracker_app/features/fuel/presentation/viewmodels/'
  'package:fuel_tracker_app/features/fuel/fuel_intelligence/widgets/' = 'package:fuel_tracker_app/features/fuel/presentation/widgets/'
  'package:fuel_tracker_app/features/fuel/fuel_intelligence/screens/' = 'package:fuel_tracker_app/features/fuel/presentation/screens/'
  'package:fuel_tracker_app/core/constants.dart' = 'package:fuel_tracker_app/core/config/constants.dart'
  'package:fuel_tracker_app/core/network/osm_config.dart' = 'package:fuel_tracker_app/core/config/osm_config.dart'
  'package:fuel_tracker_app/features/map/core/osm_config.dart' = 'package:fuel_tracker_app/core/config/osm_config.dart'
  'package:fuel_tracker_app/features/geocoding/presentation/core/' = 'package:fuel_tracker_app/core/'
  'package:fuel_tracker_app/features/map/presentation/core/' = 'package:fuel_tracker_app/core/'
  'package:fuel_tracker_app/features/location/data/core/' = 'package:fuel_tracker_app/core/'
  'package:fuel_tracker_app/features/navigation/presentation/core/' = 'package:fuel_tracker_app/core/'
  'package:fuel_tracker_app/features/navigation/constants.dart' = 'package:fuel_tracker_app/core/config/constants.dart'
  'package:fuel_tracker_app/features/navigation/navigation/gps_tracking_policy.dart' = 'package:fuel_tracker_app/features/location/core/gps_tracking_policy.dart'
  'package:fuel_tracker_app/features/navigation/utils/polyline_utils.dart' = 'package:fuel_tracker_app/features/navigation/core/polyline_utils.dart'
  'package:fuel_tracker_app/features/navigation/data/models/gas_station.dart' = 'package:fuel_tracker_app/features/fuel/data/models/gas_station.dart'
  'package:fuel_tracker_app/features/navigation/data/models/route_fuel_analysis.dart' = 'package:fuel_tracker_app/features/fuel/data/models/route_fuel_analysis.dart'
}

$files = Get-ChildItem lib, test -Recurse -Filter '*.dart'
$round = 0
do {
  $round++
  $any = $false
  foreach ($file in $files) {
    $c = Get-Content $file.FullName -Raw -Encoding UTF8
    $o = $c
    foreach ($k in $replacements.Keys) {
      $c = $c.Replace($k, $replacements[$k])
    }
    if ($c -ne $o) {
      Set-Content $file.FullName $c -Encoding UTF8 -NoNewline
      $any = $true
    }
  }
} while ($any -and $round -lt 5)

Write-Host "Done after $round rounds."
