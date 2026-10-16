import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase.dart';
import '../models/listing.dart';
import '../utils/constants.dart';
import '../utils/search_keywords.dart';
import 'paging.dart';

/// Server-side feed query: status is always filtered to available listings;
/// the optional facets and the search text become SQL equality / full-text
/// (trigram `ILIKE`) clauses so the database — not the client window — decides
/// which listings match.
class FeedQuery {
  const FeedQuery({
    this.search,
    this.category,
    this.wilaya,
    this.commune,
    this.kind,
  });

  final String? search;
  final String? category;
  final String? wilaya;
  final String? commune;
  final String? kind;

  /// Normalized query tokens (same normalization as the stored `search_text`).
  List<String> get searchWords {
    final s = search ?? '';
    if (s.trim().isEmpty) return const [];
    return searchTokens(s).take(kMaxQueryTokens).toList();
  }
}

/// One page of feed results.
///
/// [items] is the page; [rawIds] and [boundary] describe the raw server window
/// (the oldest item's `createdAt`) so the screen can merge live head events
/// without dropping or duplicating items.
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
  final Object? cursor;
  final bool hasMore;
}

class ListingService {
  SupabaseClient get _db => supabase;

  /// Builds the ordered, filtered feed query (untyped builder on purpose: the
  /// chain mixes generic builder types).
  dynamic _feedQuery(FeedQuery f) {
    dynamic q = _db.from('listings').select().eq('status', statusAvailable);
    if (f.category != null) q = q.eq('category', f.category!);
    if (f.wilaya != null) q = q.eq('wilaya', f.wilaya!);
    if (f.commune != null) q = q.eq('commune', f.commune!);
    if (f.kind != null) q = q.eq('kind', f.kind!);
    final words = f.searchWords;
    if (words.isNotEmpty) {
      q = q.ilikeAllOf('search_text', words.map((w) => '%$w%').toList());
    }
    return q.order('created_at', ascending: false);
  }

  List<Listing> _rows(Object? data) => (data as List)
      .map((e) => Listing.fromRow(Map<String, dynamic>.from(e as Map)))
      .toList();

  FeedPage _headPage(List<Listing> raw, int limit) => FeedPage(
        items: raw,
        rawIds: raw.map((l) => l.id).toSet(),
        boundary: raw.isNotEmpty ? raw.last.createdAt : null,
        cursor: raw.length,
        hasMore: raw.length >= limit,
      );

  /// Live head page (first [limit] matches) — emits immediately and refreshes
  /// on every listing change so new posts appear without a manual refresh.
  Stream<FeedPage> feedHead(FeedQuery f, {int limit = 20}) {
    return realtimeRefetch('listings', () async {
      final data = await _feedQuery(f).limit(limit);
      return _headPage(_rows(data), limit);
    });
  }

  /// One-shot next page after [cursor] (older posts).
  Future<FeedPage> feedMore(
    FeedQuery f,
    Object? cursor, {
    int limit = 20,
  }) async {
    final offset = (cursor as int?) ?? 0;
    final data = await _feedQuery(f).range(offset, offset + limit - 1);
    final raw = _rows(data);
    return FeedPage(
      items: raw,
      rawIds: raw.map((l) => l.id).toSet(),
      boundary: raw.isNotEmpty ? raw.last.createdAt : null,
      cursor: offset + raw.length,
      hasMore: raw.length >= limit,
    );
  }

  QueryPage<Listing> _page(List<Listing> raw, int offset, int limit) =>
      QueryPage(
        items: raw,
        cursor: offset + raw.length,
        hasMore: raw.length >= limit,
      );

  dynamic _ownerQuery(String uid) => _db
      .from('listings')
      .select()
      .eq('owner_id', uid)
      .order('created_at', ascending: false);

  /// Live first page of the user's own listings ("حجوزاتي" owner side).
  Stream<QueryPage<Listing>> myHead(String uid, {int limit = kPageSize}) {
    return realtimeRefetch('listings', () async {
      final data = await _ownerQuery(uid).range(0, limit - 1);
      return _page(_rows(data), 0, limit);
    });
  }

  /// One-shot older page of the user's own listings.
  Future<QueryPage<Listing>> myMore(
    String uid,
    Object? cursor, {
    int limit = kPageSize,
  }) async {
    final offset = (cursor as int?) ?? 0;
    final data = await _ownerQuery(uid).range(offset, offset + limit - 1);
    return _page(_rows(data), offset, limit);
  }

  dynamic _claimsQuery(String uid) => _db
      .from('listings')
      .select()
      .eq('claimed_by', uid)
      .order('created_at', ascending: false);

  /// Live first page of the listings the user has reserved.
  Stream<QueryPage<Listing>> reservationsHead(String uid,
      {int limit = kPageSize}) {
    return realtimeRefetch('listings', () async {
      final data = await _claimsQuery(uid).range(0, limit - 1);
      return _page(_rows(data), 0, limit);
    });
  }

