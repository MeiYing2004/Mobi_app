import 'dart:math' as math;

import '../../services/fuel_service.dart';
import '../consumption/fuel_consumption_model.dart';
import '../driving_behavior/driving_behavior_models.dart';
import 'fuel_prediction_models.dart';

class FuelPredictionEngine {
  final FuelConsumptionModel _consumptionModel;

  // EMA for average consumption.
  double _avgLPer100KmEma = 8.5;
  DateTime? _lastTick;

  FuelPredictionEngine({FuelConsumptionModel? consumptionModel})
      : _consumptionModel = consumptionModel ?? const FuelConsumptionModel();

  void reset() {
    _avgLPer100KmEma = 8.5;
    _lastTick = null;
  }

  FuelPredictionState tick({
    required FuelService fuel,
    required DrivingBehaviorMetrics behavior,
    required double? speedKmh,
    RouteFuelPrediction? routePrediction,
    required bool isIdling,
    required double elevationFactor,
    required double trafficFactor,
    List<String> hudInsights = const [],
    PredictionConfidence? confidenceOverride,
  }) {
    final now = DateTime.now();
    final dtSeconds = _lastTick == null
        ? 1.0
        : math.max(0.2, now.difference(_lastTick!).inMilliseconds / 1000.0);
    _lastTick = now;

    final base = fuel.baseLPer100Km;
    final out = _consumptionModel.compute(
      FuelConsumptionModelInputs(
        baseLPer100Km: base,
        speedKmh: speedKmh,
        behavior: behavior,
        isIdling: isIdling,
        elevationFactor: elevationFactor,
      ),
    );

    // EMA: stronger smoothing at high frequency.
    final alpha = (0.08 * dtSeconds).clamp(0.02, 0.14);
    _avgLPer100KmEma = alpha * out.currentLPer100Km +
        (1 - alpha) * _avgLPer100KmEma;

    final liters = fuel.currentFuelLiters;
    final remainingRangeKm =
        liters > 0 ? (liters / (out.currentLPer100Km / 100.0)) : 0.0;

    final timeToEmpty = _timeToEmpty(
      remainingRangeKm: remainingRangeKm,
      speedKmh: speedKmh,
      isIdling: isIdling,
    );

    final health = _health(
      fuelPercent: fuel.fuelPercent,
      remainingRangeKm: remainingRangeKm,
      routePrediction: routePrediction,
    );

    final confidence = confidenceOverride ??
        _confidence(
      speedKmh: speedKmh,
      behavior: behavior,
      fuelLiters: liters,
    );

    return FuelPredictionState(
      fuelPercent: fuel.fuelPercent,
      remainingRangeKm: remainingRangeKm,
      timeToEmpty: timeToEmpty,
      currentLPer100Km: out.currentLPer100Km,
      avgLPer100Km: _avgLPer100KmEma,
      drivingStyle: behavior.style,
      health: health,
      routePrediction: routePrediction,
      confidence: confidence,
      trafficFactor: trafficFactor,
      routeRiskLevel: routePrediction?.riskLevel,
      hudInsights: hudInsights,
    );
  }

  Duration _timeToEmpty({
    required double remainingRangeKm,
    required double? speedKmh,
    required bool isIdling,
  }) {
    if (remainingRangeKm <= 0.1) return Duration.zero;
    final v = speedKmh ?? 0;
    if (v >= 6) {
      final hours = remainingRangeKm / v;
      return Duration(seconds: (hours * 3600).round());
    }
    if (isIdling) {
      // Conservative fallback if idling: show a short horizon.
      return const Duration(minutes: 45);
    }
    return const Duration(hours: 2);
  }

  FuelHealthStatus _health({
    required double fuelPercent,
    required double remainingRangeKm,
    required RouteFuelPrediction? routePrediction,
  }) {
    if (routePrediction != null && routePrediction.insufficientFuel) {
      return FuelHealthStatus.critical;
    }
    if (fuelPercent <= 10 || remainingRangeKm <= 20) return FuelHealthStatus.warning;
    return FuelHealthStatus.ok;
  }

  PredictionConfidence _confidence({
    required double? speedKmh,
    required DrivingBehaviorMetrics behavior,
    required double fuelLiters,
  }) {
    if (fuelLiters <= 0.1) return PredictionConfidence.low;
    if (speedKmh == null) return PredictionConfidence.low;
    if (behavior.timeAbove90Ratio > 0.4) return PredictionConfidence.medium;
    return PredictionConfidence.high;
  }
}

