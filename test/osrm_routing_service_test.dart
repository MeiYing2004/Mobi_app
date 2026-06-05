import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/features/navigation/core/polyline_utils.dart';
import 'package:fuel_tracker_app/features/geocoding/data/exceptions/map_navigation_exceptions.dart';
import 'package:fuel_tracker_app/features/navigation/data/services/osrm_route_parser.dart';

void main() {
  group('OsrmRouteParser.pointsFromGeoJsonCoordinates', () {
    test('maps [lon, lat] to LatLng without swapping', () {
      final points = OsrmRouteParser.pointsFromGeoJsonCoordinates([
        [105.8342, 21.0285],
        [106.7009, 10.7769],
      ]);
      expect(points, hasLength(2));
      expect(points[0].latitude, closeTo(21.0285, 0.0001));
      expect(points[0].longitude, closeTo(105.8342, 0.0001));
      expect(points[1].latitude, closeTo(10.7769, 0.0001));
      expect(points[1].longitude, closeTo(106.7009, 0.0001));
    });

    test('skips invalid coordinates', () {
      final points = OsrmRouteParser.pointsFromGeoJsonCoordinates([
        [double.nan, 21.0],
        [105.0, 200.0],
        [105.1, 21.1],
        [105.2, 21.2],
      ]);
      expect(points, hasLength(2));
    });
  });

  group('OsrmRouteParser.pickBestRoute', () {
    test('chooses shortest duration among alternatives', () {
      final best = OsrmRouteParser.pickBestRoute([
        {
          'duration': 900,
          'distance': 12000,
          'geometry': {
            'coordinates': [
              [105.0, 21.0],
              [105.1, 21.1],
            ],
          },
        },
        {
          'duration': 600,
          'distance': 10000,
          'geometry': {
            'coordinates': [
              [105.0, 21.0],
              [105.05, 21.05],
            ],
          },
        },
      ]);
      expect(best?['duration'], 600);
    });
  });

  group('OsrmRouteParser.capPolylinePoints', () {
    test('decimates when over maxPolylinePoints', () {
      final many = List<LatLng>.generate(
        3000,
        (i) => LatLng(21.0 + i * 0.0001, 105.0 + i * 0.0001),
      );
      final capped = OsrmRouteParser.capPolylinePoints(many);
      expect(capped.length, lessThanOrEqualTo(2000));
      expect(capped.first, many.first);
      expect(capped.last, many.last);
    });
  });

  group('OsrmRouteParser.parseRoutePlan', () {
    test('uses OSRM distance and duration not polyline estimate', () {
      final plan = OsrmRouteParser.parseRoutePlan(
        {
          'distance': 12500,
          'duration': 720,
          'geometry': {
            'coordinates': [
              [105.8342, 21.0285],
              [105.8442, 21.0385],
            ],
          },
        },
        simplifiedOverview: false,
      );
      expect(plan.distanceKm, closeTo(12.5, 0.001));
      expect(plan.durationSeconds, 720);
      expect(plan.distanceLabel, contains('km'));
    });
  });

  group('OsrmRouteParser.validateEndpoints', () {
    test('rejects null island', () {
      expect(
        () => OsrmRouteParser.validateEndpoints(
          const LatLng(0, 0),
          const LatLng(21.03, 105.85),
        ),
        throwsA(isA<RoutingException>()),
      );
    });

    test('rejects endpoints too close', () {
      expect(
        () => OsrmRouteParser.validateEndpoints(
          const LatLng(21.0285, 105.8542),
          const LatLng(21.02851, 105.85421),
        ),
        throwsA(
          predicate<RoutingException>(
            (e) => e.message.contains('quá gần'),
          ),
        ),
      );
    });
  });

  group('polyline vs OSRM distance drift', () {
    test('straight segment drift stays under 1% for full geometry', () {
      final points = OsrmRouteParser.pointsFromGeoJsonCoordinates([
        [105.8342, 21.0285],
        [105.9342, 21.1285],
      ]);
      const osrmKm = 15.0;
      final polyKm = polylineLengthKm(points);
      final drift = (polyKm - osrmKm).abs() / osrmKm;
      expect(drift, lessThan(0.15));
    });
  });

  group('OsrmRouteParser destination snap', () {
    test('records snap meters when routed end differs from request', () {
      final plan = OsrmRouteParser.parseRoutePlan(
        {
          'distance': 5000,
          'duration': 300,
          'geometry': {
            'coordinates': [
              [106.700, 10.775],
              [106.705, 10.777],
            ],
          },
        },
        simplifiedOverview: false,
        requestedDestination: const LatLng(10.775, 106.700),
      );
      expect(plan.destinationSnapMeters, greaterThan(50));
    });
  });

  group('OsrmRouteParser.messageForOsrmCode', () {
    test('maps NoRoute and NoSegment', () {
      expect(
        OsrmRouteParser.messageForOsrmCode('NoRoute'),
        contains('Không có đường'),
      );
      expect(
        OsrmRouteParser.messageForOsrmCode('NoSegment'),
        contains('mạng lưới'),
      );
    });
  });
}
