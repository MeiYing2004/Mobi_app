import 'dart:math' as math;

import '../telemetry/telemetry_sample.dart';
import 'driving_behavior_models.dart';

class DrivingBehaviorAnalyzer {
  static const double _harshAccelThreshold = 2.6; // m/s^2
  static const double _harshBrakeThreshold = -3.2; // m/s^2

  // EMA smoothing for acceleration.
  static const double _accelAlpha = 0.22;

  TelemetrySample? _prev;
  double _accelEma = 0;
  int _harshAccelCount = 0;
  int _harshBrakeCount = 0;
  int _stopCount = 0;

  int _above90Count = 0;
  int _totalSpeedSamples = 0;

  int _idleSamples = 0;
  double _cornerScoreEma = 0;
  static const double _cornerAlpha = 0.18;

  double _distanceKmSinceReset = 0;
  DateTime? _startTime;

  void reset({DateTime? now}) {
    _prev = null;
    _accelEma = 0;
    _harshAccelCount = 0;
    _harshBrakeCount = 0;
    _stopCount = 0;
    _above90Count = 0;
    _totalSpeedSamples = 0;
    _idleSamples = 0;
    _cornerScoreEma = 0;
    _distanceKmSinceReset = 0;
    _startTime = now ?? DateTime.now();
  }

  /// Feed a new sample. Provide [deltaDistanceKm] from GPS between samples
  /// (if available) to compute stop-per-km.
  void ingest(TelemetrySample sample, {double deltaDistanceKm = 0}) {
    _startTime ??= sample.timestamp;
    _distanceKmSinceReset += math.max(0, deltaDistanceKm);

    final speedKmh = sample.speedKmh;
    if (speedKmh != null) {
      _totalSpeedSamples += 1;
      if (speedKmh >= 90) _above90Count += 1;
      if (speedKmh < 2) _idleSamples += 1;
    }

    if (_prev != null && speedKmh != null && _prev!.speedKmh != null) {
      final dt = sample.timestamp.difference(_prev!.timestamp).inMilliseconds;
      if (dt > 50 && dt < 10 * 1000) {
        final dvMps = ((speedKmh - _prev!.speedKmh!) / 3.6);
        final accel = dvMps / (dt / 1000.0);
        _accelEma = _accelAlpha * accel + (1 - _accelAlpha) * _accelEma;

        if (accel >= _harshAccelThreshold) _harshAccelCount += 1;
        if (accel <= _harshBrakeThreshold) _harshBrakeCount += 1;
      }

      // Stop detection: crossing from moving to near-zero.
      if ((_prev!.speedKmh ?? 0) > 6 && (speedKmh) < 2) {
        _stopCount += 1;
      }

      // Aggressive cornering heuristic: fast heading change at speed.
      final b0 = _prev!.bearingDeg;
      final b1 = sample.bearingDeg;
      if (b0 != null && b1 != null && speedKmh >= 18) {
        final dBear = _bearingDeltaDeg(b0, b1);
        final rateDegPerSec = dBear / (dt / 1000.0);
        // Normalize into 0..1-ish range.
        final score = (rateDegPerSec / 35.0).clamp(0.0, 1.6);
        _cornerScoreEma =
            _cornerAlpha * score + (1 - _cornerAlpha) * _cornerScoreEma;
      }
    }

    _prev = sample;
  }

  DrivingBehaviorMetrics snapshot() {
    final now = DateTime.now();
    final start = _startTime ?? now;
    final minutes = math.max(1e-6, now.difference(start).inSeconds / 60.0);

    final harshAccelPerMin = _harshAccelCount / minutes;
    final harshBrakePerMin = _harshBrakeCount / minutes;
    final stopPerKm = _distanceKmSinceReset > 0
        ? _stopCount / _distanceKmSinceReset
        : 0.0;
    final timeAbove90Ratio =
        _totalSpeedSamples > 0 ? _above90Count / _totalSpeedSamples : 0.0;
    final idleRatio =
        _totalSpeedSamples > 0 ? _idleSamples / _totalSpeedSamples : 0.0;
    final accelEmaAbs = _accelEma.abs();

    // Stop-go index: high when idle is frequent AND accel variance is non-trivial.
    final stopGoIndex =
        (idleRatio * 1.2 + math.min(1.0, accelEmaAbs / 2.2)).clamp(0.0, 1.0);

    final style = _classify(
      harshAccelPerMin: harshAccelPerMin,
      harshBrakePerMin: harshBrakePerMin,
      stopPerKm: stopPerKm,
      timeAbove90Ratio: timeAbove90Ratio,
      accelEmaAbs: _accelEma.abs(),
    );
    final styleBase = switch (style) {
      DrivingStyle.eco => 0.94,
      DrivingStyle.normal => 1.0,
      DrivingStyle.aggressive => 1.12, // baseline +12%
    };
    final dynamicPenalty = (harshAccelPerMin * 0.02) +
        (harshBrakePerMin * 0.018) +
        (_cornerScoreEma * 0.05) +
        (stopGoIndex * 0.06);
    final ecoCredit = style == DrivingStyle.eco ? idleRatio * 0.015 : 0.0;
    final styleFactor = (styleBase + dynamicPenalty - ecoCredit).clamp(0.88, 1.34);

    return DrivingBehaviorMetrics(
      style: style,
      styleFactor: styleFactor,
      accelMps2Ema: _accelEma,
      harshAccelPerMin: harshAccelPerMin,
      harshBrakePerMin: harshBrakePerMin,
      stopPerKm: stopPerKm,
      timeAbove90Ratio: timeAbove90Ratio,
      corneringAggressiveness: _cornerScoreEma,
      idleRatio: idleRatio,
      stopGoIndex: stopGoIndex,
    );
  }

  DrivingStyle _classify({
    required double harshAccelPerMin,
    required double harshBrakePerMin,
    required double stopPerKm,
    required double timeAbove90Ratio,
    required double accelEmaAbs,
  }) {
    final aggressiveScore = (harshAccelPerMin * 0.9) +
        (harshBrakePerMin * 0.9) +
        (timeAbove90Ratio * 2.2) +
        (accelEmaAbs * 0.25);
    final ecoScore = (stopPerKm * 0.25) + (1 - timeAbove90Ratio) * 0.6;

    if (aggressiveScore >= 2.0) return DrivingStyle.aggressive;
    if (ecoScore >= 0.8 && aggressiveScore < 1.2) return DrivingStyle.eco;
    return DrivingStyle.normal;
  }

  double _bearingDeltaDeg(double a, double b) {
    var d = (b - a).abs() % 360;
    if (d > 180) d = 360 - d;
    return d;
  }
}

