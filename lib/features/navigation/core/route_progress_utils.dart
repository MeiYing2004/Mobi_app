import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/features/navigation/core/polyline_utils.dart';
import 'package:fuel_tracker_app/features/navigation/core/route_label_utils.dart';

/// Tiến độ dọc tuyến OSRM — dùng cho Dynamic Island / ETA còn lại.
class RouteProgressMetrics {
  const RouteProgressMetrics({
    required this.traveledKm,
    required this.remainingKm,
    required this.progress,
    required this.remainingDurationSeconds,
  });

  final double traveledKm;
  final double remainingKm;
  final double progress;
  final int remainingDurationSeconds;

  String get remainingDistanceLabel =>
      RouteLabelUtils.formatDistanceKm(remainingKm);

  String get etaLabel =>
      RouteLabelUtils.formatEtaForDurationSeconds(remainingDurationSeconds);
}

/// `remaining = totalDistanceKm - traveledAlongPolyline`
RouteProgressMetrics routeProgressMetrics({
  required List<LatLng> routePoints,
  required double totalDistanceKm,
  required int totalDurationSeconds,
  LatLng? userLocation,
}) {
  if (totalDistanceKm <= 0) {
    return const RouteProgressMetrics(
      traveledKm: 0,
      remainingKm: 0,
      progress: 1,
      remainingDurationSeconds: 0,
    );
  }

  var traveledKm = 0.0;
  if (userLocation != null && routePoints.length >= 2) {
    traveledKm = progressAlongRouteKm(routePoints, userLocation) ?? 0.0;
  }

  final remainingKm =
      (totalDistanceKm - traveledKm).clamp(0.0, totalDistanceKm);
  final progress = (traveledKm / totalDistanceKm).clamp(0.0, 1.0);
  final remainingDurationSeconds = totalDurationSeconds > 0
      ? (totalDurationSeconds * (remainingKm / totalDistanceKm)).round()
      : 0;

  return RouteProgressMetrics(
    traveledKm: traveledKm,
    remainingKm: remainingKm,
    progress: progress,
    remainingDurationSeconds: remainingDurationSeconds,
  );
}
