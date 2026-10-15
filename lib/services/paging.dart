/// One page of a paginated Firestore query.
///
/// [cursor] is the last document of the page (pass it to `startAfterDocument`
/// to fetch the next one); [hasMore] is true when the server returned a full
/// page, meaning another one may exist. The cursor is intentionally an opaque
/// [Object] so the controller can be exercised without Firestore.
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
