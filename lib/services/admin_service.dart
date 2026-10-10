import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/listing.dart';
import '../models/report.dart';
import '../models/request_post.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> isAdmin(String uid) async {
    final doc = await _db.collection('admins').doc(uid).get();
    return doc.exists;
  }

  Stream<List<Listing>> listingsStream({int limit = 500}) => _db
      .collection('listings')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(Listing.fromDoc).toList());

  Stream<List<Report>> reportsStream({int limit = 300}) => _db
      .collection('reports')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(Report.fromDoc).toList());

  Stream<List<AppUser>> usersStream({int limit = 500}) => _db
      .collection('users')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(AppUser.fromDoc).toList());

  Stream<List<RequestPost>> requestsStream({int limit = 300}) => _db
      .collection('requests')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(RequestPost.fromDoc).toList());

  Future<void> deleteListing(String id) async {
    final doc = _db.collection('listings').doc(id);
    final imgs = await doc.collection('images').get();
    final batch = _db.batch();
    for (final d in imgs.docs) {
      batch.delete(d.reference);
    }
    batch.delete(doc);
    await batch.commit();
  }

  /// Doc-IDs of demo listings created by the seed script ('seed-*').
  Future<List<String>> seedListingIds({int limit = 500}) async {
    final snap = await _db
        .collection('listings')
        .where(FieldPath.documentId,
            isGreaterThanOrEqualTo: 'seed-')
        .where(FieldPath.documentId, isLessThan: 'seed-\uf8ff')
        .limit(limit)
        .get();
    return snap.docs.map((d) => d.id).toList();
  }

  /// Bulk delete (incl. images subcollections), chunked under the 500-write
  /// batch limit. Returns the number of listings removed.
  Future<int> deleteListings(List<String> ids) async {
    var deleted = 0;
    for (var i = 0; i < ids.length; i += 40) {
      final chunk = ids.sublist(i, i + 40 > ids.length ? ids.length : i + 40);
      final batch = _db.batch();
      for (final id in chunk) {
        final doc = _db.collection('listings').doc(id);
        final imgs = await doc.collection('images').get();
        for (final d in imgs.docs) {
          batch.delete(d.reference);
        }
        batch.delete(doc);
        deleted++;
      }
      await batch.commit();
    }
    return deleted;
  }

  Future<void> deleteReport(String id) async {
    await _db.collection('reports').doc(id).delete();
  }

  Future<void> setReportStatus(String id, String status) async {
    await _db.collection('reports').doc(id).update({
      'status': status,
      if (status != 'open')
        'resolvedAt': FieldValue.serverTimestamp()
      else
        'resolvedAt': null,
    });
  }

  /// Mark the report resolved and remove the reported listing in one batch.
  Future<void> resolveReportWithContent(Report r) async {
    final batch = _db.batch();
    batch.update(_db.collection('reports').doc(r.id), {
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
    if (r.listingId.isNotEmpty) {
      final doc = _db.collection('listings').doc(r.listingId);
      final imgs = await doc.collection('images').get();
      for (final d in imgs.docs) {
        batch.delete(d.reference);
      }
      batch.delete(doc);
    }
    await batch.commit();
  }

  Future<void> setUserDisabled(String uid, bool disabled,
      {String? reason}) async {
    await _db.collection('users').doc(uid).update({
      'disabled': disabled,
      if (disabled) 'disabledReason': reason,
      if (disabled) 'disabledAt': FieldValue.serverTimestamp()
      else ...{
        'disabledReason': null,
        'disabledAt': null,
      },
    });
  }
}
