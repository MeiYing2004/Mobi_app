import 'package:flutter_test/flutter_test.dart';

import 'package:fuel_tracker_app/features/geocoding/core/vietnamese_text_utils.dart';

void main() {
  group('VietnameseTextUtils.removeDiacritics', () {
    test('strips Vietnamese diacritics', () {
      expect(
        VietnameseTextUtils.removeDiacritics('Nguyễn Huệ, Quận 1'),
        'Nguyen Hue, Quan 1',
      );
      expect(
        VietnameseTextUtils.removeDiacritics('Hà Nội'),
        'Ha Noi',
      );
    });

    test('leaves ASCII unchanged', () {
      expect(VietnameseTextUtils.removeDiacritics('District 1'), 'District 1');
    });
  });

  group('VietnameseTextUtils.searchVariants', () {
    test('returns single variant for ASCII-only query', () {
      expect(
        VietnameseTextUtils.searchVariants('Landmark 81'),
        ['Landmark 81'],
      );
    });

    test('returns accented then unaccented variants', () {
      expect(
        VietnameseTextUtils.searchVariants('Quận 1'),
        ['Quận 1', 'Quan 1'],
      );
    });
  });

  group('VietnameseTextUtils.formatStructuredAddress', () {
    test('builds street, ward, district, province', () {
      final subtitle = VietnameseTextUtils.formatStructuredAddress({
        'road': 'Nguyễn Huệ',
        'suburb': 'Bến Nghé',
        'city_district': 'Quận 1',
        'city': 'Thành phố Hồ Chí Minh',
      });
      expect(subtitle, contains('Nguyễn Huệ'));
      expect(subtitle, contains('Bến Nghé'));
      expect(subtitle, contains('Quận 1'));
      expect(subtitle, contains('Thành phố Hồ Chí Minh'));
    });
  });
}
