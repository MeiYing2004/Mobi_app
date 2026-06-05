import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/features/navigation/core/polyline_utils.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/gas_station.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/route_fuel_analysis.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/trip_fuel_status.dart';
import 'package:fuel_tracker_app/features/fuel/data/services/fuel_service.dart';
import 'package:fuel_tracker_app/features/fuel/data/services/fuel_station_service.dart';

/// Tính nhiên liệu trên tuyến và vị trí dự đoán hết xăng.
class RouteFuelService {
  const RouteFuelService();

  RouteFuelAnalysis analyze({
    required List<LatLng> routePoints,
    required double routeDistanceKm,
    required FuelService fuel,
    required GasStation destination,
    required List<GasStation> nearbyStations,
    List<GasStation> routeStations = const [],
    LatLng? origin,
  }) {
    final lPer100Km = fuel.baseLPer100Km;
    final currentLiters = fuel.currentFuelLiters;
    final rangeKm = fuel.remainingDistanceKm;

    final litersRequired =
        lPer100Km > 0 ? routeDistanceKm * (lPer100Km / 100.0) : 0.0;
    final litersRemainingAfter = (currentLiters - litersRequired)
        .clamp(0.0, fuel.tankCapacityLiters)
        .toDouble();
    final kmRemainingAfter =
        lPer100Km > 0 ? litersRemainingAfter / (lPer100Km / 100.0) : 0.0;
    final hasSufficientFuel = rangeKm >= routeDistanceKm - 0.05;
    final insufficientFuel = !hasSufficientFuel;

    final status = resolveTripFuelStatus(
      hasSufficientFuel: hasSufficientFuel,
      rangeKm: rangeKm,
      routeDistanceKm: routeDistanceKm,
      fuelPercent: fuel.fuelPercent,
    );

    LatLng? emptyPoint;
    if (insufficientFuel && routePoints.length >= 2) {
      final reachableKm =
          lPer100Km > 0 ? currentLiters / (lPer100Km / 100.0) : 0.0;
      emptyPoint = pointAlongPolylineAtKm(routePoints, reachableKm);
    }

    final stationService = FuelStationService();
    GasStation? suggestedOnRoute;
    double? suggestedFromOriginKm;
    if (insufficientFuel &&
        routeStations.isNotEmpty &&
        origin != null &&
        routePoints.length >= 2) {
      suggestedOnRoute = stationService.nearestAheadOnRoute(
        stations: routeStations,
        routePoints: routePoints,
        from: origin,
      );
      if (suggestedOnRoute != null) {
        suggestedFromOriginKm = const Distance().as(
          LengthUnit.Kilometer,
          origin,
          suggestedOnRoute.location,
        );
      }
    }

    GasStation? closer;
    if (insufficientFuel) {
      final pool = routeStations.isNotEmpty ? routeStations : nearbyStations;
      closer = pool
          .where((s) => s.id != destination.id)
          .fold<GasStation?>(
        null,
        (best, s) {
          if (best == null || s.distanceKm < best.distanceKm) return s;
          return best;
        },
      );
      if (suggestedOnRoute == null && closer != null) {
        suggestedOnRoute = closer;
        if (origin != null) {
          suggestedFromOriginKm = const Distance().as(
            LengthUnit.Kilometer,
            origin,
            closer.location,
          );
        }
      }
    }

    return RouteFuelAnalysis(
      routeDistanceKm: routeDistanceKm,
      litersRequired: litersRequired,
      litersRemainingAfter: litersRemainingAfter,
      kmRemainingAfter: kmRemainingAfter,
      insufficientFuel: insufficientFuel,
      emptyPointOnRoute: emptyPoint,
      suggestedCloserStation: closer,
      rangeKm: rangeKm,
      currentFuelLiters: currentLiters,
      averageConsumptionLPer100Km: lPer100Km,
      hasSufficientFuel: hasSufficientFuel,
      status: status,
      stationsOnRouteCount: routeStations.length,
      suggestedRefuelOnRoute: suggestedOnRoute,
      suggestedRefuelDistanceFromOriginKm: suggestedFromOriginKm,
    );
  }
}
