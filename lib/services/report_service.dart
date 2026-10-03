import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';

class ReportService {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('reports');

  Future<void> create({
    required String listingId,
    required String listingTitle,
    required String reporterId,
    required String reporterName,
    required String reason,
    String? description,
  }) async {
    final report = Report(
      id: '',
      listingId: listingId,
      listingTitle: listingTitle,
      reporterId: reporterId,
      reporterName: reporterName,
      reason: reason,
      description: description,
    );
    await _col.add(report.toMap());
  }

  Future<List<Report>> recent({int limit = 100}) async {
    final snap =
        await _col.orderBy('createdAt', descending: true).limit(limit).get();
    return snap.docs.map(Report.fromDoc).toList();
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
