import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing.dart';
import '../utils/search_keywords.dart';

/// Server-side feed query: status is always filtered to available listings;
/// the optional facets and the search text become Firestore equality /
/// `arrayContainsAny` clauses so the database — not the client window —
/// decides which listings match.
class FeedQuery {
  const FeedQuery({this.search, this.category, this.wilaya, this.commune});

  final String? search;
  final String? category;
  final String? wilaya;
  final String? commune;

  /// Query words sent to `arrayContainsAny` (max 30 values per Firestore).
  List<String> get searchWords {
    final s = search ?? '';
    if (s.trim().isEmpty) return const [];
    return searchTokens(s).take(kMaxQueryTokens).toList();
  }
}

/// One page of feed results.
///
/// [items] is AND-filtered for display; [rawIds] and [boundary] describe the
/// raw server window (the oldest raw document's `createdAt`) so the screen
/// can merge live head events without dropping or duplicating items.
class FeedPage {
  const FeedPage({
    required this.items,
    required this.rawIds,
    this.boundary,
    this.cursor,
    required this.hasMore,
  });

  final List<Listing> items;
  final Set<String> rawIds;
  final DateTime? boundary;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
}

class ListingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('listings');

  Query<Map<String, dynamic>> _feedQuery(FeedQuery f) {
    Query<Map<String, dynamic>> q =
        _col.where('status', isEqualTo: statusAvailable);
    if (f.category != null) q = q.where('category', isEqualTo: f.category);
    if (f.wilaya != null) q = q.where('wilaya', isEqualTo: f.wilaya);
    if (f.commune != null) q = q.where('commune', isEqualTo: f.commune);
    final words = f.searchWords;
    if (words.isNotEmpty) q = q.where('keywords', arrayContainsAny: words);
    return q.orderBy('createdAt', descending: true);
  }

  List<Listing> _andFilter(List<Listing> items, List<String> words) {
    if (words.isEmpty) return items;
    return items
        .where((l) => words.every(l.keywords.contains))
        .toList();
  }

  DateTime? _createdAtOf(DocumentSnapshot<Map<String, dynamic>> doc) =>
      ((doc.data() ?? const <String, dynamic>{})['createdAt'] as Timestamp?)
          ?.toDate();

  /// Live head page (first [limit] matches) — re-emits on every server
  /// change so new posts appear without a manual refresh.
  Stream<FeedPage> feedHead(FeedQuery f, {int limit = 20}) {
    final words = f.searchWords;
    return _feedQuery(f).limit(limit).snapshots().map((snap) {
      final raw = snap.docs;
      return FeedPage(
        items: _andFilter(raw.map(Listing.fromDoc).toList(), words),
        rawIds: raw.map((d) => d.id).toSet(),
        boundary: raw.isNotEmpty ? _createdAtOf(raw.last) : null,
        cursor: raw.length >= limit ? raw.last : null,
        hasMore: raw.length >= limit,
      );
    });
  }

  /// One-shot next page after [cursor] (older posts) — no live updates on
  /// older pages; pull-to-refresh resets back to [feedHead].
  Future<FeedPage> feedMore(
    FeedQuery f,
    DocumentSnapshot<Map<String, dynamic>> cursor, {
    int limit = 20,
  }) async {
    final words = f.searchWords;
    final snap =
        await _feedQuery(f).startAfterDocument(cursor).limit(limit).get();
    final raw = snap.docs;
    return FeedPage(
      items: _andFilter(raw.map(Listing.fromDoc).toList(), words),
      rawIds: raw.map((d) => d.id).toSet(),
      boundary: raw.isNotEmpty ? _createdAtOf(raw.last) : null,
      cursor: raw.isNotEmpty ? raw.last : null,
      hasMore: raw.length >= limit,
    );
  }

  /// Live version of [myListings] (single-field filter, no extra index).
  Stream<List<Listing>> myStream(String uid) {
    return _col.where('ownerId', isEqualTo: uid).snapshots().map((snap) {
      final items = snap.docs.map(Listing.fromDoc).toList();
      items.sort((a, b) => (b.createdAt ?? DateTime(2000))
          .compareTo(a.createdAt ?? DateTime(2000)));
      return items;
    });
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
    // Create the listing and bump the lifetime post counter in one batch
    // (rules enforce stats/{uid}.postCount < 100 on every create).
    final batch = _db.batch();
    batch.set(doc, data);
    batch.set(
      _db.collection('stats').doc(draft.ownerId),
      {'postCount': FieldValue.increment(1)},
      SetOptions(merge: true),
    );
    await batch.commit();
    if (imagesB64.isNotEmpty) {
      final batch = _db.batch();
      for (var i = 0; i < imagesB64.length; i++) {
        batch.set(doc.collection('images').doc('$i'), {
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
      'keywords': buildKeywords(
        title: draft.title,
        description: draft.description,
        category: draft.category,
        wilaya: draft.wilaya,
        commune: draft.commune,
        condition: draft.condition,
      ),
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
        batch.set(doc.collection('images').doc('$i'), {
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

  /// Reserve an available listing (claim path in the security rules).
  /// Throws `FirebaseException(permission-denied)` when another user won
  /// the race — the caller probes [byId] to tell the difference between
  /// "taken" and a generic failure.
  Future<void> claim(String id, {required String uid, required String name}) {
    return _col.doc(id).update({
      'status': statusReserved,
      'claimedBy': uid,
      'claimedByName': name,
      'claimedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Owner or claimant releases the reservation back to the feed.
  Future<void> cancelClaim(String id) {
    return _col.doc(id).update({
      'status': statusAvailable,
      'claimedBy': null,
      'claimedByName': null,
      'claimedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Owner-only: a reserved listing becomes donated. The claim fields are
  /// kept so the community can see who received it.
  Future<void> confirmDelivery(String id) {
    return _col.doc(id).update({
      'status': statusGiven,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Live reservations made by [uid] (the "حجوزاتي" tab), newest claim first.
  Stream<List<Listing>> reservationsStream(String uid) {
    return _col.where('claimedBy', isEqualTo: uid).snapshots().map((snap) {
      final items = snap.docs.map(Listing.fromDoc).toList();
      items.sort((a, b) {
        final ta = a.claimedAt ?? a.createdAt ?? DateTime(2000);
        final tb = b.claimedAt ?? b.createdAt ?? DateTime(2000);
        return tb.compareTo(ta);
      });
      return items;
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
