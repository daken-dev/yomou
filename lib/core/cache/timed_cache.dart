class TimedCache<Key, Value> {
  TimedCache({required this.ttl, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Duration ttl;
  final DateTime Function() _now;
  final Map<Key, _CacheEntry<Value>> _entries = <Key, _CacheEntry<Value>>{};

  Value? get(Key key) {
    final entry = _entries[key];
    if (entry == null) {
      return null;
    }

    if (_now().difference(entry.cachedAt) > ttl) {
      _entries.remove(key);
      return null;
    }

    return entry.value;
  }

  void set(Key key, Value value) {
    _entries[key] = _CacheEntry<Value>(value: value, cachedAt: _now());
  }

  void clear() {
    _entries.clear();
  }
}

class _CacheEntry<Value> {
  const _CacheEntry({required this.value, required this.cachedAt});

  final Value value;
  final DateTime cachedAt;
}
