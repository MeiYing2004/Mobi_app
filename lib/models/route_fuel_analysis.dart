import 'package:latlong2/latlong.dart';

import 'gas_station.dart';

/// Phân tích nhiên liệu trên tuyến đường.
class RouteFuelAnalysis {
  final double routeDistanceKm;
  final double litersRequired;
  final double litersRemainingAfter;
  final double kmRemainingAfter;
  final bool insufficientFuel;
  final LatLng? emptyPointOnRoute;
  final GasStation? suggestedCloserStation;

  const RouteFuelAnalysis({
    required this.routeDistanceKm,
    required this.litersRequired,
    required this.litersRemainingAfter,
    required this.kmRemainingAfter,
    required this.insufficientFuel,
    this.emptyPointOnRoute,
    this.suggestedCloserStation,
  });
}
