import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/features/geocoding/data/services/nominatim_geocoding_service.dart';

void main() {
  group('NominatimGeocodingService.parseSearchResults', () {
    test('parses valid hits with coordinates', () {
      final raw = [
        {
          'lat': '10.7769',
          'lon': '106.7009',
          'osm_type': 'node',
          'osm_id': 42,
          'name': 'HUTECH',
          'display_name': 'HUTECH, TP.HCM, Việt Nam',
          'type': 'university',
        },
      ];

      final list = NominatimGeocodingService.parseSearchResults(raw);
      expect(list, hasLength(1));
      expect(list.first.primaryText, 'HUTECH');
      expect(list.first.location?.latitude, closeTo(10.7769, 0.0001));
    });

    test('skips entries without coordinates', () {
      final raw = [
        {'name': 'Bad', 'osm_type': 'node', 'osm_id': 1},
      ];
      expect(NominatimGeocodingService.parseSearchResults(raw), isEmpty);
    });

    test('sorts by bias location when provided', () {
      final raw = [
        {
          'lat': '21.0285',
          'lon': '105.8542',
          'osm_type': 'node',
          'osm_id': 1,
          'name': 'Hà Nội',
          'display_name': 'Hà Nội',
        },
        {
          'lat': '10.7769',
          'lon': '106.7009',
          'osm_type': 'node',
          'osm_id': 2,
          'name': 'HCM',
          'display_name': 'HCM',
        },
      ];
      const bias = LatLng(10.77, 106.70);
      final list = NominatimGeocodingService.parseSearchResults(raw, bias: bias);
      expect(list.first.primaryText, 'HCM');
    });

    test('parses structured address components', () {
      final raw = [
        {
          'lat': '10.7769',
          'lon': '106.7009',
          'osm_type': 'node',
          'osm_id': 99,
          'name': 'Nguyễn Huệ',
          'display_name': 'Nguyễn Huệ, Quận 1, TP.HCM',
          'address': {
            'road': 'Nguyễn Huệ',
            'suburb': 'Bến Nghé',
            'city_district': 'Quận 1',
            'city': 'Thành phố Hồ Chí Minh',
          },
        },
      ];
      final list = NominatimGeocodingService.parseSearchResults(raw);
      expect(list.first.address?.street, 'Nguyễn Huệ');
      expect(list.first.address?.district, 'Quận 1');
    });
  });

  group('NominatimGeocodingService.subtitleFor', () {
    test('strips name prefix from display name', () {
      expect(
        NominatimGeocodingService.subtitleFor('Landmark 81', 'Landmark 81, TP.HCM'),
        'TP.HCM',
      );
    });
  });
}
