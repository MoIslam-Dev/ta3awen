import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_post.dart';
import '../utils/constants.dart';
import '../utils/search_keywords.dart';
import 'paging.dart';

/// Board (requests) data access. Every read is paginated: a live head
/// (newest page) plus one-shot older pages, so the app never streams a whole
/// collection from Firestore.
class RequestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('requests');

  /// Open posts, newest first — optionally narrowed by [kind]
  /// (general/blood) and/or [type] (need/offer). Ordered by `createdAt`,
  /// which needs the composite indexes declared in firestore.indexes.json.
  Query<Map<String, dynamic>> _boardQuery({String? type, String? kind}) {
    Query<Map<String, dynamic>> q =
        _col.where('status', isEqualTo: requestStatusOpen);
    if (kind != null) q = q.where('kind', isEqualTo: kind);
    if (type != null) q = q.where('type', isEqualTo: type);
    return q.orderBy('createdAt', descending: true);
  }

  QueryPage<RequestPost> _page(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, int limit) {
    return QueryPage(
      items: docs.map(RequestPost.fromDoc).toList(),
      cursor: docs.length >= limit ? docs.last : null,
      hasMore: docs.length >= limit,
    );
  }

  /// Live first page of the open board.
  Stream<QueryPage<RequestPost>> boardHead({
    String? type,
    String? kind,
    int limit = kPageSize,
  }) {
    return _boardQuery(type: type, kind: kind)
        .limit(limit)
        .snapshots()
        .map((snap) => _page(snap.docs, limit));
  }

  /// One-shot older page of the open board.
  Future<QueryPage<RequestPost>> boardMore({
    String? type,
    String? kind,
    required Object? cursor,
    int limit = kPageSize,
  }) async {
    final snap = await _boardQuery(type: type, kind: kind)
        .startAfterDocument(cursor as DocumentSnapshot<Map<String, dynamic>>)
        .limit(limit)
        .get();
    return _page(snap.docs, limit);
  }

  Query<Map<String, dynamic>> _myQuery(String uid) =>
      _col.where('uid', isEqualTo: uid).orderBy('createdAt', descending: true);

  /// Live first page of the current user's own posts (any status).
  Stream<QueryPage<RequestPost>> myHead(String uid, {int limit = kPageSize}) =>
      _myQuery(uid).limit(limit).snapshots().map((snap) => _page(snap.docs, limit));

  /// One-shot older page of the current user's own posts.
  Future<QueryPage<RequestPost>> myMore(
    String uid,
    Object? cursor, {
    int limit = kPageSize,
  }) async {
    final snap = await _myQuery(uid)
        .startAfterDocument(cursor as DocumentSnapshot<Map<String, dynamic>>)
        .limit(limit)
        .get();
    return _page(snap.docs, limit);
  }

  Future<RequestPost?> byId(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return RequestPost.fromDoc(doc);
  }

  Future<String> create(RequestPost post) async {
    final doc = _col.doc();
    // Create the post and bump the lifetime post counter in one batch
    // (rules enforce stats/{uid}.postCount < 100 on every create).
    final batch = _db.batch();
    batch.set(doc, post.toMap());
    batch.set(
      _db.collection('stats').doc(post.uid),
      {'postCount': FieldValue.increment(1)},
      SetOptions(merge: true),
    );
    await batch.commit();
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
