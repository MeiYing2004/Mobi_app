import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/features/geocoding/core/place_location_utils.dart';
import 'package:fuel_tracker_app/features/navigation/core/navigation_performance.dart';
import 'package:fuel_tracker_app/features/navigation/core/route_snap_warning.dart';
import 'package:fuel_tracker_app/features/navigation/core/polyline_utils.dart';
import 'package:fuel_tracker_app/features/geocoding/data/exceptions/map_navigation_exceptions.dart';
import 'package:fuel_tracker_app/features/navigation/data/models/route_plan.dart';

/// Parse và chọn tuyến từ phản hồi OSRM.
class OsrmRouteParser {
  OsrmRouteParser._();

  static const String drivingProfile = 'driving';

  /// Khoảng cách tối thiểu (m) giữa điểm đi và điểm đến.
  static const double minEndpointSeparationM = 8;

  /// Cảnh báo khi polyline đo được lệch so với `distance` OSRM (chỉ overview=full).
  static const double maxPolylineDistanceDrift = 0.01;

  static void validateEndpoints(LatLng origin, LatLng destination) {
    if (!PlaceLocationValidator.isNavigable(origin)) {
      final reason = PlaceLocationValidator.rejectReason(origin) ?? 'invalid';
      throw RoutingException('Điểm xuất phát không hợp lệ ($reason)');
    }
    if (!PlaceLocationValidator.isNavigable(destination)) {
      final reason =
          PlaceLocationValidator.rejectReason(destination) ?? 'invalid';
      throw RoutingException('Điểm đến không hợp lệ ($reason)');
    }

    const distance = Distance();
    final sepM = distance.as(LengthUnit.Meter, origin, destination);
    if (sepM < minEndpointSeparationM) {
      throw const RoutingException(
        'Điểm đi và điểm đến quá gần — hãy chọn đích xa hơn',
      );
    }
  }

  /// GeoJSON coordinates: `[lon, lat]` → `LatLng(lat, lon)`.
  static List<LatLng> pointsFromGeoJsonCoordinates(List<dynamic> coordsList) {
    final buffer = <LatLng>[];
    for (final raw in coordsList) {
      if (raw is! List || raw.length < 2) continue;
      final lon = (raw[0] as num).toDouble();
      final lat = (raw[1] as num).toDouble();
      if (lat.isNaN ||
          lon.isNaN ||
          lat < -90 ||
          lat > 90 ||
          lon < -180 ||
          lon > 180) {
        continue;
      }
      buffer.add(LatLng(lat, lon));
    }
    return buffer;
  }

  /// Giảm số đỉnh polyline khi > [NavigationPerformance.maxPolylinePoints].
  static List<LatLng> capPolylinePoints(
    List<LatLng> points, {
    int maxPoints = NavigationPerformance.maxPolylinePoints,
  }) {
    if (points.length <= maxPoints) return points;
    final out = <LatLng>[points.first];
    final step = (points.length - 1) / (maxPoints - 1);
    for (var i = 1; i < maxPoints - 1; i++) {
      final idx = (i * step).round().clamp(1, points.length - 2);
      out.add(points[idx]);
    }
    out.add(points.last);
    return out;
  }

  /// Chọn tuyến có `duration` ngắn nhất (ưu tiên thời gian lái xe).
  static Map<String, dynamic>? pickBestRoute(List<dynamic> routes) {
    Map<String, dynamic>? best;
    num? bestDuration;
    for (final raw in routes) {
      if (raw is! Map<String, dynamic>) continue;
      final duration = raw['duration'] as num?;
      if (duration == null) continue;
      if (bestDuration == null || duration < bestDuration) {
        bestDuration = duration;
        best = raw;
      }
    }
    return best;
  }

  static RoutePlan parseRoutePlan(
    Map<String, dynamic> route, {
    required bool simplifiedOverview,
    LatLng? requestedDestination,
  }) {
    final geometry = route['geometry'];
    if (geometry is! Map<String, dynamic>) {
      throw const RoutingException('OSRM thiếu geometry');
    }
    final coordsList = geometry['coordinates'];
    if (coordsList is! List<dynamic>) {
      throw const RoutingException('OSRM geometry không hợp lệ');
    }

    var points = pointsFromGeoJsonCoordinates(coordsList);
    if (points.length < 2) {
      throw RoutingException(
        'Polyline OSRM không hợp lệ (${points.length} điểm)',
      );
    }

    final distanceM = route['distance'] as num?;
    final durationSec = route['duration'] as num?;
    if (distanceM == null || durationSec == null) {
      throw const RoutingException('OSRM thiếu distance/duration');
    }

    final distanceKm = distanceM / 1000;
    final durationSeconds = durationSec.round();

    final rawCount = points.length;
    points = capPolylinePoints(points);

    if (!simplifiedOverview) {
      final polylineKm = polylineLengthKm(points);
      final drift = distanceKm > 0
          ? (polylineKm - distanceKm).abs() / distanceKm
          : 0.0;
      debugPrint(
        '[OSRM] parsed profile=$drivingProfile overview=full '
        'rawPoints=$rawCount capped=${points.length} '
        'osrmDistanceKm=${distanceKm.toStringAsFixed(3)} '
        'polylineKm=${polylineKm.toStringAsFixed(3)} '
        'drift=${(drift * 100).toStringAsFixed(2)}% '
        'durationSec=$durationSeconds',
      );
      if (drift > maxPolylineDistanceDrift) {
        debugPrint(
          '[OSRM] WARN polyline drift ${(drift * 100).toStringAsFixed(2)}% '
          '> ${(maxPolylineDistanceDrift * 100).toStringAsFixed(0)}% '
          '(UI vẫn dùng distance OSRM)',
        );
      }
    } else {
      debugPrint(
        '[OSRM] parsed profile=$drivingProfile overview=simplified '
        'rawPoints=$rawCount capped=${points.length} '
        'osrmDistanceKm=${distanceKm.toStringAsFixed(3)} '
        'durationSec=$durationSeconds',
      );
    }

    double? snapMeters;
    if (requestedDestination != null) {
      const distance = Distance();
      snapMeters = distance.as(
        LengthUnit.Meter,
        requestedDestination,
        points.last,
      );
      if (snapMeters >= RouteSnapWarning.ignoreBelowM) {
        debugPrint(
          '[OSRM] destination snap ${snapMeters.round()}m '
          '(requested ${requestedDestination.latitude},${requestedDestination.longitude} '
          '→ routed ${points.last.latitude},${points.last.longitude})',
        );
      }
    }

    return RoutePlan(
      points: points,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      destinationSnapMeters: snapMeters,
    );
  }

  static String messageForOsrmCode(String? code) {
    switch (code) {
      case 'NoRoute':
        return 'Không có đường lái xe nối hai điểm — thử địa điểm gần đường';
      case 'NoSegment':
        return 'Điểm nằm xa mạng lưới đường — chọn vị trí gần lộ giao thông';
      case 'InvalidInput':
      case 'InvalidQuery':
      case 'InvalidValue':
        return 'Tọa độ hoặc tham số tuyến không hợp lệ';
      default:
        return code == null || code.isEmpty ? 'Không lấy được tuyến' : 'OSRM: $code';
    }
  }
}
