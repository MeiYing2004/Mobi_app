import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/core/config/constants.dart';
import 'package:fuel_tracker_app/features/navigation/core/polyline_utils.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/gas_station.dart';
import 'package:fuel_tracker_app/features/fuel/data/services/gas_station_service.dart';

class FuelStationCandidate {
  final GasStation station;
  final double distanceToRouteKm;
  final double distanceFromOriginKm;
  final bool reachableWithCurrentFuel;

  const FuelStationCandidate({
    required this.station,
    required this.distanceToRouteKm,
    required this.distanceFromOriginKm,
    required this.reachableWithCurrentFuel,
  });
}

class RankedFuelStation {
  final GasStation station;
  final double score;
  final double detourPenaltyKm;
  final double safetyMarginKm;

  const RankedFuelStation({
    required this.station,
    required this.score,
    required this.detourPenaltyKm,
    required this.safetyMarginKm,
  });
}

/// Higher-level station logic on top of Overpass.
class FuelStationService {
  /// Trạm cách tuyến đi tối đa bao nhiêu km thì coi là "gần đường".
  static const double routeCorridorMaxKm = AppConstants.routeStationCorridorKm;

  /// Bán kính Overpass quanh mỗi điểm mẫu (fallback khi bbox quá lớn).
  static const double routeSearchRadiusKm = 1.5;

  /// Khoảng cách mẫu dọc tuyến — phải ≤ 2× bán kính tìm kiếm để không bỏ sót trạm.
  static const double routeSampleEveryKm = 2.0;

  final GasStationService _nearby;

  FuelStationService({GasStationService? nearby})
      : _nearby = nearby ?? GasStationService();

  Future<List<GasStation>> nearbyStations({
    required LatLng origin,
    double radiusKm = 5,
    int limit = 20,
    bool forceRefresh = false,
  }) {
    return _nearby.findNearestStations(
      origin: origin,
      radiusKm: radiusKm,
      limit: limit,
      forceRefresh: forceRefresh,
    );
  }

  /// Find stations along a route.
  ///
  /// Ưu tiên một truy vấn bbox quanh tuyến; fallback mẫu tuần tự nếu bbox quá rộng.
  Future<List<GasStation>> stationsAlongRoute({
    required List<LatLng> routePoints,
    required LatLng origin,
    required double routeDistanceKm,
    double sampleEveryKm = routeSampleEveryKm,
    double radiusKm = routeSearchRadiusKm,
    double destinationRadiusKm = routeSearchRadiusKm,
    double maxOnRouteKm = routeCorridorMaxKm,
    int perSampleLimit = 24,
    int maxSamples = 30,
    int maxStations = 100,
  }) async {
    if (routePoints.length < 2) return const [];

    final raw = await _fetchStationsForRoute(
      routePoints: routePoints,
      routeDistanceKm: routeDistanceKm,
      origin: origin,
      sampleEveryKm: sampleEveryKm,
      radiusKm: radiusKm,
      destinationRadiusKm: destinationRadiusKm,
      perSampleLimit: perSampleLimit,
      maxSamples: maxSamples,
    );

    final withOrigin = _withDistanceFromOrigin(raw, origin);
    final onRoute = filterStationsNearPolyline(
      withOrigin,
      routePoints,
      maxDistanceKm: maxOnRouteKm,
    );

    onRoute.sort((a, b) {
      final corridor = densifyPolyline(routePoints);
      final byRoute = distancePointToPolylineKm(corridor, a.location)
          .compareTo(distancePointToPolylineKm(corridor, b.location));
      if (byRoute != 0) return byRoute;
      return a.distanceKm.compareTo(b.distanceKm);
    });

    if (onRoute.length <= maxStations) return onRoute;
    return onRoute.sublist(0, maxStations);
  }

