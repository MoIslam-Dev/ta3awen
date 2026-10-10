import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_post.dart';
import '../utils/search_keywords.dart';

/// Board (requests) data access. Mirrors [ListingService] shape:
/// equality-filtered queries + client-side sort/filter — no composite
/// indexes needed.
class RequestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('requests');

  List<RequestPost> _sorted(Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final items = docs.map(RequestPost.fromDoc).toList();
    items.sort((a, b) => (b.createdAt ?? DateTime(2000))
        .compareTo(a.createdAt ?? DateTime(2000)));
    return items;
  }

  /// Live board of open posts, newest first. Optionally narrowed to one
  /// type (need/offer, general posts only) or to the blood board.
  /// Matching / closed posts drop out automatically.
  Stream<List<RequestPost>> boardStream({String? type, String? kind}) {
    Query<Map<String, dynamic>> q =
        _col.where('status', isEqualTo: requestStatusOpen);
    if (kind != null) {
      q = q.where('kind', isEqualTo: kind);
    } else if (type != null) {
      q = q.where('type', isEqualTo: type);
    }
    return q.snapshots().map((snap) => _sorted(snap.docs));
  }

  /// Live stream of the current user's own posts (any status).
  Stream<List<RequestPost>> myStream(String uid) {
    return _col
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snap) => _sorted(snap.docs));
  }

  Future<RequestPost?> byId(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return RequestPost.fromDoc(doc);
  }

  Future<String> create(RequestPost post) async {
    final doc = _col.doc();
    await doc.set(post.toMap());
    return doc.id;
  }

  Future<void> update(RequestPost draft) async {
    await _col.doc(draft.id).update({
      'title': draft.title,
      'description': draft.description,
      'category': draft.category,
      'wilaya': draft.wilaya,
      'commune': draft.commune,
      'contactPhone': draft.contactPhone,
      'kind': draft.kind,
      'bloodType': draft.bloodType,
      'keywords': buildKeywords(
        title: draft.title,
        description: draft.description,
        category: draft.category,
        wilaya: draft.wilaya,
        commune: draft.commune,
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setStatus(String id, String status) async {
    await _col.doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Another user answers an open post ("I can help" / "I want this").
  Future<void> match(String id, {required String uid, required String name}) {
    return _col.doc(id).update({
      'status': requestStatusMatched,
      'matchedBy': uid,
      'matchedName': name,
      'matchedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Matcher withdraws (back to open) — same write the owner uses to
  /// release a match; the rules allow both roles.
  Future<void> unmatch(String id) {
    return _col.doc(id).update({
      'status': requestStatusOpen,
      'matchedBy': null,
      'matchedName': null,
      'matchedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
