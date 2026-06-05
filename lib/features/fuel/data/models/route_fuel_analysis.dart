import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/features/fuel/data/models/gas_station.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/trip_fuel_status.dart';

/// Phân tích nhiên liệu trên tuyến đường OSRM.
class RouteFuelAnalysis {
  final double routeDistanceKm;
  final double litersRequired;
  final double litersRemainingAfter;
  final double kmRemainingAfter;
  final bool insufficientFuel;
  final LatLng? emptyPointOnRoute;
  final GasStation? suggestedCloserStation;

  /// Quãng đường tối đa theo công thức (L còn / L/100km) * 100.
  final double rangeKm;

  final double currentFuelLiters;
  final double averageConsumptionLPer100Km;

  /// Range >= routeDistanceKm
  final bool hasSufficientFuel;

  final TripFuelStatus status;

  final int stationsOnRouteCount;

  /// Cây xăng gần nhất trên tuyến (khi không đủ nhiên liệu).
  final GasStation? suggestedRefuelOnRoute;

  /// Khoảng cách từ vị trí hiện tại tới cây xăng đề xuất (km).
  final double? suggestedRefuelDistanceFromOriginKm;

  const RouteFuelAnalysis({
    required this.routeDistanceKm,
    required this.litersRequired,
    required this.litersRemainingAfter,
    required this.kmRemainingAfter,
    required this.insufficientFuel,
    required this.rangeKm,
    required this.currentFuelLiters,
    required this.averageConsumptionLPer100Km,
    required this.hasSufficientFuel,
    required this.status,
    required this.stationsOnRouteCount,
    this.emptyPointOnRoute,
    this.suggestedCloserStation,
    this.suggestedRefuelOnRoute,
    this.suggestedRefuelDistanceFromOriginKm,
  });

  String get fuelAfterArrivalLabel =>
      '${litersRemainingAfter.toStringAsFixed(1)} L';

  String get fuelUsedLabel => '${litersRequired.toStringAsFixed(1)} L';

  String get rangeLabel => '${rangeKm.round()} km';
}
