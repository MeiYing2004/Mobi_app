import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:fuel_tracker_app/core/config/osm_config.dart';
import 'package:fuel_tracker_app/core/network/osm_http.dart';

void main() {
  group('OsmConfig', () {
    test('nominatim User-Agent includes app name, version, and contact', () {
      expect(OsmConfig.userAgent, contains(OsmConfig.appName));
      expect(OsmConfig.userAgent, contains(OsmConfig.appVersion));
      expect(OsmConfig.userAgent, contains(OsmConfig.contactEmail));
      expect(OsmConfig.nominatimHeaders['User-Agent'], OsmConfig.userAgent);
    });
  });

  group('OsmHttpClient.backoffDelayFor429', () {
    test('uses Retry-After seconds when present', () {
      final res = http.Response('', 429, headers: {'retry-after': '5'});
      expect(
        OsmHttpClient.backoffDelayFor429(1, res),
        const Duration(seconds: 5),
      );
    });

    test('exponential backoff when Retry-After missing', () {
      final res = http.Response('', 429);
      expect(
        OsmHttpClient.backoffDelayFor429(1, res),
        const Duration(milliseconds: 1000),
      );
      expect(
        OsmHttpClient.backoffDelayFor429(2, res),
        const Duration(milliseconds: 2000),
      );
      expect(
        OsmHttpClient.backoffDelayFor429(3, res),
        const Duration(milliseconds: 4000),
      );
    });
  });
}
