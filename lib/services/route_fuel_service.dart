import 'package:latlong2/latlong.dart';

import '../models/gas_station.dart';
import '../models/route_fuel_analysis.dart';
import '../core/utils/polyline_utils.dart';
import 'fuel_service.dart';

/// Tính nhiên liệu trên tuyến và vị trí dự đoán hết xăng.
class RouteFuelService {
  const RouteFuelService();

  RouteFuelAnalysis analyze({
    required List<LatLng> routePoints,
    required double routeDistanceKm,
    required FuelService fuel,
    required GasStation destination,
    required List<GasStation> nearbyStations,
  }) {
    final lPer100Km = fuel.baseLPer100Km;
    final currentLiters = fuel.currentFuelLiters;

    final litersRequired =
        lPer100Km > 0 ? routeDistanceKm * (lPer100Km / 100.0) : 0.0;
    final litersRemainingAfter = (currentLiters - litersRequired)
        .clamp(0.0, fuel.tankCapacityLiters)
        .toDouble();
    final kmRemainingAfter =
        lPer100Km > 0 ? litersRemainingAfter / (lPer100Km / 100.0) : 0.0;
    final insufficientFuel = litersRequired > currentLiters + 0.05;

    LatLng? emptyPoint;
    if (insufficientFuel && routePoints.length >= 2) {
      final reachableKm =
          lPer100Km > 0 ? currentLiters / (lPer100Km / 100.0) : 0.0;
      emptyPoint = pointAlongPolylineAtKm(routePoints, reachableKm);
    }

    GasStation? closer;
    if (insufficientFuel && nearbyStations.isNotEmpty) {
      closer = nearbyStations
          .where((s) => s.id != destination.id)
          .where((s) => s.distanceKm < destination.distanceKm)
          .fold<GasStation?>(
        null,
        (best, s) {
          if (best == null || s.distanceKm < best.distanceKm) return s;
          return best;
        },
      );
    }

    return RouteFuelAnalysis(
      routeDistanceKm: routeDistanceKm,
      litersRequired: litersRequired,
      litersRemainingAfter: litersRemainingAfter,
      kmRemainingAfter: kmRemainingAfter,
      insufficientFuel: insufficientFuel,
      emptyPointOnRoute: emptyPoint,
      suggestedCloserStation: closer,
    );
  }
}
