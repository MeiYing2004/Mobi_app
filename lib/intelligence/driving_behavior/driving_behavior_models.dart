enum DrivingStyle {
  eco,
  normal,
  aggressive,
}

class DrivingBehaviorMetrics {
  final DrivingStyle style;
  final double styleFactor;
  final double accelMps2Ema;
  final double harshAccelPerMin;
  final double harshBrakePerMin;
  final double stopPerKm;
  final double timeAbove90Ratio;
  final double corneringAggressiveness;
  final double idleRatio;
  final double stopGoIndex;

  const DrivingBehaviorMetrics({
    required this.style,
    required this.styleFactor,
    required this.accelMps2Ema,
    required this.harshAccelPerMin,
    required this.harshBrakePerMin,
    required this.stopPerKm,
    required this.timeAbove90Ratio,
    required this.corneringAggressiveness,
    required this.idleRatio,
    required this.stopGoIndex,
  });
}

