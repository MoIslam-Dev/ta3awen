import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/search_keywords.dart';

/// A post on the community board: either something the author needs
/// (`need`) or something they can provide (`offer`). Matching connects
/// the two sides; the board itself holds no images.
class RequestPost {
  final String id;
  final String uid;
  final String userName;
  final String type;
  final String title;
  final String description;
  final String category;
  final String wilaya;
  final String commune;
  final String? contactPhone;
  final String status;

  /// 'general' (default) or 'blood' — blood posts are always type need
  /// and carry a valid [bloodType].
  final String kind;
  final String? bloodType;

  final String? matchedBy;
  final String? matchedName;
  final DateTime? matchedAt;
  final List<String> keywords;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RequestPost({
    required this.id,
    required this.uid,
    required this.userName,
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    required this.wilaya,
    required this.commune,
    this.contactPhone,
    this.status = requestStatusOpen,
    this.kind = requestKindGeneral,
    this.bloodType,
    this.matchedBy,
    this.matchedName,
    this.matchedAt,
    this.keywords = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool get isOpen => status == requestStatusOpen;

  bool get isMatched => status == requestStatusMatched;

  bool get isClosed => status == requestStatusClosed;

  bool get isBlood => kind == requestKindBlood;

  factory RequestPost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return RequestPost(
      id: doc.id,
      uid: (d['uid'] ?? '') as String,
      userName: (d['userName'] ?? '') as String,
      type: (d['type'] ?? requestTypeNeed) as String,
      title: (d['title'] ?? '') as String,
      description: (d['description'] ?? '') as String,
      category: (d['category'] ?? '') as String,
      wilaya: (d['wilaya'] ?? '') as String,
      commune: (d['commune'] ?? '') as String,
      contactPhone: d['contactPhone'] as String?,
      status: (d['status'] ?? requestStatusOpen) as String,
      kind: (d['kind'] ?? requestKindGeneral) as String,
      bloodType: d['bloodType'] as String?,
      matchedBy: d['matchedBy'] as String?,
      matchedName: d['matchedName'] as String?,
      matchedAt: (d['matchedAt'] as Timestamp?)?.toDate(),
      keywords: List<String>.from(d['keywords'] as List? ?? const []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Client create shape: new posts always start [requestStatusOpen];
  /// match keys are deliberately absent (the create rule rejects them).
  Map<String, dynamic> toMap() => {
        'uid': uid,
        'userName': userName,
        'type': type,
        'title': title,
        'description': description,
        'category': category,
        'wilaya': wilaya,
        'commune': commune,
        'contactPhone': contactPhone,
        'status': requestStatusOpen,
        'kind': kind,
        'bloodType': bloodType,
        'keywords': buildKeywords(
          title: title,
          description: description,
          category: category,
          wilaya: wilaya,
          commune: commune,
        ),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

const String requestStatusOpen = 'open';
const String requestStatusMatched = 'matched';
const String requestStatusClosed = 'closed';

const String requestTypeNeed = 'need';
const String requestTypeOffer = 'offer';

const String requestKindGeneral = 'general';
const String requestKindBlood = 'blood';
