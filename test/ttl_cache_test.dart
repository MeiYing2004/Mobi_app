import 'package:flutter_test/flutter_test.dart';

import 'package:fuel_tracker_app/core/ttl_cache.dart';

void main() {
  group('TtlCache', () {
    test('returns stored value before TTL expires', () {
      final cache = TtlCache<String>(ttl: const Duration(minutes: 5));
      cache.put('k', 'value');
      expect(cache.get('k'), 'value');
    });

    test('evicts expired entries', () async {
      final cache = TtlCache<String>(ttl: const Duration(milliseconds: 20));
      cache.put('k', 'value');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(cache.get('k'), isNull);
    });

    test('evicts oldest when max entries reached', () {
      final cache = TtlCache<int>(ttl: const Duration(minutes: 5), maxEntries: 2);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), 2);
      expect(cache.get('c'), 3);
    });
  });
}
