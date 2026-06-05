import 'package:flutter/foundation.dart';

import 'package:fuel_tracker_app/features/fuel/data/models/gas_station.dart';

/// Snapshot điều hướng cho Dynamic Island (shared giữa HomeScreen và Launcher).
class NavigationIslandSnapshot {
  const NavigationIslandSnapshot({
    required this.destinationName,
    required this.remainingDistanceKm,
    required this.progress,
    required this.etaLabel,
  });

  final String destinationName;
  final double remainingDistanceKm;
  final double progress;
  final String etaLabel;
}

/// Cầu nối trạng thái hệ thống iOS giả lập — navigation, trạm xăng gần nhất.
class IosSystemBridge extends ChangeNotifier {
  NavigationIslandSnapshot? _navigation;
  GasStation? _nearestStation;
  bool _loadingStations = false;

  NavigationIslandSnapshot? get navigation => _navigation;
  GasStation? get nearestStation => _nearestStation;
  bool get loadingStations => _loadingStations;

  bool get isNavigating => _navigation != null;

  void setNavigation(NavigationIslandSnapshot? snapshot) {
    if (_navigation == snapshot) return;
    _navigation = snapshot;
    notifyListeners();
  }

  void clearNavigation() => setNavigation(null);

  void setNearestStation(GasStation? station) {
    if (_nearestStation?.id == station?.id) return;
    _nearestStation = station;
    notifyListeners();
  }

  void setLoadingStations(bool loading) {
    if (_loadingStations == loading) return;
    _loadingStations = loading;
    notifyListeners();
  }
}
