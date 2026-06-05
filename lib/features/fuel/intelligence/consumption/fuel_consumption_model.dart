import 'package:fuel_tracker_app/features/fuel/intelligence/driving_behavior/driving_behavior_models.dart';

class FuelConsumptionModelInputs {
  final double baseLPer100Km;
  final double? speedKmh;
  final DrivingBehaviorMetrics behavior;
  final bool isIdling;
  final double elevationFactor;

  const FuelConsumptionModelInputs({
    required this.baseLPer100Km,
    required this.speedKmh,
    required this.behavior,
    required this.isIdling,
    required this.elevationFactor,
  });
}

class FuelConsumptionModelOutput {
  final double currentLPer100Km;
  final double speedFactor;
  final double stopFactor;
  final double elevationFactor;
  final double styleFactor;

  const FuelConsumptionModelOutput({
    required this.currentLPer100Km,
    required this.speedFactor,
    required this.stopFactor,
    required this.elevationFactor,
    required this.styleFactor,
  });
}

class FuelConsumptionModel {
  const FuelConsumptionModel();

  FuelConsumptionModelOutput compute(FuelConsumptionModelInputs i) {
    final speedFactor = _speedFactor(i.speedKmh);
    // Stop-go traffic heuristic: when idle/stop-go rises, increase consumption.
    final trafficFactor = (1.0 + (i.behavior.stopGoIndex * 0.18)).clamp(1.0, 1.18);
    final stopFactor = (i.isIdling ? 1.12 : 1.0) * trafficFactor;
    final styleFactor = i.behavior.styleFactor;
    final elevationFactor = i.elevationFactor.clamp(0.85, 1.35);

    final current = (i.baseLPer100Km *
            speedFactor *
            stopFactor *
            styleFactor *
            elevationFactor)
        .clamp(1.2, 40.0)
        .toDouble();

    return FuelConsumptionModelOutput(
      currentLPer100Km: current,
      speedFactor: speedFactor,
      stopFactor: stopFactor,
      elevationFactor: elevationFactor,
      styleFactor: styleFactor,
    );
  }

  double _speedFactor(double? speedKmh) {
    if (speedKmh == null) return 1.0;
    final v = speedKmh.clamp(0, 160);
    if (v < 20) return 1.05;
    if (v <= 70) return 1.0;
    if (v <= 90) return 1.05;
    final over = v - 90;
    // +0.12% per km/h over 90, capped.
    return (1.08 + over * 0.0012).clamp(1.0, 1.28).toDouble();
  }
}

