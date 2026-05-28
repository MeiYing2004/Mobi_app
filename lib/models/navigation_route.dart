import 'package:latlong2/latlong.dart';

import 'gas_station.dart';
import 'route_fuel_analysis.dart';

/// Tuyến OSRM tới đích.
class NavigationRoute {
  final GasStation destination;
  final List<LatLng> polylinePoints;
  final double distanceKm;
  final int durationSeconds;
  final DateTime eta;
  final RouteFuelAnalysis fuelAnalysis;

  const NavigationRoute({
    required this.destination,
    required this.polylinePoints,
    required this.distanceKm,
    required this.durationSeconds,
    required this.eta,
    required this.fuelAnalysis,
  });

  String get distanceLabel {
    if (distanceKm < 1) return '${(distanceKm * 1000).round()} m';
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get durationLabel {
    final m = (durationSeconds / 60).round();
    if (m < 60) return '$m phút';
    final h = m ~/ 60;
    final rm = m % 60;
    return rm == 0 ? '$h giờ' : '$h giờ $rm phút';
  }

  String get etaLabel {
    final h = eta.hour.toString().padLeft(2, '0');
    final min = eta.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }
}
