/// Cache TTL đơn giản — dùng cho kết quả geocoding Nominatim.
class TtlCache<T> {
  TtlCache({
    required this.ttl,
    this.maxEntries = 128,
  });

  final Duration ttl;
  final int maxEntries;

  final _entries = <String, _CacheEntry<T>>{};

  T? get(String key) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.at) > ttl) {
      _entries.remove(key);
      return null;
    }
    return entry.value;
  }

  void put(String key, T value) {
    if (_entries.length >= maxEntries && !_entries.containsKey(key)) {
      _evictOldest();
    }
    _entries[key] = _CacheEntry(value, DateTime.now());
  }

  void clear() => _entries.clear();

  void _evictOldest() {
    if (_entries.isEmpty) return;
    String? oldestKey;
    DateTime? oldestAt;
    for (final e in _entries.entries) {
      if (oldestAt == null || e.value.at.isBefore(oldestAt)) {
        oldestAt = e.value.at;
        oldestKey = e.key;
      }
    }
    if (oldestKey != null) _entries.remove(oldestKey);
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime at;
  const _CacheEntry(this.value, this.at);
}
