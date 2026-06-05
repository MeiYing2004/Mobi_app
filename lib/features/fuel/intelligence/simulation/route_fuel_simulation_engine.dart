import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/features/fuel/intelligence/driving_behavior/driving_behavior_models.dart';

class RouteFuelSegmentUsage {
  final int index;
  final LatLng from;
  final LatLng to;
  final double segKm;
  final double segLiters;
  final double segLPer100Km;
  final double cumulativeKm;
  final double fuelLeftAfterLiters;

  const RouteFuelSegmentUsage({
    required this.index,
    required this.from,
    required this.to,
    required this.segKm,
    required this.segLiters,
    required this.segLPer100Km,
    required this.cumulativeKm,
    required this.fuelLeftAfterLiters,
  });
}

class RouteFuelSimulationResult {
  final double litersRequired;
  final double arrivalFuelLiters;
  final double arrivalFuelPercent;
  final bool insufficientFuel;
  final LatLng? emptyPoint;
  final double? emptyAfterKm;
  final List<RouteFuelSegmentUsage> segments;

  const RouteFuelSimulationResult({
    required this.litersRequired,
    required this.arrivalFuelLiters,
    required this.arrivalFuelPercent,
    required this.insufficientFuel,
    required this.emptyPoint,
    required this.emptyAfterKm,
    required this.segments,
  });
}

/// Simulate fuel usage along route polyline.
///
/// v1: heuristic traffic/elevation modifiers without external traffic API.
class RouteFuelSimulationEngine {
  const RouteFuelSimulationEngine();

  RouteFuelSimulationResult simulate({
    required List<LatLng> routePoints,
    required double tankCapacityLiters,
    required double currentFuelLiters,
    required double baseLPer100Km,
    required DrivingBehaviorMetrics behavior,
    List<double>? elevationMeters,
    double trafficJamFactor = 1.0,
  }) {
    if (routePoints.length < 2) {
      final arrival = currentFuelLiters.clamp(0.0, tankCapacityLiters).toDouble();
      return RouteFuelSimulationResult(
        litersRequired: 0,
        arrivalFuelLiters: arrival,
        arrivalFuelPercent: tankCapacityLiters > 0 ? arrival / tankCapacityLiters * 100 : 0,
        insufficientFuel: false,
        emptyPoint: null,
        emptyAfterKm: null,
        segments: const [],
      );
    }

    const dist = Distance();
    var fuelLeft = currentFuelLiters;
    var litersRequired = 0.0;
    var traveledKm = 0.0;
    final segments = <RouteFuelSegmentUsage>[];

    for (var i = 1; i < routePoints.length; i++) {
      final a = routePoints[i - 1];
      final b = routePoints[i];
      final segKm = dist.as(LengthUnit.Kilometer, a, b);
      if (segKm <= 0) continue;

      final gradeFactor = _gradeFactor(
        i: i,
        elevationMeters: elevationMeters,
        segKm: segKm,
      );
      final styleFactor = behavior.styleFactor;
      final segLPer100 = (baseLPer100Km *
              styleFactor *
              trafficJamFactor.clamp(1.0, 1.35) *
              gradeFactor)
          .clamp(1.2, 40.0)
          .toDouble();

      final segLiters = segKm * (segLPer100 / 100.0);
      litersRequired += segLiters;

      final nextFuel = fuelLeft - segLiters;
      traveledKm += segKm;

      if (nextFuel <= 0.0) {
        // Interpolate empty point inside this segment.
        final ratio = fuelLeft <= 0 ? 0.0 : (fuelLeft / segLiters).clamp(0.0, 1.0);
        final empty = LatLng(
          a.latitude + (b.latitude - a.latitude) * ratio,
          a.longitude + (b.longitude - a.longitude) * ratio,
        );
        final segKmToEmpty = segKm * ratio;
        segments.add(
          RouteFuelSegmentUsage(
            index: i - 1,
            from: a,
            to: b,
            segKm: segKmToEmpty,
            segLiters: fuelLeft.clamp(0.0, segLiters).toDouble(),
            segLPer100Km: segLPer100,
            cumulativeKm: traveledKm - segKm + segKmToEmpty,
            fuelLeftAfterLiters: 0.0,
          ),
        );
        return RouteFuelSimulationResult(
          litersRequired: litersRequired,
          arrivalFuelLiters: 0,
          arrivalFuelPercent: 0,
          insufficientFuel: true,
          emptyPoint: empty,
          emptyAfterKm: traveledKm - segKm + segKm * ratio,
          segments: segments,
        );
      }

      fuelLeft = nextFuel;
      segments.add(
        RouteFuelSegmentUsage(
          index: i - 1,
          from: a,
          to: b,
          segKm: segKm,
          segLiters: segLiters,
          segLPer100Km: segLPer100,
          cumulativeKm: traveledKm,
          fuelLeftAfterLiters: fuelLeft.clamp(0.0, tankCapacityLiters).toDouble(),
        ),
      );
    }

    final arrival = fuelLeft.clamp(0.0, tankCapacityLiters).toDouble();
    return RouteFuelSimulationResult(
      litersRequired: litersRequired,
      arrivalFuelLiters: arrival,
      arrivalFuelPercent: tankCapacityLiters > 0 ? arrival / tankCapacityLiters * 100 : 0,
      insufficientFuel: false,
      emptyPoint: null,
      emptyAfterKm: null,
      segments: segments,
    );
  }

  double _gradeFactor({
    required int i,
    required List<double>? elevationMeters,
    required double segKm,
  }) {
    if (elevationMeters == null) return 1.0;
    if (i <= 0 || i >= elevationMeters.length) return 1.0;
    final prev = elevationMeters[i - 1];
    final cur = elevationMeters[i];
    final dh = cur - prev; // meters
    final slope = dh / math.max(1.0, segKm * 1000.0); // rise/run
    final slopePct = slope * 100.0;

    // Spec:
    // 0–5%: normal
    // 5–10%: +8%
    // >10%: +15%
    // downhill: -5% to -12%
    if (slopePct >= 0) {
      if (slopePct <= 5) return 1.0;
      if (slopePct <= 10) return 1.08;
      return 1.15;
    }

    final down = slopePct.abs();
    if (down >= 10) return 0.88; // -12%
    if (down >= 5) return 0.92; // -8%
    return 0.95; // -5%
  }
}

