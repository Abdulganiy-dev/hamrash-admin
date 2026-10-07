/// Small in-memory previews, separate from a sheet's live pagination state.
class PaginatedListCache<I> {
  static const previewLimit = 10;
  static const _entryLimit = 32;
  static final _entries = <(Type, Object), Object>{};

  List<I> _items = [];
  List<I> get items => _items;

  /// Keys must distinguish endpoints and filters that change their options.
  static PaginatedListCache<T> forKey<T>(Object key) {
    final typedKey = (T, key);
    final cache =
        _entries.remove(typedKey) as PaginatedListCache<T>? ??
        PaginatedListCache<T>();
    _entries[typedKey] = cache;
    if (_entries.length > _entryLimit) {
      _entries.remove(_entries.keys.first);
    }
    return cache;
  }

  static void clearAll() => _entries.clear();

  void replace(Iterable<I> items) {
    _items = List<I>.unmodifiable(items.take(previewLimit));
  }
}
