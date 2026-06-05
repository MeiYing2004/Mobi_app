import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/features/location/core/gps_tracking_policy.dart';
import 'package:fuel_tracker_app/features/navigation/core/polyline_utils.dart';

/// Hành động khi GPS lệch khỏi polyline tuyến.
enum OffRouteAction {
  onRoute,
  updateProgressOnly,
  triggerReroute,
  immediateReroute,
}

OffRouteAction classifyOffRouteMeters(double meters) {
  if (meters >= GpsTrackingPolicy.rerouteImmediateM) {
    return OffRouteAction.immediateReroute;
  }
  if (meters >= GpsTrackingPolicy.rerouteTriggerM) {
    return OffRouteAction.triggerReroute;
  }
  if (meters >= GpsTrackingPolicy.onRouteMaxM) {
    return OffRouteAction.updateProgressOnly;
  }
  return OffRouteAction.onRoute;
}

/// Khoảng cách ngắn nhất từ [point] tới polyline (m).
/// [precomputedCorridor] — corridor đã densify (cache từ shell), tránh tính lại mỗi tick GPS.
double offRouteDistanceM(
  List<LatLng> routePoints,
  LatLng point, {
  List<LatLng>? precomputedCorridor,
}) {
  if (routePoints.length < 2) return double.infinity;
  final corridor = precomputedCorridor ?? densifyPolyline(routePoints);
  return distancePointToPolylineKm(corridor, point) * 1000;
}
