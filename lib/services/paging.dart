/// One page of a paginated Supabase query.
///
/// [cursor] is an offset into the ordered result set (pass it back to fetch
/// the next page); [hasMore] is true when the server returned a full page,
/// meaning another one may exist. The cursor is intentionally an opaque
/// [Object] so the controller can be exercised without a live backend.
class QueryPage<T> {
  const QueryPage({
    required this.items,
    required this.hasMore,
    this.cursor,
  });

  final List<T> items;
  final bool hasMore;
  final Object? cursor;

  static const QueryPage<Never> empty =
      QueryPage(items: [], hasMore: false);
}
