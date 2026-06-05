import 'package:fuel_tracker_app/features/fuel/intelligence/driving_behavior/driving_behavior_models.dart';

enum FuelHealthStatus {
  ok,
  warning,
  critical,
}

enum RouteRiskLevel {
  safe,
  moderate,
  risky,
  critical,
}

enum PredictionConfidence {
  low,
  medium,
  high,
}

class RouteFuelPrediction {
  final double routeDistanceKm;
  final int routeDurationSeconds;
  final double litersRequired;
  final double arrivalFuelLiters;
  final double arrivalFuelPercent;
  final bool insufficientFuel;
  final double? emptyAfterKm;
  final RouteRiskLevel riskLevel;
  final double trafficFactor;
  final double stationDensityScore;
  final List<String> hudInsights;

  const RouteFuelPrediction({
    required this.routeDistanceKm,
    required this.routeDurationSeconds,
    required this.litersRequired,
    required this.arrivalFuelLiters,
    required this.arrivalFuelPercent,
    required this.insufficientFuel,
    required this.emptyAfterKm,
    required this.riskLevel,
    required this.trafficFactor,
    required this.stationDensityScore,
    required this.hudInsights,
  });
}

class FuelPredictionState {
  final double fuelPercent;
  final double remainingRangeKm;
  final Duration timeToEmpty;
  final double currentLPer100Km;
  final double avgLPer100Km;
  final DrivingStyle drivingStyle;
  final FuelHealthStatus health;
  final RouteFuelPrediction? routePrediction;
  final PredictionConfidence confidence;
  final double trafficFactor;
  final RouteRiskLevel? routeRiskLevel;
  final List<String> hudInsights;

  const FuelPredictionState({
    required this.fuelPercent,
    required this.remainingRangeKm,
    required this.timeToEmpty,
    required this.currentLPer100Km,
    required this.avgLPer100Km,
    required this.drivingStyle,
    required this.health,
    required this.routePrediction,
    required this.confidence,
    required this.trafficFactor,
    required this.routeRiskLevel,
    required this.hudInsights,
  });
}

