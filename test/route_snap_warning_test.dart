import 'package:flutter_test/flutter_test.dart';

import 'package:fuel_tracker_app/features/navigation/core/route_snap_warning.dart';

void main() {
  group('RouteSnapWarning', () {
    test('ignores snap under 50m', () {
      expect(RouteSnapWarning.messageForSnapMeters(30), isNull);
      expect(RouteSnapWarning.messageForSnapMeters(49), isNull);
    });

    test('mild warning between 50 and 200m', () {
      final msg = RouteSnapWarning.messageForSnapMeters(120);
      expect(msg, isNotNull);
      expect(msg, contains('120'));
      expect(RouteSnapWarning.isStrongWarning(120), isFalse);
    });

    test('strong warning above 200m', () {
      final msg = RouteSnapWarning.messageForSnapMeters(520);
      expect(msg, isNotNull);
      expect(msg, contains('520'));
      expect(RouteSnapWarning.isStrongWarning(520), isTrue);
    });
  });
}
