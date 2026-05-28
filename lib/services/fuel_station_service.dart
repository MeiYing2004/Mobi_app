import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/gas_station.dart';
import 'gas_station_service.dart';

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

  /// Find stations along a route by sampling the polyline.
  ///
  /// Notes:
  /// - This is Overpass-heavy; we keep it conservative by sampling.
  /// - Deduplicates by `id` (`type_id`).
  Future<List<GasStation>> stationsAlongRoute({
    required List<LatLng> routePoints,
    required LatLng origin,
    required double routeDistanceKm,
    double sampleEveryKm = 12,
    double radiusKm = 2.0,
    int perSampleLimit = 10,
    int maxStations = 30,
  }) async {
    if (routePoints.length < 2) return const [];

    final sampleCount =
        math.max(1, (routeDistanceKm / sampleEveryKm).floor());
    final step = (routePoints.length / (sampleCount + 1)).floor().clamp(1, 9999);

    final seen = <String>{};
    final out = <GasStation>[];

    for (var i = step; i < routePoints.length && out.length < maxStations; i += step) {
      final p = routePoints[i];
      final stations = await _nearby.findNearestStations(
        origin: p,
        radiusKm: radiusKm,
        limit: perSampleLimit,
        forceRefresh: true,
      );
      for (final s in stations) {
        if (seen.add(s.id)) {
          out.add(s);
          if (out.length >= maxStations) break;
        }
      }
    }

    // Sort by distance from current origin (not the sample point).
    out.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return out;
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
    final d = const Distance();
    var best = double.infinity;
    // Brute-force nearest route vertex (v1). Good enough for small candidate sets.
    for (final r in routePoints) {
      final km = d.as(LengthUnit.Kilometer, p, r);
      if (km < best) best = km;
    }
    return best.isFinite ? best : 0.0;
  }

  double _routeDirectionPenalty(LatLng station, List<LatLng>? routePoints) {
    if (routePoints == null || routePoints.length < 2) return 0.0;
    final origin = routePoints.first;
    final destination = routePoints.last;
    final d = const Distance();

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

