import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/core/config/constants.dart';

/// Trạng thái vùng di chuyển tối đa (range circle).
enum TripFuelStatus {
  /// 🟢 Đủ nhiên liệu cho tuyến.
  safe,

  /// 🟠 Sắp hết / biên an toàn hẹp.
  warning,

  /// 🔴 Không đủ nhiên liệu cho tuyến.
  critical,
}

extension TripFuelStatusX on TripFuelStatus {
  Color get circleFill {
    switch (this) {
      case TripFuelStatus.safe:
        return const Color(0xFF34D399);
      case TripFuelStatus.warning:
        return const Color(0xFFFBBF24);
      case TripFuelStatus.critical:
        return const Color(0xFFEF4444);
    }
  }

  Color get circleBorder => circleFill.withValues(alpha: 0.85);

  String get label {
    switch (this) {
      case TripFuelStatus.safe:
        return '🟢 Đủ nhiên liệu';
      case TripFuelStatus.warning:
        return '🟠 Sắp hết nhiên liệu';
      case TripFuelStatus.critical:
        return '🔴 Không đủ nhiên liệu';
    }
  }

}

TripFuelStatus resolveTripFuelStatus({
  required bool hasSufficientFuel,
  required double rangeKm,
  required double routeDistanceKm,
  required double fuelPercent,
}) {
  if (!hasSufficientFuel) return TripFuelStatus.critical;
  if (fuelPercent <= AppConstants.fuelWarningPercent + 8 ||
      rangeKm < routeDistanceKm * 1.12) {
    return TripFuelStatus.warning;
  }
  return TripFuelStatus.safe;
}
