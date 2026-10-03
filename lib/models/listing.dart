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
  final String? contactPhone;
  final String? image0;
  final int imageCount;
  final List<String> keywords;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.contactPhone,
    this.image0,
    this.imageCount = 0,
    this.keywords = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool get isAvailable => status == statusAvailable;

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
      contactPhone: d['contactPhone'] as String?,
      image0: d['image0'] as String?,
      imageCount: ((d['imageCount'] ?? 0) as num).toInt(),
      keywords: List<String>.from(d['keywords'] as List? ?? const []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
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
const String statusGiven = 'تم التبرع به';
