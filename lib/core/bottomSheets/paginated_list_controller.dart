import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hamrash_admin/core/bottomSheets/paginated_list_cache.dart';

class PaginatedListPage<I> {
  const PaginatedListPage({required this.items, required this.hasMore});
  final List<I> items;
  final bool hasMore;
}

typedef PaginatedListLoader<I> =
    Future<PaginatedListPage<I>> Function({
      required int page,
      required int pageSize,
      String? search,
    });

class PaginatedListLoadError implements Exception {
  const PaginatedListLoadError(this.message);
  final String message;
}

/// One list and page state for browsing and searching remote options.
class PaginatedListController<I> extends ChangeNotifier {
  PaginatedListController({
    required this.loadPage,
    required this.idBuilder,
    required this.matchesSearch,
    this.pageSize = 20,
    this.cache,
  }) : items = List<I>.of(cache?.items ?? []),
       _knownItems = List<I>.of(cache?.items ?? []),
       _browseItems = List<I>.of(cache?.items ?? []);

  final PaginatedListLoader<I> loadPage;
  final String Function(I) idBuilder;
  final bool Function(I, String) matchesSearch;
  final int pageSize;
  final PaginatedListCache<I>? cache;
  List<I> _knownItems;
  List<I> _browseItems;
  int _browsePage = 0;
  bool _browseHasMore = false;
  List<I> items;
  int page = 0;
  bool hasMore = false;
  bool loading = false;
  String query = '';
  String? error;
  int _generation = 0;
  bool _disposed = false;
  Timer? _debounce;

  List<I> get visibleItems => query.trim().isEmpty
      ? items
      : items.where((item) => matchesSearch(item, query.trim())).toList();

  void search(String value, {bool immediately = false}) {
    _debounce?.cancel();
    _generation++;
    query = value;
    error = null;
    loading = false;
    hasMore = false;
    page = 0;
    if (query.trim().isEmpty && _browsePage > 0) {
      items = List<I>.of(_browseItems);
      page = _browsePage;
      hasMore = _browseHasMore;
      notifyListeners();
      return;
    }
    if (query.trim().isNotEmpty &&
        _knownItems.any((item) => matchesSearch(item, query.trim()))) {
      items = List<I>.of(_knownItems);
      notifyListeners();
      return;
    }
    items = query.trim().isEmpty ? List<I>.of(_browseItems) : [];
    loading = true;
    notifyListeners();
    if (immediately) {
      load();
    } else {
      _debounce = Timer(const Duration(milliseconds: 350), () => load());
    }
  }

  Future<void> load({bool more = false}) async {
    if (_disposed || (more && (loading || !hasMore))) return;
    _debounce?.cancel();
    final generation = more ? _generation : ++_generation;
    final search = query.trim();
    if (!more) {
      if (search.isNotEmpty &&
          _knownItems.any((item) => matchesSearch(item, search))) {
        items = List<I>.of(_knownItems);
        page = 0;
        hasMore = false;
        loading = false;
        error = null;
        notifyListeners();
        return;
      }
      items = search.isEmpty ? List<I>.of(cache?.items ?? []) : [];
      page = 0;
      hasMore = false;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      do {
        final response = await loadPage(
          page: page + 1,
          pageSize: pageSize,
          search: search.isEmpty ? null : search,
        );
        if (_disposed || generation != _generation) return;
        // A ten-item preview is not a complete API page. Replace it first.
        final previous = page == 0 ? <I>[] : items;
        final seen = previous.map((item) => idBuilder(item).trim()).toSet();
        items = [
          ...previous,
          ...response.items.where((item) {
            final id = idBuilder(item).trim();
            return id.isNotEmpty && seen.add(id);
          }),
        ];
        page++;
        hasMore = response.hasMore;
        if (search.isEmpty && page == 1) _knownItems = [];
        final known = {for (final item in _knownItems) idBuilder(item): item};
        for (final item in items) {
          known[idBuilder(item)] = item;
        }
        _knownItems = known.values.toList();
        if (search.isEmpty) {
          _browseItems = List<I>.of(items);
          _browsePage = page;
          _browseHasMore = hasMore;
          if (page == 1) cache?.replace(items);
        }
        notifyListeners();
        // Some endpoints ignore search. Continue only until a match is found.
      } while (search.isNotEmpty && visibleItems.isEmpty && hasMore);
    } on PaginatedListLoadError catch (e) {
      if (_disposed || generation != _generation) return;
      error = e.message;
      hasMore = page > 0;
    } catch (_) {
      if (_disposed || generation != _generation) return;
      error = 'Could not load options. Please try again.';
      hasMore = page > 0;
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> retry() => load(more: page > 0);

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _debounce?.cancel();
    super.dispose();
  }
}
