import '../core/supabase.dart';

class Listing {
  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final String description;
  final String category;
  final String wilaya;
  final String commune;
  final String condition;
  final String status;

  /// 'تبرع' (free donation, default) or 'تبادل' (barter/exchange).
  /// Exchange listings follow the exact same lifecycle; only this tag
  /// (and the card badge) sets them apart — no chat, no negotiation.
  final String kind;
  final String? contactPhone;

  /// Public URL of the 480px cover (resolved from `cover_path`), or null.
  final String? image0;
  final int imageCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? claimedBy;
  final String? claimedByName;
  final DateTime? claimedAt;

  /// Marked by the seed script so the admin console can bulk-remove demo data.
  final bool isDemo;

  const Listing({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.description,
    required this.category,
    required this.wilaya,
    required this.commune,
    required this.condition,
    required this.status,
    this.kind = listingKindDonation,
    this.contactPhone,
    this.image0,
    this.imageCount = 0,
    this.createdAt,
    this.updatedAt,
    this.claimedBy,
    this.claimedByName,
    this.claimedAt,
    this.isDemo = false,
  });

  bool get isAvailable => status == statusAvailable;

  bool get isExchange => kind == listingKindExchange;

  /// Reserved by another user — hidden from the feed until the owner
  /// confirms delivery or the claim is cancelled.
  bool get isReserved => status == statusReserved;

  factory Listing.fromRow(Map<String, dynamic> r) {
    final coverPath = r['cover_path'] as String?;
    return Listing(
      id: r['id'] as String,
      ownerId: (r['owner_id'] ?? '') as String,
      ownerName: (r['owner_name'] ?? '') as String,
      title: (r['title'] ?? '') as String,
      description: (r['description'] ?? '') as String,
      category: (r['category'] ?? '') as String,
      wilaya: (r['wilaya'] ?? '') as String,
      commune: (r['commune'] ?? '') as String,
      condition: (r['condition'] ?? '') as String,
      status: (r['status'] ?? statusAvailable) as String,
      kind: (r['kind'] ?? listingKindDonation) as String,
      contactPhone: r['contact_phone'] as String?,
      image0: (coverPath == null || coverPath.isEmpty)
          ? null
          : storagePublicUrl(coverPath),
      imageCount: ((r['image_count'] ?? 0) as num).toInt(),
      createdAt: _dt(r['created_at']),
      updatedAt: _dt(r['updated_at']),
      claimedBy: r['claimed_by'] as String?,
      claimedByName: r['claimed_by_name'] as String?,
      claimedAt: _dt(r['claimed_at']),
      isDemo: (r['is_demo'] ?? false) as bool,
    );
  }

  /// Insert payload. Claim keys are deliberately absent (the DB trigger owns
  /// them); images/cover are written by the service after the row exists.
  Map<String, dynamic> toMap() => {
        'owner_id': ownerId,
        'owner_name': ownerName,
        'title': title,
        'description': description,
        'category': category,
        'wilaya': wilaya,
        'commune': commune,
        'condition': condition,
        'status': status,
        'kind': kind,
        'contact_phone': contactPhone,
      };
}

DateTime? _dt(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v.toLocal();
  return DateTime.tryParse(v.toString())?.toLocal();
}

const String statusAvailable = 'متاح';
const String statusReserved = 'محجوز';
const String statusGiven = 'تم التبرع به';

/// Listing nature, stored as a stable value (never translated).
const String listingKindDonation = 'تبرع';
const String listingKindExchange = 'تبادل';
