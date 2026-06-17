import 'package:flutter/foundation.dart';

import 'package:fuel_tracker_app/core/config/constants.dart';
import 'package:fuel_tracker_app/features/auth/models/user_data_models.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/fuel_warning_event.dart';
import 'package:fuel_tracker_app/features/fuel/data/services/gas_station_service.dart';
import 'package:fuel_tracker_app/shared/services/notification_service.dart';

/// Quản lý nhiên liệu — tự trừ theo quãng đường GPS thực tế.
class FuelService extends ChangeNotifier {
  final NotificationService _notificationService;

  FuelService({required NotificationService notificationService})
      : _notificationService = notificationService;

  double _tankCapacityLiters = AppConstants.defaultTankCapacityLiters;
  // Demo mặc định: còn 12L/14L => safe range xấp xỉ ~250km (giữ reserve 2L).
  double _currentFuelLiters = 12.0;
  double _baseLPer100Km = AppConstants.defaultBaseLPer100Km;

  bool _hasShownWarning = false;
  bool _persistEnabled = false;

  void Function(UserFuelData data)? onFuelDataChanged;

  void Function(FuelWarningEvent event)? onLowFuelWarning;

  String get vehicleName => AppConstants.defaultVehicleName;
  double get tankCapacityLiters => _tankCapacityLiters;
  double get currentFuelLiters => _currentFuelLiters;
  double get baseLPer100Km => _baseLPer100Km;
  double get criticalReserveLiters => AppConstants.defaultCriticalReserveLiters;

  double get fuelPercent {
    if (_tankCapacityLiters <= 0) return 0;
    return (_currentFuelLiters / _tankCapacityLiters).clamp(0.0, 1.0) * 100;
  }

  double get remainingDistanceKm =>
      _baseLPer100Km > 0 ? _currentFuelLiters / (_baseLPer100Km / 100) : 0;

  /// Quãng đường còn đi "an toàn", đã trừ mức dự phòng tối thiểu.
  double get safeRemainingDistanceKm {
    if (_baseLPer100Km <= 0) return 0;
    final usableLiters = (_currentFuelLiters - criticalReserveLiters).clamp(
      0.0,
      _tankCapacityLiters,
    );
    return usableLiters / (_baseLPer100Km / 100);
  }

  double get litersPer100Km =>
      _baseLPer100Km;

  double get fuelPriceVndPerLiter => GasStationService.referencePriceVndPerLiter;

  /// Nhãn lần đổ xăng gần nhất (demo — cập nhật khi có lịch sử thật).
  String get lastFillUpLabel {
    final daysSince = ((100 - fuelPercent) / 8).round().clamp(1, 14);
    if (daysSince == 1) return 'Hôm qua';
    if (daysSince <= 7) return '$daysSince ngày trước';
    return '${(daysSince / 7).floor()} tuần trước';
  }

  double fuelCostForDistanceKm(double distanceKm) {
    if (_baseLPer100Km <= 0) return 0;
    final liters = distanceKm * (_baseLPer100Km / 100);
    return liters * fuelPriceVndPerLiter;
  }

  String get estimatedEmptyLabel {
    if (remainingDistanceKm <= 0) return 'Sắp hết xăng';
    final hours = remainingDistanceKm / 50;
    if (hours < 1) return '~${(hours * 60).round()} phút';
    return '~${hours.toStringAsFixed(1)} giờ';
  }

  bool get isLowFuel {
    return fuelPercent <= AppConstants.fuelWarningPercent ||
        _currentFuelLiters <= criticalReserveLiters ||
        remainingDistanceKm <= AppConstants.fuelWarningDistanceKm;
  }

  /// Load fuel state từ user hiện tại.
  void loadFromUserData(UserFuelData data, {bool persist = true}) {
    _persistEnabled = false;
    _tankCapacityLiters = data.tankCapacity.clamp(1, 200);
    _currentFuelLiters = data.currentFuel.clamp(0, _tankCapacityLiters);
    _baseLPer100Km = data.avgConsumption > 0
        ? data.avgConsumption.clamp(2.0, 35.0)
        : AppConstants.defaultBaseLPer100Km;
    _hasShownWarning = false;
    _persistEnabled = persist;
    notifyListeners();
  }

