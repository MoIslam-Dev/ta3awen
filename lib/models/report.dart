import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String listingId;
  final String listingTitle;
  final String reporterId;
  final String reporterName;
  final String reason;
  final String? description;
  final DateTime? createdAt;

  const Report({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.reporterId,
    required this.reporterName,
    required this.reason,
    this.description,
    this.createdAt,
  });

  factory Report.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return Report(
      id: doc.id,
      listingId: (d['listingId'] ?? '') as String,
      listingTitle: (d['listingTitle'] ?? '') as String,
      reporterId: (d['reporterId'] ?? '') as String,
      reporterName: (d['reporterName'] ?? '') as String,
      reason: (d['reason'] ?? '') as String,
      description: d['description'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'listingId': listingId,
        'listingTitle': listingTitle,
        'reporterId': reporterId,
        'reporterName': reporterName,
        'reason': reason,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
