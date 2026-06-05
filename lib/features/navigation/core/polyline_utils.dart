import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/core/config/constants.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/gas_station.dart';

/// Điểm trên polyline cách điểm đầu [distanceKm] km.
LatLng? pointAlongPolylineAtKm(List<LatLng> points, double distanceKm) {
  if (points.length < 2 || distanceKm <= 0) return points.first;

  const distance = Distance();
  var traveled = 0.0;

  for (var i = 1; i < points.length; i++) {
    final a = points[i - 1];
    final b = points[i];
    final segKm = distance.as(LengthUnit.Kilometer, a, b);
    if (segKm <= 0) continue;

    if (traveled + segKm >= distanceKm) {
      final t = (distanceKm - traveled) / segKm;
      return LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );
    }
    traveled += segKm;
  }

  return points.last;
}

/// Khoảng cách dọc tuyến từ [origin] tới điểm gần [target] nhất trên polyline (km).
double? distanceAlongRouteFromOriginKm(
  List<LatLng> points,
  LatLng origin,
  LatLng target,
) {
  if (points.length < 2) return null;

  const distance = Distance();
  var bestVertexIndex = 0;
  var bestToTarget = double.infinity;
  for (var i = 0; i < points.length; i++) {
    final d = distance.as(LengthUnit.Kilometer, points[i], target);
    if (d < bestToTarget) {
      bestToTarget = d;
      bestVertexIndex = i;
    }
  }

  var along = 0.0;
  for (var i = 1; i <= bestVertexIndex; i++) {
    along += distance.as(LengthUnit.Kilometer, points[i - 1], points[i]);
  }

  final snap = points[bestVertexIndex];
  along += distance.as(LengthUnit.Kilometer, snap, target) * 0.35;
  final fromOrigin = distance.as(LengthUnit.Kilometer, points.first, origin);
  if (fromOrigin > 0.02) {
    along -= fromOrigin * 0.15;
  }
  return along.clamp(0.0, polylineLengthKm(points));
}

double polylineLengthKm(List<LatLng> points) {
  if (points.length < 2) return 0;
  const distance = Distance();
  var total = 0.0;
  for (var i = 1; i < points.length; i++) {
    total += distance.as(LengthUnit.Kilometer, points[i - 1], points[i]);
  }
  return total;
}

/// Khoảng cách ngắn nhất từ [point] tới polyline (km).
double distancePointToPolylineKm(List<LatLng> points, LatLng point) {
  if (points.length < 2) return double.infinity;
  const distance = Distance();
  var best = double.infinity;
  for (var i = 1; i < points.length; i++) {
    final d = _distancePointToSegmentKm(
      points[i - 1],
      points[i],
      point,
      distance,
    );
    if (d < best) best = d;
  }
  return best;
}

double _distancePointToSegmentKm(
  LatLng a,
  LatLng b,
  LatLng p,
  Distance distance,
) {
  final segKm = distance.as(LengthUnit.Kilometer, a, b);
  if (segKm <= 1e-6) {
    return distance.as(LengthUnit.Kilometer, a, p);
  }

  final ax = a.longitude;
  final ay = a.latitude;
  final bx = b.longitude;
  final by = b.latitude;
  final px = p.longitude;
  final py = p.latitude;
  final dx = bx - ax;
  final dy = by - ay;
  final lenSq = dx * dx + dy * dy;
  final t = lenSq <= 0
      ? 0.0
      : (((px - ax) * dx + (py - ay) * dy) / lenSq).clamp(0.0, 1.0);
  final closest = LatLng(ay + dy * t, ax + dx * t);
  return distance.as(LengthUnit.Kilometer, closest, p);
}

/// Thêm điểm trung gian dọc polyline (tuyến OSRM rút gọn có ít đỉnh).
List<LatLng> densifyPolyline(
  List<LatLng> points, {
  double stepKm = 0.05,
}) {
  if (points.length < 2) return points;

  const distance = Distance();
  final out = <LatLng>[points.first];

  for (var i = 1; i < points.length; i++) {
    final a = points[i - 1];
    final b = points[i];
    final segKm = distance.as(LengthUnit.Kilometer, a, b);
    if (segKm <= stepKm) {
      out.add(b);
      continue;
    }

    final steps = (segKm / stepKm).ceil();
    for (var s = 1; s <= steps; s++) {
      final t = s / steps;
      out.add(
        LatLng(
          a.latitude + (b.latitude - a.latitude) * t,
          a.longitude + (b.longitude - a.longitude) * t,
        ),
      );
    }
  }

  return out;
}

/// Tiến độ dọc tuyến (km) từ điểm đầu polyline tới [location].
double? progressAlongRouteKm(List<LatLng> routePoints, LatLng location) {
  if (routePoints.length < 2) return null;
  return distanceAlongRouteFromOriginKm(
    routePoints,
    routePoints.first,
    location,
  );
}

/// Chỉ giữ trạm phía trước (hoặc sát) vị trí người dùng trên tuyến.
List<GasStation> filterStationsAheadOnRoute({
  required List<GasStation> stations,
  required List<LatLng> routePoints,
  required LatLng userLocation,
  double lookBackKm = AppConstants.aheadStationLookBackKm,
  int maxCount = AppConstants.maxAheadStationsOnRoute,
}) {
  if (routePoints.length < 2 || stations.isEmpty) return const [];

  final userKm = progressAlongRouteKm(routePoints, userLocation);
  if (userKm == null) return stations;

  final ahead = <({GasStation station, double alongKm})>[];
  for (final s in stations) {
    final along = progressAlongRouteKm(routePoints, s.location);
    if (along == null) continue;
    if (along >= userKm - lookBackKm) {
      ahead.add((station: s, alongKm: along));
    }
  }

  ahead.sort((a, b) => a.alongKm.compareTo(b.alongKm));
  if (maxCount > 0 && ahead.length > maxCount) {
    return ahead.take(maxCount).map((e) => e.station).toList();
  }
  return ahead.map((e) => e.station).toList();
}

/// Chỉ giữ trạm trong [maxDistanceKm] quanh tuyến đi.
List<GasStation> filterStationsNearPolyline(
  List<GasStation> stations,
  List<LatLng> routePoints, {
  double maxDistanceKm = AppConstants.routeStationCorridorKm,
}) {
  if (routePoints.length < 2) return const [];

  final corridor = densifyPolyline(routePoints);
  return stations
      .where(
        (s) =>
            distancePointToPolylineKm(corridor, s.location) <= maxDistanceKm,
      )
      .toList();
}
