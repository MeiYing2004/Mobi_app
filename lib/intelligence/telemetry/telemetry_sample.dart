class TelemetrySample {
  final DateTime timestamp;
  final double? speedKmh;
  final double? bearingDeg;

  const TelemetrySample({
    required this.timestamp,
    required this.speedKmh,
    this.bearingDeg,
  });
}