  Future<List<GasStation>> _fetchStationsForRoute({
    required List<LatLng> routePoints,
    required double routeDistanceKm,
    required LatLng origin,
    required double sampleEveryKm,
    required double radiusKm,
    required double destinationRadiusKm,
    required int perSampleLimit,
    required int maxSamples,
  }) async {
    final corridorPad =
        (routeCorridorMaxKm / 111.0).clamp(0.008, 0.025);
    final bbox = _routeBoundingBox(routePoints, paddingDeg: corridorPad);
    if (bbox != null && _bboxDiagonalKm(bbox) <= 180) {
      final fromBbox = await _nearby.findStationsInBounds(
        south: bbox.south,
        west: bbox.west,
        north: bbox.north,
        east: bbox.east,
        originForDistance: origin,
        limit: 400,
      );
      if (fromBbox.isNotEmpty) return fromBbox;
    }

    return _fetchStationsBySampling(
      routePoints: routePoints,
      routeDistanceKm: routeDistanceKm,
      sampleEveryKm: sampleEveryKm,
      radiusKm: radiusKm,
      destinationRadiusKm: destinationRadiusKm,
      perSampleLimit: perSampleLimit,
      maxSamples: maxSamples,
    );
  }

  ({double south, double west, double north, double east})? _routeBoundingBox(
    List<LatLng> points, {
    required double paddingDeg,
  }) {
    if (points.isEmpty) return null;
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLon = points.first.longitude;
    var maxLon = points.first.longitude;
    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLon = math.min(minLon, p.longitude);
      maxLon = math.max(maxLon, p.longitude);
    }
    return (
      south: minLat - paddingDeg,
      west: minLon - paddingDeg,
      north: maxLat + paddingDeg,
      east: maxLon + paddingDeg,
    );
  }

  double _bboxDiagonalKm(({double south, double west, double north, double east}) b) {
    const d = Distance();
    return d.as(
      LengthUnit.Kilometer,
      LatLng(b.south, b.west),
      LatLng(b.north, b.east),
    );
  }

  /// Mẫu tuần tự — tránh gửi hàng chục request Overpass song song bị rate-limit.
  Future<List<GasStation>> _fetchStationsBySampling({
    required List<LatLng> routePoints,
    required double routeDistanceKm,
    required double sampleEveryKm,
    required double radiusKm,
    required double destinationRadiusKm,
    required int perSampleLimit,
    required int maxSamples,
  }) async {
    final samplePoints = _buildRouteSamplePoints(
      routePoints: routePoints,
      routeDistanceKm: routeDistanceKm,
      sampleEveryKm: sampleEveryKm,
      maxSamples: maxSamples,
    );
    if (samplePoints.isEmpty) return const [];

    final destination = routePoints.last;
    final seen = <String>{};
    final out = <GasStation>[];

    for (final p in samplePoints) {
      final radius =
          _sameLatLng(p, destination) ? destinationRadiusKm : radiusKm;
      final stations = await _nearby.findNearestStations(
        origin: p,
        radiusKm: radius,
        limit: perSampleLimit,
        forceRefresh: true,
      );
      for (final s in stations) {
        if (seen.add(s.id)) out.add(s);
      }
    }

    return out;
  }

  /// Điểm mẫu dọc tuyến — điểm đầu, cuối + chia đều theo km trên polyline.
  List<LatLng> _buildRouteSamplePoints({
    required List<LatLng> routePoints,
    required double routeDistanceKm,
    required double sampleEveryKm,
    int maxSamples = 20,
  }) {
    final points = <LatLng>[];
    final seen = <String>{};

    void add(LatLng p) {
      if (points.length >= maxSamples) return;
      final key =
          '${p.latitude.toStringAsFixed(5)}:${p.longitude.toStringAsFixed(5)}';
      if (seen.add(key)) points.add(p);
    }

    add(routePoints.first);
    add(routePoints.last);

    if (routeDistanceKm <= sampleEveryKm) return points;

    var km = sampleEveryKm;
    while (km < routeDistanceKm - (sampleEveryKm * 0.35)) {
      final p = pointAlongPolylineAtKm(routePoints, km);
      if (p != null) add(p);
      km += sampleEveryKm;
    }

    return points;
  }

  bool _sameLatLng(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < 0.00001 &&
        (a.longitude - b.longitude).abs() < 0.00001;
  }

  List<GasStation> _withDistanceFromOrigin(List<GasStation> stations, LatLng origin) {
    const d = Distance();
    final withOriginDistance = stations
        .map(
          (s) => GasStation(
            id: s.id,
            osmType: s.osmType,
            osmId: s.osmId,
            name: s.name,
            address: s.address,
            location: s.location,
            distanceKm: d.as(LengthUnit.Kilometer, origin, s.location),
            brand: s.brand,
            operatorName: s.operatorName,
            openingHours: s.openingHours,
            phone: s.phone,
            website: s.website,
            fuelTypes: s.fuelTypes,
            services: s.services,
            tags: s.tags,
          ),
        )
        .toList();
    withOriginDistance.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return withOriginDistance;
  }

  /// Cây xăng gần nhất phía trước trên tuyến (từ [from]).
  GasStation? nearestAheadOnRoute({
    required List<GasStation> stations,
    required List<LatLng> routePoints,
    required LatLng from,
  }) {
    if (stations.isEmpty || routePoints.length < 2) return null;

    GasStation? best;
    var bestAlong = double.infinity;
    for (final s in stations) {
      final along = distanceAlongRouteFromOriginKm(
        routePoints,
        from,
        s.location,
      );
      if (along == null || along < 0.05) continue;
      if (along < bestAlong) {
        bestAlong = along;
        best = s;
      }
    }
    return best;
  }

  /// Emergency recommendation: pick the best reachable station.
  GasStation? recommendEmergencyStation({
    required List<GasStation> nearby,
    required double remainingRangeKm,
    double bufferKm = 8,
    List<LatLng>? routePoints,
    double routeDistanceKm = 0,
    double trafficFactor = 1.0,
  }) {
    final ranked = rankStationsForRoute(
      nearby: nearby,
      remainingRangeKm: remainingRangeKm,
      routePoints: routePoints,
      routeDistanceKm: routeDistanceKm,
      trafficFactor: trafficFactor,
      bufferKm: bufferKm,
    );
    if (ranked.isEmpty) return null;
    return ranked.first.station;
  }

  List<RankedFuelStation> rankStationsForRoute({
    required List<GasStation> nearby,
    required double remainingRangeKm,
    List<LatLng>? routePoints,
    double routeDistanceKm = 0,
    double trafficFactor = 1.0,
    double bufferKm = 8,
  }) {
    final reachLimit = math.max(
      0.0,
      remainingRangeKm - (bufferKm * trafficFactor.clamp(1.0, 1.35)),
    );

    final out = <RankedFuelStation>[];
    for (final s in nearby) {
      final detour = _distanceToRouteKm(s.location, routePoints);
      if (routePoints != null &&
          routePoints.length >= 2 &&
          detour > AppConstants.routeStationCorridorKm) {
        continue;
      }
      final reachable = s.distanceKm <= reachLimit;
      if (!reachable) continue;

      final routeDirectionPenalty = _routeDirectionPenalty(
        s.location,
        routePoints,
      );
      final openBonus = _openStatusBonus(s);
      final safetyMarginKm = reachLimit - s.distanceKm;
      final detourPenalty = detour * 1.45 + routeDirectionPenalty;
      final score = (safetyMarginKm * 1.2) - (detourPenalty * 2.6) + openBonus;

      out.add(
        RankedFuelStation(
          station: s,
          score: score,
          detourPenaltyKm: detourPenalty,
          safetyMarginKm: safetyMarginKm,
        ),
      );
    }

    out.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.station.distanceKm.compareTo(b.station.distanceKm);
    });
    return out;
  }

  double _distanceToRouteKm(LatLng p, List<LatLng>? routePoints) {
    if (routePoints == null || routePoints.length < 2) return 0.0;
    return distancePointToPolylineKm(densifyPolyline(routePoints), p);
  }

  double _routeDirectionPenalty(LatLng station, List<LatLng>? routePoints) {
    if (routePoints == null || routePoints.length < 2) return 0.0;
    final origin = routePoints.first;
    final destination = routePoints.last;
    const d = Distance();

    final directToDestKm = d.as(LengthUnit.Kilometer, origin, destination);
    final viaStationKm =
        d.as(LengthUnit.Kilometer, origin, station) +
        d.as(LengthUnit.Kilometer, station, destination);
    return math.max(0.0, viaStationKm - directToDestKm);
  }

  double _openStatusBonus(GasStation station) {
    final hours = station.openingHoursLabel.toLowerCase();
    if (hours.contains('24') || hours.contains('always')) return 2.2;
    if (hours.contains('close') || hours.contains('đóng')) return -2.0;
    return 0.5;
  }
}

