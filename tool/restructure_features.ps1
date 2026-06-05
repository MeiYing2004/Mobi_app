# Feature-based lib/ restructure — moves files + updates import path segments.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

function Ensure-Dir($path) {
  if (-not (Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
}

function Move-File($from, $to) {
  if (-not (Test-Path $from)) {
    Write-Warning "Skip missing: $from"
    return
  }
  $dir = Split-Path $to -Parent
  Ensure-Dir $dir
  if (Test-Path $to) { Remove-Item $to -Force }
  Move-Item -Path $from -Destination $to -Force
  Write-Host "MOVED $from -> $to"
}

# --- Create target dirs ---
@(
  'lib/features/navigation/data/services',
  'lib/features/navigation/data/models',
  'lib/features/navigation/data/repositories',
  'lib/features/navigation/data/session',
  'lib/features/navigation/core',
  'lib/features/navigation/presentation/widgets',
  'lib/features/map/presentation/widgets',
  'lib/features/map/core',
  'lib/features/geocoding/data/services',
  'lib/features/geocoding/data/models',
  'lib/features/geocoding/data/exceptions',
  'lib/features/geocoding/core',
  'lib/features/geocoding/presentation/widgets',
  'lib/features/location/data/services',
  'lib/features/location/core',
  'lib/features/fuel/data/services',
  'lib/features/fuel/data/models',
  'lib/features/fuel/intelligence/consumption',
  'lib/features/fuel/intelligence/driving_behavior',
  'lib/features/fuel/intelligence/prediction',
  'lib/features/fuel/intelligence/simulation',
  'lib/features/fuel/intelligence/telemetry',
  'lib/features/fuel/intelligence/warnings',
  'lib/features/fuel/presentation/screens',
  'lib/features/fuel/presentation/viewmodels',
  'lib/features/fuel/presentation/widgets',
  'lib/core/network',
  'lib/core/config',
  'lib/shared/providers',
  'lib/shared/services',
  'lib/shared/screens',
  'lib/shared/widgets'
) | ForEach-Object { Ensure-Dir $_ }

# --- Navigation ---
Move-File 'lib/features/map_navigation/data/services/osrm_routing_service.dart' 'lib/features/navigation/data/services/osrm_routing_service.dart'
Move-File 'lib/features/map_navigation/data/services/osrm_route_parser.dart' 'lib/features/navigation/data/services/osrm_route_parser.dart'
Move-File 'lib/features/map_navigation/data/models/route_plan.dart' 'lib/features/navigation/data/models/route_plan.dart'
Move-File 'lib/features/map_navigation/data/repositories/map_navigation_repository.dart' 'lib/features/navigation/data/repositories/map_navigation_repository.dart'
Move-File 'lib/core/navigation/route_off_route.dart' 'lib/features/navigation/core/route_off_route.dart'
Move-File 'lib/core/route_snap_warning.dart' 'lib/features/navigation/core/route_snap_warning.dart'
Move-File 'lib/core/utils/polyline_utils.dart' 'lib/features/navigation/core/polyline_utils.dart'
Move-File 'lib/core/utils/route_label_utils.dart' 'lib/features/navigation/core/route_label_utils.dart'
Move-File 'lib/core/utils/route_progress_utils.dart' 'lib/features/navigation/core/route_progress_utils.dart'
Move-File 'lib/models/navigation_route.dart' 'lib/features/navigation/data/models/navigation_route.dart'
Move-File 'lib/services/navigation_session_store.dart' 'lib/features/navigation/data/session/navigation_session_store.dart'
Move-File 'lib/widgets/navigation_hud.dart' 'lib/features/navigation/presentation/widgets/navigation_hud.dart'

# --- Map ---
Move-File 'lib/widgets/map_panel.dart' 'lib/features/map/presentation/widgets/map_panel.dart'
Move-File 'lib/core/map_style.dart' 'lib/features/map/core/map_style.dart'

# --- Geocoding ---
Move-File 'lib/features/map_navigation/data/services/nominatim_geocoding_service.dart' 'lib/features/geocoding/data/services/nominatim_geocoding_service.dart'
Move-File 'lib/features/map_navigation/data/models/address_components.dart' 'lib/features/geocoding/data/models/address_components.dart'
Move-File 'lib/features/map_navigation/data/exceptions/map_navigation_exceptions.dart' 'lib/features/geocoding/data/exceptions/map_navigation_exceptions.dart'
Move-File 'lib/models/place_model.dart' 'lib/features/geocoding/data/models/place_model.dart'
Move-File 'lib/widgets/map_search_bar.dart' 'lib/features/geocoding/presentation/widgets/map_search_bar.dart'
Move-File 'lib/widgets/place_suggestions_panel.dart' 'lib/features/geocoding/presentation/widgets/place_suggestions_panel.dart'
Move-File 'lib/core/place_location_utils.dart' 'lib/features/geocoding/core/place_location_utils.dart'
Move-File 'lib/core/vietnamese_text_utils.dart' 'lib/features/geocoding/core/vietnamese_text_utils.dart'

# --- Location ---
Move-File 'lib/services/location_service.dart' 'lib/features/location/data/services/location_service.dart'
Move-File 'lib/core/navigation/gps_position_filter.dart' 'lib/features/location/core/gps_position_filter.dart'
Move-File 'lib/core/navigation/gps_tracking_policy.dart' 'lib/features/location/core/gps_tracking_policy.dart'

# --- Fuel: intelligence ---
Move-File 'lib/intelligence/consumption/fuel_consumption_model.dart' 'lib/features/fuel/intelligence/consumption/fuel_consumption_model.dart'
Move-File 'lib/intelligence/driving_behavior/driving_behavior_analyzer.dart' 'lib/features/fuel/intelligence/driving_behavior/driving_behavior_analyzer.dart'
Move-File 'lib/intelligence/driving_behavior/driving_behavior_models.dart' 'lib/features/fuel/intelligence/driving_behavior/driving_behavior_models.dart'
Move-File 'lib/intelligence/prediction/fuel_prediction_engine.dart' 'lib/features/fuel/intelligence/prediction/fuel_prediction_engine.dart'
Move-File 'lib/intelligence/prediction/fuel_prediction_models.dart' 'lib/features/fuel/intelligence/prediction/fuel_prediction_models.dart'
Move-File 'lib/intelligence/simulation/route_fuel_simulation_engine.dart' 'lib/features/fuel/intelligence/simulation/route_fuel_simulation_engine.dart'
Move-File 'lib/intelligence/telemetry/telemetry_sample.dart' 'lib/features/fuel/intelligence/telemetry/telemetry_sample.dart'
Move-File 'lib/intelligence/warnings/fuel_warning_models.dart' 'lib/features/fuel/intelligence/warnings/fuel_warning_models.dart'
Move-File 'lib/intelligence/warnings/warnings_engine.dart' 'lib/features/fuel/intelligence/warnings/warnings_engine.dart'

# --- Fuel: presentation (from fuel_intelligence) ---
Move-File 'lib/features/fuel_intelligence/screens/fuel_intelligence_screen.dart' 'lib/features/fuel/presentation/screens/fuel_intelligence_screen.dart'
Move-File 'lib/features/fuel_intelligence/viewmodels/fuel_intelligence_view_model.dart' 'lib/features/fuel/presentation/viewmodels/fuel_intelligence_view_model.dart'
Move-File 'lib/features/fuel_intelligence/widgets/fuel_consumption_graph.dart' 'lib/features/fuel/presentation/widgets/fuel_consumption_graph.dart'
Move-File 'lib/features/fuel_intelligence/widgets/fuel_intelligence_shell.dart' 'lib/features/fuel/presentation/widgets/fuel_intelligence_shell.dart'
Move-File 'lib/features/fuel_intelligence/widgets/fuel_weather_card.dart' 'lib/features/fuel/presentation/widgets/fuel_weather_card.dart'

# --- Fuel: services + models ---
Move-File 'lib/services/fuel_service.dart' 'lib/features/fuel/data/services/fuel_service.dart'
Move-File 'lib/services/route_fuel_service.dart' 'lib/features/fuel/data/services/route_fuel_service.dart'
Move-File 'lib/services/fuel_station_service.dart' 'lib/features/fuel/data/services/fuel_station_service.dart'
Move-File 'lib/services/gas_station_service.dart' 'lib/features/fuel/data/services/gas_station_service.dart'
Move-File 'lib/services/elevation_service.dart' 'lib/features/fuel/data/services/elevation_service.dart'
Move-File 'lib/services/weather_service.dart' 'lib/features/fuel/data/services/weather_service.dart'
Move-File 'lib/models/gas_station.dart' 'lib/features/fuel/data/models/gas_station.dart'
Move-File 'lib/models/fuel_warning_event.dart' 'lib/features/fuel/data/models/fuel_warning_event.dart'
Move-File 'lib/models/route_fuel_analysis.dart' 'lib/features/fuel/data/models/route_fuel_analysis.dart'
Move-File 'lib/models/trip_fuel_status.dart' 'lib/features/fuel/data/models/trip_fuel_status.dart'
Move-File 'lib/models/refuel_flow_phase.dart' 'lib/features/fuel/data/models/refuel_flow_phase.dart'
Move-File 'lib/models/weather_snapshot.dart' 'lib/features/fuel/data/models/weather_snapshot.dart'

# --- Core network/config ---
Move-File 'lib/core/osm_http.dart' 'lib/core/network/osm_http.dart'
Move-File 'lib/core/osm_config.dart' 'lib/core/config/osm_config.dart'
Move-File 'lib/core/constants.dart' 'lib/core/config/constants.dart'
Move-File 'lib/core/lan_dev_config.dart' 'lib/core/config/lan_dev_config.dart'

# --- Shared ---
Move-File 'lib/providers/app_providers.dart' 'lib/shared/providers/app_providers.dart'
Move-File 'lib/services/notification_service.dart' 'lib/shared/services/notification_service.dart'
Move-File 'lib/services/user_session_service.dart' 'lib/shared/services/user_session_service.dart'
Move-File 'lib/services/ios_system_bridge.dart' 'lib/features/home_ios/data/ios_system_bridge.dart'
Move-File 'lib/screens/home_screen.dart' 'lib/shared/screens/home_screen.dart'
Move-File 'lib/screens/profile_settings_sheet.dart' 'lib/shared/screens/profile_settings_sheet.dart'
Move-File 'lib/widgets/cinematic_sheet.dart' 'lib/shared/widgets/cinematic_sheet.dart'
Move-File 'lib/widgets/ios_style_widgets.dart' 'lib/shared/widgets/ios_style_widgets.dart'
Move-File 'lib/widgets/iphone_17_pro_max_frame.dart' 'lib/shared/widgets/iphone_17_pro_max_frame.dart'
Move-File 'lib/widgets/vehicle_bottom_nav.dart' 'lib/shared/widgets/vehicle_bottom_nav.dart'
Move-File 'lib/widgets/vehicle_dashboard_panel.dart' 'lib/shared/widgets/vehicle_dashboard_panel.dart'
Move-File 'lib/widgets/web_lan_debug_overlay.dart' 'lib/shared/widgets/web_lan_debug_overlay.dart'

# --- Cleanup empty dirs ---
@(
  'lib/features/map_navigation',
  'lib/intelligence',
  'lib/features/fuel_intelligence',
  'lib/providers',
  'lib/screens',
  'lib/services',
  'lib/models',
  'lib/widgets',
  'lib/core/navigation',
  'lib/core/utils'
) | ForEach-Object {
  if (Test-Path $_) {
    Get-ChildItem $_ -Recurse -ErrorAction SilentlyContinue | Out-Null
    if (-not (Get-ChildItem $_ -Recurse -File -ErrorAction SilentlyContinue)) {
      Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue
      Write-Host "REMOVED empty dir $_"
    }
  }
}

# --- Import path segment replacements (longest first) ---
$replacements = [ordered]@{
  'features/map_navigation/data/services/osrm_routing_service' = 'features/navigation/data/services/osrm_routing_service'
  'features/map_navigation/data/services/osrm_route_parser' = 'features/navigation/data/services/osrm_route_parser'
  'features/map_navigation/data/services/nominatim_geocoding_service' = 'features/geocoding/data/services/nominatim_geocoding_service'
  'features/map_navigation/data/repositories/map_navigation_repository' = 'features/navigation/data/repositories/map_navigation_repository'
  'features/map_navigation/data/models/address_components' = 'features/geocoding/data/models/address_components'
  'features/map_navigation/data/models/route_plan' = 'features/navigation/data/models/route_plan'
  'features/map_navigation/data/exceptions/map_navigation_exceptions' = 'features/geocoding/data/exceptions/map_navigation_exceptions'
  'features/fuel_intelligence/screens/fuel_intelligence_screen' = 'features/fuel/presentation/screens/fuel_intelligence_screen'
  'features/fuel_intelligence/viewmodels/fuel_intelligence_view_model' = 'features/fuel/presentation/viewmodels/fuel_intelligence_view_model'
  'features/fuel_intelligence/widgets/fuel_intelligence_shell' = 'features/fuel/presentation/widgets/fuel_intelligence_shell'
  'features/fuel_intelligence/widgets/fuel_consumption_graph' = 'features/fuel/presentation/widgets/fuel_consumption_graph'
  'features/fuel_intelligence/widgets/fuel_weather_card' = 'features/fuel/presentation/widgets/fuel_weather_card'
  'core/navigation/gps_tracking_policy' = 'features/location/core/gps_tracking_policy'
  'core/navigation/gps_position_filter' = 'features/location/core/gps_position_filter'
  'core/navigation/route_off_route' = 'features/navigation/core/route_off_route'
  'core/utils/route_progress_utils' = 'features/navigation/core/route_progress_utils'
  'core/utils/route_label_utils' = 'features/navigation/core/route_label_utils'
  'core/utils/polyline_utils' = 'features/navigation/core/polyline_utils'
  'services/navigation_session_store' = 'features/navigation/data/session/navigation_session_store'
  'services/fuel_station_service' = 'features/fuel/data/services/fuel_station_service'
  'services/gas_station_service' = 'features/fuel/data/services/gas_station_service'
  'services/route_fuel_service' = 'features/fuel/data/services/route_fuel_service'
  'services/elevation_service' = 'features/fuel/data/services/elevation_service'
  'services/notification_service' = 'shared/services/notification_service'
  'services/user_session_service' = 'shared/services/user_session_service'
  'services/ios_system_bridge' = 'features/home_ios/data/ios_system_bridge'
  'services/weather_service' = 'features/fuel/data/services/weather_service'
  'services/location_service' = 'features/location/data/services/location_service'
  'services/fuel_service' = 'features/fuel/data/services/fuel_service'
  'models/navigation_route' = 'features/navigation/data/models/navigation_route'
  'models/fuel_warning_event' = 'features/fuel/data/models/fuel_warning_event'
  'models/route_fuel_analysis' = 'features/fuel/data/models/route_fuel_analysis'
  'models/refuel_flow_phase' = 'features/fuel/data/models/refuel_flow_phase'
  'models/weather_snapshot' = 'features/fuel/data/models/weather_snapshot'
  'models/trip_fuel_status' = 'features/fuel/data/models/trip_fuel_status'
  'models/place_model' = 'features/geocoding/data/models/place_model'
  'models/gas_station' = 'features/fuel/data/models/gas_station'
  'widgets/place_suggestions_panel' = 'features/geocoding/presentation/widgets/place_suggestions_panel'
  'widgets/vehicle_dashboard_panel' = 'shared/widgets/vehicle_dashboard_panel'
  'widgets/iphone_17_pro_max_frame' = 'shared/widgets/iphone_17_pro_max_frame'
  'widgets/web_lan_debug_overlay' = 'shared/widgets/web_lan_debug_overlay'
  'widgets/vehicle_bottom_nav' = 'shared/widgets/vehicle_bottom_nav'
  'widgets/ios_style_widgets' = 'shared/widgets/ios_style_widgets'
  'widgets/navigation_hud' = 'features/navigation/presentation/widgets/navigation_hud'
  'widgets/map_search_bar' = 'features/geocoding/presentation/widgets/map_search_bar'
  'widgets/cinematic_sheet' = 'shared/widgets/cinematic_sheet'
  'widgets/map_panel' = 'features/map/presentation/widgets/map_panel'
  'screens/profile_settings_sheet' = 'shared/screens/profile_settings_sheet'
  'screens/home_screen' = 'shared/screens/home_screen'
  'providers/app_providers' = 'shared/providers/app_providers'
  'core/route_snap_warning' = 'features/navigation/core/route_snap_warning'
  'core/place_location_utils' = 'features/geocoding/core/place_location_utils'
  'core/vietnamese_text_utils' = 'features/geocoding/core/vietnamese_text_utils'
  'core/lan_dev_config' = 'core/config/lan_dev_config'
  'core/map_style' = 'features/map/core/map_style'
  'core/osm_config' = 'core/config/osm_config'
  'core/constants' = 'core/config/constants'
  'core/osm_http' = 'core/network/osm_http'
  'intelligence/simulation/route_fuel_simulation_engine' = 'features/fuel/intelligence/simulation/route_fuel_simulation_engine'
  'intelligence/driving_behavior/driving_behavior_analyzer' = 'features/fuel/intelligence/driving_behavior/driving_behavior_analyzer'
  'intelligence/driving_behavior/driving_behavior_models' = 'features/fuel/intelligence/driving_behavior/driving_behavior_models'
  'intelligence/prediction/fuel_prediction_engine' = 'features/fuel/intelligence/prediction/fuel_prediction_engine'
  'intelligence/prediction/fuel_prediction_models' = 'features/fuel/intelligence/prediction/fuel_prediction_models'
  'intelligence/consumption/fuel_consumption_model' = 'features/fuel/intelligence/consumption/fuel_consumption_model'
  'intelligence/telemetry/telemetry_sample' = 'features/fuel/intelligence/telemetry/telemetry_sample'
  'intelligence/warnings/fuel_warning_models' = 'features/fuel/intelligence/warnings/fuel_warning_models'
  'intelligence/warnings/warnings_engine' = 'features/fuel/intelligence/warnings/warnings_engine'
}

$dartFiles = @(
  Get-ChildItem -Path 'lib', 'test' -Recurse -Filter '*.dart' -ErrorAction SilentlyContinue
) | Select-Object -ExpandProperty FullName

foreach ($file in $dartFiles) {
  $content = Get-Content $file -Raw -Encoding UTF8
  $original = $content
  foreach ($key in $replacements.Keys) {
    $val = $replacements[$key]
    $content = $content.Replace($key, $val)
  }
  if ($content -ne $original) {
    Set-Content -Path $file -Value $content -Encoding UTF8 -NoNewline
    Write-Host "UPDATED imports: $file"
  }
}

Write-Host 'Restructure complete.'
