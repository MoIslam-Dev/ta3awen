import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing.dart';

class ListingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('listings');

  Future<List<Listing>> recent({int limit = 100}) async {
    final snap =
        await _col.orderBy('createdAt', descending: true).limit(limit).get();
    return snap.docs.map(Listing.fromDoc).toList();
  }

  Future<List<Listing>> myListings(String uid) async {
    final snap = await _col.where('ownerId', isEqualTo: uid).get();
    final items = snap.docs.map(Listing.fromDoc).toList();
    items.sort((a, b) => (b.createdAt ?? DateTime(2000))
        .compareTo(a.createdAt ?? DateTime(2000)));
    return items;
  }

  Future<List<Listing>> byIds(List<String> ids) async {
    final items = <Listing>[];
    for (final id in ids) {
      final doc = await _col.doc(id).get();
      if (doc.exists) items.add(Listing.fromDoc(doc));
    }
    return items;
  }

  Future<Listing?> byId(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Listing.fromDoc(doc);
  }

  Future<String> create({
    required Listing draft,
    required List<String> imagesB64,
  }) async {
    final doc = _col.doc();
    final data = draft.toMap();
    data['imageCount'] = imagesB64.length;
    // Create the listing first: the images security rule reads the parent
    // listing with get(), which cannot see documents created in the same
    // batch — so images must be written in a second, separate commit.
    await doc.set(data);
    if (imagesB64.isNotEmpty) {
      final batch = _db.batch();
      for (var i = 0; i < imagesB64.length; i++) {
        batch.set(doc.collection('images').doc(), {
          'index': i,
          'data': imagesB64[i],
        });
      }
      try {
        await batch.commit();
      } catch (_) {
        // Don't leave a listing without its images behind.
        try {
          await doc.delete();
        } catch (_) {}
        rethrow;
      }
    }
    return doc.id;
  }

  Future<void> update({
    required Listing draft,
    List<String>? newImagesB64,
    String? thumbB64,
  }) async {
    final doc = _col.doc(draft.id);
    final batch = _db.batch();
    final data = <String, dynamic>{
      'ownerName': draft.ownerName,
      'title': draft.title,
      'description': draft.description,
      'category': draft.category,
      'wilaya': draft.wilaya,
      'commune': draft.commune,
      'condition': draft.condition,
      'status': draft.status,
      'contactPhone': draft.contactPhone,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (newImagesB64 != null) {
      data['image0'] = thumbB64;
      data['imageCount'] = newImagesB64.length;
      final existing = await doc.collection('images').get();
      for (final d in existing.docs) {
        batch.delete(d.reference);
      }
      for (var i = 0; i < newImagesB64.length; i++) {
        batch.set(doc.collection('images').doc(), {
          'index': i,
          'data': newImagesB64[i],
        });
      }
    }
    batch.update(doc, data);
    await batch.commit();
  }

  Future<void> setStatus(String id, String status) async {
    await _col.doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) async {
    final doc = _col.doc(id);
    final imgs = await doc.collection('images').get();
    final batch = _db.batch();
    for (final d in imgs.docs) {
      batch.delete(d.reference);
    }
    batch.delete(doc);
    await batch.commit();
  }

  Future<List<String>> imagesOf(String id) async {
    final snap = await _col.doc(id).collection('images').orderBy('index').get();
    return snap.docs
        .map((d) => (d.data()['data'] ?? '') as String)
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