  /// Xuất fuel state để lưu vào data.json.
  UserFuelData exportUserData() => UserFuelData(
        currentFuel: _currentFuelLiters,
        tankCapacity: _tankCapacityLiters,
        avgConsumption: _baseLPer100Km,
      );

  /// Reset khi logout — không ghi vào user.
  void resetToDefaults() {
    _persistEnabled = false;
    _tankCapacityLiters = AppConstants.defaultTankCapacityLiters;
    _currentFuelLiters = 12.0;
    _baseLPer100Km = AppConstants.defaultBaseLPer100Km;
    _hasShownWarning = false;
    notifyListeners();
  }

  void _notifyFuelPersist() {
    if (!_persistEnabled) return;
    onFuelDataChanged?.call(exportUserData());
  }

  /// Trừ nhiên liệu theo quãng đường GPS (mét).
  void consumeDistanceMeters(double meters) {
    if (meters <= 0 || _baseLPer100Km <= 0) return;
    final liters = (meters / 1000) * (_baseLPer100Km / 100);
    _currentFuelLiters =
        (_currentFuelLiters - liters).clamp(0.0, _tankCapacityLiters);
    _evaluateWarning();
    notifyListeners();
    _notifyFuelPersist();
  }

  void updateTankCapacity(double value) {
    _tankCapacityLiters = value.clamp(1, 200);
    if (_currentFuelLiters > _tankCapacityLiters) {
      _currentFuelLiters = _tankCapacityLiters;
    }
    _evaluateWarning();
    notifyListeners();
    _notifyFuelPersist();
  }

  void updateCurrentFuel(double value) {
    _currentFuelLiters = value.clamp(0, _tankCapacityLiters);
    _evaluateWarning();
    notifyListeners();
    _notifyFuelPersist();
  }

  /// Demo đổ xăng (debug/profile) — 100% bình hoặc tối thiểu 5L.
  void simulateRefuelForDebug() {
    if (kReleaseMode) return;
    _currentFuelLiters = _tankCapacityLiters >= 5.0
        ? _tankCapacityLiters
        : 5.0.clamp(0.0, _tankCapacityLiters);
    _hasShownWarning = false;
    _evaluateWarning();
    notifyListeners();
    _notifyFuelPersist();
  }

  void updateBaseConsumptionLPer100Km(double value) {
    _baseLPer100Km = value.clamp(2.0, 35.0);
    _evaluateWarning();
    notifyListeners();
    _notifyFuelPersist();
  }

  void _evaluateWarning() {
    final percent = fuelPercent;
    final distanceLeft = remainingDistanceKm;

    final belowPercent = percent <= AppConstants.fuelWarningPercent;
    final belowReserve = _currentFuelLiters <= criticalReserveLiters;
    final belowDistance =
        distanceLeft <= AppConstants.fuelWarningDistanceKm;

    if ((belowPercent || belowReserve || belowDistance) && !_hasShownWarning) {
      _hasShownWarning = true;
      _triggerWarning(percent, distanceLeft);
    } else if (!belowPercent && !belowReserve && !belowDistance) {
      _hasShownWarning = false;
    }
  }

  Future<void> _triggerWarning(double percent, double distanceKm) async {
    final event = FuelWarningEvent(
      title: 'Cảnh báo nhiên liệu thấp',
      message:
          'Chỉ còn ${percent.toStringAsFixed(0)}% (~${distanceKm.toStringAsFixed(1)} km). '
          'Mức dự phòng tối thiểu là ${criticalReserveLiters.toStringAsFixed(1)}L. Hãy tìm cây xăng gần nhất!',
      fuelPercent: percent,
      remainingDistanceKm: distanceKm,
    );

    await _notificationService.showFuelWarning(
      title: event.title,
      body: event.message,
    );

    onLowFuelWarning?.call(event);
  }
}
