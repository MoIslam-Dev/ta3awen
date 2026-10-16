import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/paging.dart';
import '../utils/constants.dart';

typedef HeadBuilder<T> = Stream<QueryPage<T>> Function(int limit);

/// Fetches the next page after an opaque [cursor] (see [QueryPage.cursor]).
typedef MoreBuilder<T> = Future<QueryPage<T>> Function(Object? cursor, int limit);

/// Drives a paginated Supabase list with a live first page.
///
/// * The **head** (newest [pageSize] items) stays subscribed so new/updated
///   documents appear without a manual refresh.
/// * Older **tail** pages are fetched one-shot on demand ([loadMore]) and
///   never listened to, so scrolling costs one query per page instead of a
///   permanent listener over the whole collection.
///
/// This keeps read usage proportional to what the user actually looks at —
/// important to keep the read budget healthy.
class PagedList<T> extends ChangeNotifier {
  PagedList({
    required this.headBuilder,
    required this.moreBuilder,
    this.idOf,
    this.pageSize = kPageSize,
  });

  final HeadBuilder<T> headBuilder;
  final MoreBuilder<T> moreBuilder;

  /// Stable identity used to de-duplicate head/tail overlaps. When null,
  /// items are concatenated as-is.
  final String Function(T item)? idOf;

  final int pageSize;

  final List<T> _head = [];
  final List<T> _tail = [];
  StreamSubscription<QueryPage<T>>? _sub;
  Object? _cursor;
  bool _primed = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  Object? _error;

  List<T> get items {
    final id = idOf;
    if (id == null) return List.unmodifiable([..._head, ..._tail]);
    final seen = <String>{};
    final out = <T>[];
    for (final item in _head) {
      if (seen.add(id(item))) out.add(item);
    }
    for (final item in _tail) {
      if (seen.add(id(item))) out.add(item);
    }
    return out;
  }

  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  Object? get error => _error;
  bool get isEmpty => _head.isEmpty && _tail.isEmpty;

  /// (Re)subscribes to the live head. Call on init and on refresh.
  void start() {
    _sub?.cancel();
    _head.clear();
    _tail.clear();
    _cursor = null;
    _primed = false;
    _hasMore = false;
    _loadingMore = false;
    _loading = true;
    _error = null;
    _sub = headBuilder(pageSize).listen(
      (page) {
        _head
          ..clear()
          ..addAll(page.items);
        // Latch the paging cursor on the first emission so later head
        // updates (new posts) do not shift the "older than" boundary.
        if (!_primed) {
          _cursor = page.cursor;
          _hasMore = page.hasMore;
          _primed = true;
        }
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e;
        _loading = false;
        notifyListeners();
      },
    );
    notifyListeners();
  }

  /// Fetches the next older page. Errors are rethrown so the caller can
  /// surface a snackbar without wiping the already-loaded content.
  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || _cursor == null) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await moreBuilder(_cursor!, pageSize);
      _tail.addAll(page.items);
      if (page.hasMore && page.cursor != null) _cursor = page.cursor;
      _hasMore = page.hasMore;
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  /// Optimistically drops [item] (after a delete) without a round-trip.
  void remove(T item) {
    _head.remove(item);
    _tail.remove(item);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
