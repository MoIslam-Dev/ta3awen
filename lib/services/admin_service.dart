import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/listing.dart';
import '../models/report.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> isAdmin(String uid) async {
    final doc = await _db.collection('admins').doc(uid).get();
    return doc.exists;
  }

  Future<List<Listing>> allListings() async {
    final snap = await _db
        .collection('listings')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    return snap.docs.map(Listing.fromDoc).toList();
  }

  Future<List<Report>> allReports() async {
    final snap = await _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    return snap.docs.map(Report.fromDoc).toList();
  }

  Future<List<AppUser>> allUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs.map(AppUser.fromDoc).toList();
  }

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

  Future<void> deleteReport(String id) async {
    await _db.collection('reports').doc(id).delete();
  }

  Future<void> setUserDisabled(String uid, bool disabled) async {
    await _db.collection('users').doc(uid).update({'disabled': disabled});
  }
}
