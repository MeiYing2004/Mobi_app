import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:fuel_tracker_app/features/location/core/gps_position_filter.dart';
import 'package:fuel_tracker_app/features/location/core/gps_tracking_policy.dart';
import 'package:fuel_tracker_app/features/navigation/core/route_off_route.dart';

void main() {
  group('classifyOffRouteMeters', () {
    test('threshold bands', () {
      expect(classifyOffRouteMeters(10), OffRouteAction.onRoute);
      expect(classifyOffRouteMeters(29), OffRouteAction.onRoute);
      expect(classifyOffRouteMeters(30), OffRouteAction.updateProgressOnly);
      expect(classifyOffRouteMeters(99), OffRouteAction.updateProgressOnly);
      expect(classifyOffRouteMeters(100), OffRouteAction.triggerReroute);
      expect(classifyOffRouteMeters(299), OffRouteAction.triggerReroute);
      expect(classifyOffRouteMeters(300), OffRouteAction.immediateReroute);
    });
  });

  group('GpsPositionFilter', () {
    test('rejects poor accuracy', () {
      final filter = GpsPositionFilter();
      final bad = Position(
        latitude: 10.776,
        longitude: 106.7,
        timestamp: DateTime.now(),
        accuracy: 45,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 2,
        speedAccuracy: 0,
      );
      expect(filter.ingest(bad), isNull);
    });

    test('ignores stationary jitter', () {
      final filter = GpsPositionFilter();
      final t = DateTime.now();
      final a = Position(
        latitude: 10.776,
        longitude: 106.7,
        timestamp: t,
        accuracy: 8,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      filter.ingest(a);
      final b = Position(
        latitude: 10.776004,
        longitude: 106.700004,
        timestamp: t.add(const Duration(seconds: 1)),
        accuracy: 8,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      expect(filter.ingest(b), a);
      expect(filter.latLng?.latitude, closeTo(10.776, 0.0001));
    });
  });

  group('GpsTrackingPolicy', () {
    test('reroute cooldown is reasonable', () {
      expect(GpsTrackingPolicy.rerouteCooldown.inSeconds, greaterThan(15));
    });
  });
}
