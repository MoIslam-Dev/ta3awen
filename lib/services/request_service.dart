import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase.dart';
import '../models/request_post.dart';
import '../utils/constants.dart';
import 'paging.dart';

/// Board (requests) data access. Every read is paginated: a live head
/// (newest page) plus one-shot older pages, so the app never streams a whole
/// table.
class RequestService {
  SupabaseClient get _db => supabase;

  /// Open posts, newest first — optionally narrowed by [kind]
  /// (general/blood), [type] (need/offer) and/or [category].
  dynamic _boardQuery({String? type, String? kind, String? category}) {
    dynamic q = _db.from('requests').select().eq('status', requestStatusOpen);
    if (kind != null) q = q.eq('kind', kind);
    if (type != null) q = q.eq('type', type);
    if (category != null) q = q.eq('category', category);
    return q.order('created_at', ascending: false);
  }

  List<RequestPost> _rows(Object? data) => (data as List)
      .map((e) => RequestPost.fromRow(Map<String, dynamic>.from(e as Map)))
      .toList();

  QueryPage<RequestPost> _page(List<RequestPost> raw, int offset, int limit) =>
      QueryPage(
        items: raw,
        cursor: offset + raw.length,
        hasMore: raw.length >= limit,
      );

  /// Live first page of the open board.
  Stream<QueryPage<RequestPost>> boardHead({
    String? type,
    String? kind,
    String? category,
    int limit = kPageSize,
  }) {
    return realtimeRefetch('requests', () async {
      final data = await _boardQuery(type: type, kind: kind, category: category)
          .range(0, limit - 1);
      return _page(_rows(data), 0, limit);
    });
  }

  /// One-shot older page of the open board.
  Future<QueryPage<RequestPost>> boardMore({
    String? type,
    String? kind,
    String? category,
    required Object? cursor,
    int limit = kPageSize,
  }) async {
    final offset = (cursor as int?) ?? 0;
    final data = await _boardQuery(type: type, kind: kind, category: category)
        .range(offset, offset + limit - 1);
    return _page(_rows(data), offset, limit);
  }

  dynamic _myQuery(String uid) => _db
      .from('requests')
      .select()
      .eq('uid', uid)
      .order('created_at', ascending: false);

  /// Live first page of the current user's own posts (any status).
  Stream<QueryPage<RequestPost>> myHead(String uid, {int limit = kPageSize}) {
    return realtimeRefetch('requests', () async {
      final data = await _myQuery(uid).range(0, limit - 1);
      return _page(_rows(data), 0, limit);
    });
  }

  /// One-shot older page of the current user's own posts.
  Future<QueryPage<RequestPost>> myMore(
    String uid,
    Object? cursor, {
    int limit = kPageSize,
  }) async {
    final offset = (cursor as int?) ?? 0;
    final data = await _myQuery(uid).range(offset, offset + limit - 1);
    return _page(_rows(data), offset, limit);
  }

  Future<RequestPost?> byId(String id) async {
    final row =
        await _db.from('requests').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return RequestPost.fromRow(row);
  }

  Future<String> create(RequestPost post) async {
    final row = await _db
        .from('requests')
        .insert(post.toMap())
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> update(RequestPost draft) async {
    await _db.from('requests').update({
      'title': draft.title,
      'description': draft.description,
      'category': draft.category,
      'wilaya': draft.wilaya,
      'commune': draft.commune,
      'contact_phone': draft.contactPhone,
      'kind': draft.kind,
      'blood_type': draft.bloodType,
    }).eq('id', draft.id);
  }

  Future<void> setStatus(String id, String status) async {
    await _db.from('requests').update({'status': status}).eq('id', id);
  }

  /// Another user answers an open post ("I can help" / "I want this").
  Future<void> match(String id, {required String uid, required String name}) {
    return _db.from('requests').update({
      'status': requestStatusMatched,
      'matched_by': uid,
      'matched_name': name,
    }).eq('id', id);
  }

  /// Matcher withdraws (back to open) — same write the owner uses to release
  /// a match; the trigger allows both roles.
  Future<void> unmatch(String id) {
    return _db.from('requests').update({
      'status': requestStatusOpen,
      'matched_by': null,
      'matched_name': null,
      'matched_at': null,
    }).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _db.from('requests').delete().eq('id', id);
  }
}
