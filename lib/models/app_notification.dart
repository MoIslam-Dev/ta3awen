/// An in-app notification row. Created server-side by the lifecycle triggers
/// (see `supabase/migrations/20261016000010_notifications.sql`) and delivered
/// over Realtime; the app renders a localized message from [type] + [actorName].
///
/// There is no OS push: a row is visible live while the app is open, or on the
/// next launch otherwise.
class AppNotification {
  final String id;
  final String type;
  final String actorName;
  final String? listingId;
  final String? requestId;
  final DateTime? readAt;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    this.actorName = '',
    this.listingId,
    this.requestId,
    this.readAt,
    this.createdAt,
  });

  bool get isUnread => readAt == null;

  /// The row points at a listing (vs a board/blood post).
  bool get isListing => listingId != null;

  /// The row points at a board/blood post.
  bool get isRequest => requestId != null;

  factory AppNotification.fromRow(Map<String, dynamic> r) => AppNotification(
        id: r['id'] as String,
        type: (r['type'] ?? '') as String,
        actorName: (r['actor_name'] ?? '') as String,
        listingId: r['listing_id'] as String?,
        requestId: r['request_id'] as String?,
        readAt: _dt(r['read_at']),
        createdAt: _dt(r['created_at']),
      );

  AppNotification asRead(DateTime at) => AppNotification(
        id: id,
        type: type,
        actorName: actorName,
        listingId: listingId,
        requestId: requestId,
        readAt: at,
        createdAt: createdAt,
      );
}

DateTime? _dt(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v.toLocal();
  return DateTime.tryParse(v.toString())?.toLocal();
}

// Stored `type` values (must match the CHECK constraint in the migration).
const String notifyListingClaimed = 'listing_claimed';
const String notifyListingReleased = 'listing_released';
const String notifyListingGiven = 'listing_given';
const String notifyRequestMatched = 'request_matched';
const String notifyBloodMatched = 'blood_matched';
const String notifyRequestReleased = 'request_released';
const String notifyRequestClosed = 'request_closed';
const String notifyReportNew = 'report_new';
