import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/listing.dart';
import '../models/report.dart';
import '../models/request_post.dart';
import '../utils/constants.dart';
import 'paging.dart';

/// Admin data access. Every list is paginated and counts use Firestore
/// aggregation queries (`.count()`), which cost ~1 read per 1000 documents
/// instead of loading whole collections — critical on the free tier.
class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> isAdmin(String uid) async {
    final doc = await _db.collection('admins').doc(uid).get();
    return doc.exists;
  }

  // ---- Aggregations (cheap counts) ---------------------------------------

  Future<int> _count(Query<Object?> q) async =>
      (await q.count().get()).count ?? 0;

  Future<int> countUsers({bool? disabled}) {
    Query<Map<String, dynamic>> q = _db.collection('users');
    if (disabled != null) q = q.where('disabled', isEqualTo: disabled);
    return _count(q);
  }

  Future<int> countListings({String? status}) {
    Query<Map<String, dynamic>> q = _db.collection('listings');
    if (status != null) q = q.where('status', isEqualTo: status);
    return _count(q);
  }

  Future<int> countRequests({String? status, String? kind}) {
    Query<Map<String, dynamic>> q = _db.collection('requests');
    if (status != null) q = q.where('status', isEqualTo: status);
    if (kind != null) q = q.where('kind', isEqualTo: kind);
    return _count(q);
  }

  Future<int> countReports({String? status}) {
    Query<Map<String, dynamic>> q = _db.collection('reports');
    if (status != null) q = q.where('status', isEqualTo: status);
    return _count(q);
  }

  // ---- Paginated lists ---------------------------------------------------

  Query<Map<String, dynamic>> _listingsQuery(String? status) {
    Query<Map<String, dynamic>> q = _db.collection('listings');
    if (status != null) q = q.where('status', isEqualTo: status);
    return q.orderBy('createdAt', descending: true);
  }

  QueryPage<Listing> _listingPage(List<QueryDocumentSnapshot<Map<String, dynamic>>> d, int limit) =>
      QueryPage(
        items: d.map(Listing.fromDoc).toList(),
        cursor: d.length >= limit ? d.last : null,
        hasMore: d.length >= limit,
      );

  Stream<QueryPage<Listing>> listingsHead({String? status, int limit = kPageSize}) =>
      _listingsQuery(status).limit(limit).snapshots().map((s) => _listingPage(s.docs, limit));

  Future<QueryPage<Listing>> listingsMore(String? status, Object? cursor,
      {int limit = kPageSize}) async {
    final s = await _listingsQuery(status)
        .startAfterDocument(cursor as DocumentSnapshot<Map<String, dynamic>>)
        .limit(limit)
        .get();
    return _listingPage(s.docs, limit);
  }

  Query<Map<String, dynamic>> _requestsQuery(String? status, String? kind) {
    Query<Map<String, dynamic>> q = _db.collection('requests');
    if (status != null) q = q.where('status', isEqualTo: status);
    if (kind != null) q = q.where('kind', isEqualTo: kind);
    return q.orderBy('createdAt', descending: true);
  }

  QueryPage<RequestPost> _requestPage(List<QueryDocumentSnapshot<Map<String, dynamic>>> d, int limit) =>
      QueryPage(
        items: d.map(RequestPost.fromDoc).toList(),
        cursor: d.length >= limit ? d.last : null,
        hasMore: d.length >= limit,
      );

  Stream<QueryPage<RequestPost>> requestsHead({String? status, int limit = kPageSize}) =>
      _requestsQuery(status, null).limit(limit).snapshots().map((s) => _requestPage(s.docs, limit));

  Future<QueryPage<RequestPost>> requestsMore(String? status, Object? cursor,
      {int limit = kPageSize}) async {
    final s = await _requestsQuery(status, null)
        .startAfterDocument(cursor as DocumentSnapshot<Map<String, dynamic>>)
        .limit(limit)
        .get();
    return _requestPage(s.docs, limit);
  }

  Query<Map<String, dynamic>> _usersQuery(String? search) {
    Query<Map<String, dynamic>> q = _db.collection('users');
    final s = search?.trim() ?? '';
    if (s.isNotEmpty) {
      q = q
          .where('fullName', isGreaterThanOrEqualTo: s)
          .where('fullName', isLessThan: '$s\uf8ff')
          .orderBy('fullName');
    } else {
      q = q.orderBy('createdAt', descending: true);
    }
    return q;
  }

  QueryPage<AppUser> _userPage(List<QueryDocumentSnapshot<Map<String, dynamic>>> d, int limit) =>
      QueryPage(
        items: d.map(AppUser.fromDoc).toList(),
        cursor: d.length >= limit ? d.last : null,
        hasMore: d.length >= limit,
      );

  Stream<QueryPage<AppUser>> usersHead({String? search, int limit = kPageSize}) =>
      _usersQuery(search).limit(limit).snapshots().map((s) => _userPage(s.docs, limit));

  Future<QueryPage<AppUser>> usersMore(String? search, Object? cursor,
      {int limit = kPageSize}) async {
    final s = await _usersQuery(search)
        .startAfterDocument(cursor as DocumentSnapshot<Map<String, dynamic>>)
        .limit(limit)
        .get();
    return _userPage(s.docs, limit);
  }

  Query<Map<String, dynamic>> get _reportsQuery =>
      _db.collection('reports').orderBy('createdAt', descending: true);

  QueryPage<Report> _reportPage(List<QueryDocumentSnapshot<Map<String, dynamic>>> d, int limit) =>
      QueryPage(
        items: d.map(Report.fromDoc).toList(),
        cursor: d.length >= limit ? d.last : null,
        hasMore: d.length >= limit,
      );

  Stream<QueryPage<Report>> reportsHead({int limit = kPageSize}) =>
      _reportsQuery.limit(limit).snapshots().map((s) => _reportPage(s.docs, limit));

  Future<QueryPage<Report>> reportsMore(Object? cursor,
      {int limit = kPageSize}) async {
    final s = await _reportsQuery
        .startAfterDocument(cursor as DocumentSnapshot<Map<String, dynamic>>)
        .limit(limit)
        .get();
    return _reportPage(s.docs, limit);
  }

  // ---- Content moderation ------------------------------------------------

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

  /// Cheap count of demo listings created by the seed script ('seed-*').
  Future<int> countSeedListings() => _count(_db
      .collection('listings')
      .where(FieldPath.documentId, isGreaterThanOrEqualTo: 'seed-')
      .where(FieldPath.documentId, isLessThan: 'seed-\uf8ff'));

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

  Future<void> deleteRequest(String id) =>
      _db.collection('requests').doc(id).delete();

  Future<int> deleteRequests(List<String> ids) async {
    var deleted = 0;
    for (var i = 0; i < ids.length; i += 400) {
      final chunk = ids.sublist(i, i + 400 > ids.length ? ids.length : i + 400);
      final batch = _db.batch();
      for (final id in chunk) {
        batch.delete(_db.collection('requests').doc(id));
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

  // ---- User administration ----------------------------------------------

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

  /// Grant or revoke admin rights (writes `admins/{uid}`).
  Future<void> setAdmin(String uid, bool value) async {
    final ref = _db.collection('admins').doc(uid);
    if (value) {
      await ref.set({'grantedAt': FieldValue.serverTimestamp()});
    } else {
      await ref.delete();
    }
  }

  /// Count of listings owned by [uid].
  Future<int> countUserListings(String uid) =>
      _count(_db.collection('listings').where('ownerId', isEqualTo: uid));

  /// Count of requests authored by [uid].
  Future<int> countUserRequests(String uid) =>
      _count(_db.collection('requests').where('uid', isEqualTo: uid));

  /// Permanently deletes everything [uid] owns: listings (with images),
  /// board posts, their reports, counters, admin rights and the profile
  /// document. The Firebase Auth account itself must be removed from the
  /// console / Admin SDK.
  Future<void> deleteUserData(String uid) async {
    final listingIds = (await _db
            .collection('listings')
            .where('ownerId', isEqualTo: uid)
            .get())
        .docs
        .map((d) => d.id)
        .toList();
    await deleteListings(listingIds);

    final requestIds =
        (await _db.collection('requests').where('uid', isEqualTo: uid).get())
            .docs
            .map((d) => d.id)
            .toList();
    await deleteRequests(requestIds);

    final reportIds = (await _db
            .collection('reports')
            .where('reporterId', isEqualTo: uid)
            .get())
        .docs
        .map((d) => d.id)
        .toList();
    for (var i = 0; i < reportIds.length; i += 400) {
      final chunk =
          reportIds.sublist(i, i + 400 > reportIds.length ? reportIds.length : i + 400);
      final batch = _db.batch();
      for (final id in chunk) {
        batch.delete(_db.collection('reports').doc(id));
      }
      await batch.commit();
    }

    final batch = _db.batch();
    batch.delete(_db.collection('users').doc(uid));
    batch.delete(_db.collection('stats').doc(uid));
    batch.delete(_db.collection('admins').doc(uid));
    await batch.commit();
  }
}
