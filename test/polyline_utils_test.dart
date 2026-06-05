import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_tracker_app/core/config/constants.dart';
import 'package:fuel_tracker_app/features/navigation/core/polyline_utils.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/gas_station.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('filterStationsNearPolyline', () {
    test('keeps stations within corridor along route segments', () {
      // Tuyến đi thẳng theo kinh độ tại vĩ độ 21.0.
      final route = [
        const LatLng(21.0, 105.80),
        const LatLng(21.0, 105.82),
        const LatLng(21.0, 105.84),
      ];

      const onRoute = GasStation(
        id: 'near',
        osmType: 'node',
        osmId: 1,
        name: 'Trạm sát tuyến',
        address: 'Test',
        location: LatLng(21.0004, 105.81),
        distanceKm: 0,
        brand: 'Fuel',
      );
      const offRoute = GasStation(
        id: 'far',
        osmType: 'node',
        osmId: 2,
        name: 'Trạm xa tuyến',
        address: 'Test',
        location: LatLng(21.03, 105.81),
        distanceKm: 0,
        brand: 'Fuel',
      );

      final filtered = filterStationsNearPolyline(
        [onRoute, offRoute],
        route,
        maxDistanceKm: AppConstants.routeStationCorridorKm,
      );

      expect(filtered.map((s) => s.id), contains('near'));
      expect(filtered.map((s) => s.id), isNot(contains('far')));
    });

    test('distancePointToPolylineKm measures perpendicular offset from path', () {
      final route = [
        const LatLng(21.0, 105.80),
        const LatLng(21.0, 105.84),
      ];
      const nearPath = LatLng(21.0018, 105.82);
      const farFromPath = LatLng(21.035, 105.82);

      final corridor = densifyPolyline(route);
      final nearDist = distancePointToPolylineKm(corridor, nearPath);
      final farDist = distancePointToPolylineKm(corridor, farFromPath);

      expect(nearDist, lessThan(AppConstants.routeStationCorridorKm));
      expect(farDist, greaterThan(nearDist));
      expect(farDist, greaterThan(AppConstants.routeStationCorridorKm));
    });

    test('filterStationsAheadOnRoute keeps only stations ahead of user', () {
      final route = [
        const LatLng(21.0, 105.80),
        const LatLng(21.0, 105.90),
      ];
      const user = LatLng(21.0, 105.85);

      GasStation stationAt(String id, double lon) => GasStation(
            id: id,
            osmType: 'node',
            osmId: id.hashCode,
            name: id,
            address: 'Test',
            location: LatLng(21.0, lon),
            distanceKm: 0,
            brand: 'Fuel',
          );

      final behind = stationAt('behind', 105.82);
      final ahead = stationAt('ahead', 105.88);

      final filtered = filterStationsAheadOnRoute(
        stations: [behind, ahead],
        routePoints: route,
        userLocation: user,
        lookBackKm: 0.05,
        maxCount: 10,
      );

      expect(filtered.map((s) => s.id), contains('ahead'));
      expect(filtered.map((s) => s.id), isNot(contains('behind')));
    });
  });
}
