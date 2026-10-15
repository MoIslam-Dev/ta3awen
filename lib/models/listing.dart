import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/search_keywords.dart';

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
  final String? image0;
  final int imageCount;
  final List<String> keywords;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? claimedBy;
  final String? claimedByName;
  final DateTime? claimedAt;

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
    this.keywords = const [],
    this.createdAt,
    this.updatedAt,
    this.claimedBy,
    this.claimedByName,
    this.claimedAt,
  });

  bool get isAvailable => status == statusAvailable;

  bool get isExchange => kind == listingKindExchange;

  /// Reserved by another user — hidden from the feed until the owner
  /// confirms delivery or the claim is cancelled.
  bool get isReserved => status == statusReserved;

  factory Listing.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return Listing(
      id: doc.id,
      ownerId: (d['ownerId'] ?? '') as String,
      ownerName: (d['ownerName'] ?? '') as String,
      title: (d['title'] ?? '') as String,
      description: (d['description'] ?? '') as String,
      category: (d['category'] ?? '') as String,
      wilaya: (d['wilaya'] ?? '') as String,
      commune: (d['commune'] ?? '') as String,
      condition: (d['condition'] ?? '') as String,
      status: (d['status'] ?? statusAvailable) as String,
      kind: (d['kind'] ?? listingKindDonation) as String,
      contactPhone: d['contactPhone'] as String?,
      image0: d['image0'] as String?,
      imageCount: ((d['imageCount'] ?? 0) as num).toInt(),
      keywords: List<String>.from(d['keywords'] as List? ?? const []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      claimedBy: d['claimedBy'] as String?,
      claimedByName: d['claimedByName'] as String?,
      claimedAt: (d['claimedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'ownerName': ownerName,
        'title': title,
        'description': description,
        'category': category,
        'wilaya': wilaya,
        'commune': commune,
        'condition': condition,
        'status': status,
        'kind': kind,
        'contactPhone': contactPhone,
        'image0': image0,
        'imageCount': imageCount,
        'keywords': buildKeywords(
          title: title,
          description: description,
          category: category,
          wilaya: wilaya,
          commune: commune,
          condition: condition,
        ),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

const String statusAvailable = 'متاح';
const String statusReserved = 'محجوز';
const String statusGiven = 'تم التبرع به';

/// Listing nature, stored as a stable value (never translated).
const String listingKindDonation = 'تبرع';
const String listingKindExchange = 'تبادل';