  /// One-shot older page of the user's reservations.
  Future<QueryPage<Listing>> reservationsMore(
    String uid,
    Object? cursor, {
    int limit = kPageSize,
  }) async {
    final offset = (cursor as int?) ?? 0;
    final data = await _claimsQuery(uid).range(offset, offset + limit - 1);
    return _page(_rows(data), offset, limit);
  }

  Future<Listing?> byId(String id) async {
    final row =
        await _db.from('listings').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return Listing.fromRow(row);
  }

  Future<String> create({
    required Listing draft,
    required List<String> imagesB64,
  }) async {
    final row = await _db
        .from('listings')
        .insert(draft.toMap())
        .select('id')
        .single();
    final id = row['id'] as String;
    try {
      await _writeImages(id, imagesB64, draft.image0);
    } catch (_) {
      // Don't leave a listing without its images behind.
      try {
        await _db.from('listings').delete().eq('id', id);
      } catch (_) {}
      rethrow;
    }
    return id;
  }

  Future<void> update({
    required Listing draft,
    List<String>? newImagesB64,
    String? thumbB64,
  }) async {
    final data = <String, dynamic>{
      'owner_name': draft.ownerName,
      'title': draft.title,
      'description': draft.description,
      'category': draft.category,
      'wilaya': draft.wilaya,
      'commune': draft.commune,
      'condition': draft.condition,
      'status': draft.status,
      'kind': draft.kind,
      'contact_phone': draft.contactPhone,
    };
    if (newImagesB64 != null) {
      await _deleteImages(draft.id);
      await _writeImages(draft.id, newImagesB64, thumbB64);
    }
    await _db.from('listings').update(data).eq('id', draft.id);
  }

  Future<void> setStatus(String id, String status) async {
    await _db.from('listings').update({'status': status}).eq('id', id);
  }

  /// Reserve an available listing (claim path in the DB trigger). Throws when
  /// another user won the race — the caller probes [byId] to tell the
  /// difference between "taken" and a generic failure.
  Future<void> claim(String id, {required String uid, required String name}) {
    return _db.from('listings').update({
      'status': statusReserved,
      'claimed_by': uid,
      'claimed_by_name': name,
    }).eq('id', id);
  }

  /// Owner or claimant releases the reservation back to the feed.
  Future<void> cancelClaim(String id) {
    return _db.from('listings').update({
      'status': statusAvailable,
      'claimed_by': null,
      'claimed_by_name': null,
      'claimed_at': null,
    }).eq('id', id);
  }

  /// Owner-only: a reserved listing becomes donated. The claim fields are
  /// kept so the community can see who received it.
  Future<void> confirmDelivery(String id) {
    return _db
        .from('listings')
        .update({'status': statusGiven}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _deleteImages(id);
    await _db.from('listings').delete().eq('id', id);
  }

  Future<List<String>> imagesOf(String id) async {
    final rows = await _db
        .from('listing_images')
        .select('storage_path')
        .eq('listing_id', id)
        .order('idx');
    return (rows as List)
        .map((e) => storagePublicUrl((e as Map)['storage_path'] as String))
        .toList();
  }

  // ---- Storage helpers ---------------------------------------------------

  /// Uploads the 480px cover plus every gallery image, then records their
  /// metadata (`listings.cover_path` / `listing_images`).
  Future<void> _writeImages(
    String id,
    List<String> imagesB64,
    String? coverB64,
  ) async {
    if (imagesB64.isEmpty && (coverB64 == null || coverB64.isEmpty)) return;
    final bucket = _db.storage.from(kListingsBucket);

    String? coverPath;
    if (coverB64 != null && coverB64.isNotEmpty) {
      coverPath = '$id/cover.jpg';
      await bucket.uploadBinary(
        coverPath,
        _decode(coverB64),
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );
    }

    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < imagesB64.length; i++) {
      final path = '$id/$i.jpg';
      await bucket.uploadBinary(
        path,
        _decode(imagesB64[i]),
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );
      rows.add({'listing_id': id, 'idx': i, 'storage_path': path});
    }
    if (rows.isNotEmpty) {
      await _db.from('listing_images').upsert(rows);
    }

    await _db.from('listings').update({
      'cover_path': coverPath,
      'image_count': imagesB64.length,
    }).eq('id', id);
  }

  /// Removes a listing's gallery rows, cover row and storage objects.
  Future<void> _deleteImages(String id) async {
    final bucket = _db.storage.from(kListingsBucket);
    final imgs = await _db
        .from('listing_images')
        .select('storage_path')
        .eq('listing_id', id);
    final paths = (imgs as List)
        .map((e) => (e as Map)['storage_path'] as String)
        .toList();

    final row = await _db
        .from('listings')
        .select('cover_path')
        .eq('id', id)
        .maybeSingle();
    final cover = row?['cover_path'] as String?;
    if (cover != null && cover.isNotEmpty) paths.add(cover);

    if (paths.isNotEmpty) {
      try {
        await bucket.remove(paths);
      } catch (_) {}
    }
    await _db.from('listing_images').delete().eq('listing_id', id);
  }

  Uint8List _decode(String b64) => base64Decode(b64);
}
