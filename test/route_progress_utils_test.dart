import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/features/navigation/core/route_progress_utils.dart';

void main() {
  group('routeProgressMetrics', () {
    final route = [
      const LatLng(21.0, 105.80),
      const LatLng(21.0, 105.85),
      const LatLng(21.0, 105.90),
    ];
    const totalKm = 10.0;
    const totalSec = 600;

    test('no GPS uses full route distance and duration', () {
      final m = routeProgressMetrics(
        routePoints: route,
        totalDistanceKm: totalKm,
        totalDurationSeconds: totalSec,
      );
      expect(m.remainingKm, totalKm);
      expect(m.progress, 0);
      expect(m.remainingDurationSeconds, totalSec);
    });

    test('mid-route user reduces remaining proportionally', () {
      const user = LatLng(21.0, 105.85);
      final m = routeProgressMetrics(
        routePoints: route,
        totalDistanceKm: totalKm,
        totalDurationSeconds: totalSec,
        userLocation: user,
      );
      expect(m.traveledKm, greaterThan(0));
      expect(m.remainingKm, lessThan(totalKm));
      expect(m.remainingKm, greaterThan(0));
      expect(m.progress, greaterThan(0));
      expect(m.progress, lessThan(1));
      expect(m.remainingDurationSeconds, lessThan(totalSec));
    });

    test('remaining uses route not straight-line to destination', () {
      const user = LatLng(21.02, 105.86);
      final along = routeProgressMetrics(
        routePoints: route,
        totalDistanceKm: totalKm,
        totalDurationSeconds: totalSec,
        userLocation: user,
      );
      final straight = const Distance().as(
        LengthUnit.Kilometer,
        user,
        const LatLng(21.0, 105.90),
      );
      expect(along.remainingKm, isNot(closeTo(straight, 0.5)));
    });
  });
}
