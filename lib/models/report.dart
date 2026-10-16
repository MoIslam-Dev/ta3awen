class Report {
  final String id;
  final String listingId;
  final String listingTitle;
  final String reporterId;
  final String reporterName;
  final String reason;
  final String? description;
  final DateTime? createdAt;

  /// Moderation workflow: 'open' (DB default), 'resolved', 'dismissed'.
  final String status;
  final DateTime? resolvedAt;

  const Report({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.reporterId,
    required this.reporterName,
    required this.reason,
    this.description,
    this.createdAt,
    this.status = reportStatusOpen,
    this.resolvedAt,
  });

  bool get isOpen => status == reportStatusOpen;
  bool get isResolved => status == reportStatusResolved;
  bool get isDismissed => status == reportStatusDismissed;

  factory Report.fromRow(Map<String, dynamic> r) {
    return Report(
      id: r['id'] as String,
      listingId: (r['listing_id'] ?? '') as String,
      listingTitle: (r['listing_title'] ?? '') as String,
      reporterId: (r['reporter_id'] ?? '') as String,
      reporterName: (r['reporter_name'] ?? '') as String,
      reason: (r['reason'] ?? '') as String,
      description: r['description'] as String?,
      createdAt: _dt(r['created_at']),
      status: (r['status'] ?? reportStatusOpen) as String,
      resolvedAt: _dt(r['resolved_at']),
    );
  }

  /// Create payload: status/resolved_at are server-owned (default 'open').
  Map<String, dynamic> toMap() => {
        'listing_id': listingId.isEmpty ? null : listingId,
        'listing_title': listingTitle,
        'reporter_id': reporterId,
        'reporter_name': reporterName,
        'reason': reason,
        'description': description,
      };
}

DateTime? _dt(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v.toLocal();
  return DateTime.tryParse(v.toString())?.toLocal();
}

const String reportStatusOpen = 'open';
const String reportStatusResolved = 'resolved';
const String reportStatusDismissed = 'dismissed';
