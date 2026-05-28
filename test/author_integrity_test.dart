import 'package:flutter_test/flutter_test.dart';

import 'package:fuel_tracker_app/core/author_integrity_guard.dart';
import 'package:fuel_tracker_app/core/constants.dart';

void main() {
  test('Author credit must stay unchanged', () {
    expect(
      AppConstants.authorCredit,
      AuthorIntegrityGuard.requiredAuthorCredit,
    );
  });

  test('Author integrity guard should pass', () {
    expect(() => AuthorIntegrityGuard.enforce(), returnsNormally);
  });
}
