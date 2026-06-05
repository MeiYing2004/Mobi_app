import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/features/navigation/core/route_label_utils.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/gas_station.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/route_fuel_analysis.dart';

/// Tuyến OSRM tới đích.
class NavigationRoute {
  final GasStation destination;
  final List<LatLng> polylinePoints;
  final double distanceKm;
  final int durationSeconds;
  final DateTime eta;
  final RouteFuelAnalysis fuelAnalysis;

  /// Cây xăng OSM trong phạm vi quanh tuyến (Overpass).
  final List<GasStation> stationsOnRoute;

  /// Snap đích OSRM so với tọa độ người chọn (m).
  final double? destinationSnapMeters;

  const NavigationRoute({
    required this.destination,
    required this.polylinePoints,
    required this.distanceKm,
    required this.durationSeconds,
    required this.eta,
    required this.fuelAnalysis,
    this.stationsOnRoute = const [],
    this.destinationSnapMeters,
  });

  GasStation? get highlightedRefuelStation =>
      fuelAnalysis.suggestedRefuelOnRoute ??
      fuelAnalysis.suggestedCloserStation;

  String get distanceLabel => RouteLabelUtils.formatDistanceKm(distanceKm);

  String get durationLabel =>
      RouteLabelUtils.formatDurationSeconds(durationSeconds);

  String get etaLabel {
    final h = eta.hour.toString().padLeft(2, '0');
    final min = eta.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }
}
