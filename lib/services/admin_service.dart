import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase.dart';
import '../models/app_user.dart';
import '../models/listing.dart';
import '../models/report.dart';
import '../models/request_post.dart';
import '../utils/constants.dart';
import 'paging.dart';

/// Admin data access. Every list is paginated; counts use Postgres `HEAD`
/// count queries (a single cheap round-trip) instead of loading whole tables.
class AdminService {
  SupabaseClient get _db => supabase;

  Future<bool> isAdmin(String uid) async {
    final row = await _db
        .from('admins')
        .select('user_id')
        .eq('user_id', uid)
        .maybeSingle();
    return row != null;
  }

  // ---- Aggregations (cheap counts) ---------------------------------------

  Future<int> _count(String table, [Map<String, Object?> filters = const {}]) async {
    dynamic q = _db.from(table).count();
    for (final e in filters.entries) {
      q = q.eq(e.key, e.value);
    }
    return (await q) as int;
  }

  Future<int> countUsers({bool? disabled}) => _count(
        'profiles',
        {...(disabled == null ? const {} : {'disabled': disabled})},
      );

  Future<int> countListings({String? status}) => _count(
        'listings',
        {...(status == null ? const {} : {'status': status})},
      );

  Future<int> countRequests({String? status, String? kind}) => _count(
        'requests',
        {
          ...(status == null ? const {} : {'status': status}),
          ...(kind == null ? const {} : {'kind': kind}),
        },
      );

  Future<int> countReports({String? status}) => _count(
        'reports',
        {...(status == null ? const {} : {'status': status})},
      );

  Future<int> countSeedListings() => _count('listings', {'is_demo': true});

  // ---- Paginated lists ---------------------------------------------------

  dynamic _listingsQuery(String? status) {
    dynamic q = _db.from('listings').select();
    if (status != null) q = q.eq('status', status);
    return q.order('created_at', ascending: false);
  }

  QueryPage<Listing> _listingPage(List<Listing> raw, int offset, int limit) =>
      QueryPage(
        items: raw,
        cursor: offset + raw.length,
        hasMore: raw.length >= limit,
      );

  List<Listing> _listingRows(Object? data) => (data as List)
      .map((e) => Listing.fromRow(Map<String, dynamic>.from(e as Map)))
      .toList();

  Stream<QueryPage<Listing>> listingsHead(
      {String? status, int limit = kPageSize}) {
    return realtimeRefetch('listings', () async {
      final data = await _listingsQuery(status).range(0, limit - 1);
      return _listingPage(_listingRows(data), 0, limit);
    });
  }

  Future<QueryPage<Listing>> listingsMore(String? status, Object? cursor,
      {int limit = kPageSize}) async {
    final offset = (cursor as int?) ?? 0;
    final data =
        await _listingsQuery(status).range(offset, offset + limit - 1);
    return _listingPage(_listingRows(data), offset, limit);
  }

  dynamic _requestsQuery(String? status) {
    dynamic q = _db.from('requests').select();
    if (status != null) q = q.eq('status', status);
    return q.order('created_at', ascending: false);
  }

  QueryPage<RequestPost> _requestPage(
          List<RequestPost> raw, int offset, int limit) =>
      QueryPage(
        items: raw,
        cursor: offset + raw.length,
        hasMore: raw.length >= limit,
      );

  List<RequestPost> _requestRows(Object? data) => (data as List)
      .map((e) => RequestPost.fromRow(Map<String, dynamic>.from(e as Map)))
      .toList();

  Stream<QueryPage<RequestPost>> requestsHead(
      {String? status, int limit = kPageSize}) {
    return realtimeRefetch('requests', () async {
      final data = await _requestsQuery(status).range(0, limit - 1);
      return _requestPage(_requestRows(data), 0, limit);
    });
  }

  Future<QueryPage<RequestPost>> requestsMore(String? status, Object? cursor,
      {int limit = kPageSize}) async {
    final offset = (cursor as int?) ?? 0;
    final data =
        await _requestsQuery(status).range(offset, offset + limit - 1);
    return _requestPage(_requestRows(data), offset, limit);
  }

  dynamic _usersQuery(String? search) {
    dynamic q = _db.from('profiles').select();
    final s = search?.trim() ?? '';
    if (s.isNotEmpty) {
      return q.ilike('full_name', '%$s%').order('full_name');
    }
    return q.order('created_at', ascending: false);
  }

  QueryPage<AppUser> _userPage(List<AppUser> raw, int offset, int limit) =>
      QueryPage(
        items: raw,
        cursor: offset + raw.length,
        hasMore: raw.length >= limit,
      );

  List<AppUser> _userRows(Object? data) => (data as List)
      .map((e) => AppUser.fromRow(Map<String, dynamic>.from(e as Map)))
      .toList();

  Stream<QueryPage<AppUser>> usersHead({String? search, int limit = kPageSize}) {
    return realtimeRefetch('profiles', () async {
      final data = await _usersQuery(search).range(0, limit - 1);
      return _userPage(_userRows(data), 0, limit);
    });
  }

  Future<QueryPage<AppUser>> usersMore(String? search, Object? cursor,
      {int limit = kPageSize}) async {
    final offset = (cursor as int?) ?? 0;
    final data = await _usersQuery(search).range(offset, offset + limit - 1);
    return _userPage(_userRows(data), offset, limit);
  }

  dynamic get _reportsQuery =>
      _db.from('reports').select().order('created_at', ascending: false);

  QueryPage<Report> _reportPage(List<Report> raw, int offset, int limit) =>
      QueryPage(
        items: raw,
        cursor: offset + raw.length,
        hasMore: raw.length >= limit,
      );

  List<Report> _reportRows(Object? data) => (data as List)
      .map((e) => Report.fromRow(Map<String, dynamic>.from(e as Map)))
      .toList();

  Stream<QueryPage<Report>> reportsHead({int limit = kPageSize}) {
    return realtimeRefetch('reports', () async {
      final data = await _reportsQuery.range(0, limit - 1);
      return _reportPage(_reportRows(data), 0, limit);
    });
  }

  Future<QueryPage<Report>> reportsMore(Object? cursor,
      {int limit = kPageSize}) async {
    final offset = (cursor as int?) ?? 0;
    final data = await _reportsQuery.range(offset, offset + limit - 1);
    return _reportPage(_reportRows(data), offset, limit);
  }

  // ---- Content moderation ------------------------------------------------

  Future<void> deleteListing(String id) async {
    await _removeListingStorage(id);
    await _db.from('listings').delete().eq('id', id);
  }

  /// Doc-IDs of demo listings created by the seed script.
  Future<List<String>> seedListingIds({int limit = 500}) async {
    final rows = await _db
        .from('listings')
        .select('id')
        .eq('is_demo', true)
        .limit(limit);
    return (rows as List).map((e) => (e as Map)['id'] as String).toList();
  }

  /// Bulk delete (incl. storage + image rows), chunked. Returns the number of
  /// listings removed.
  Future<int> deleteListings(List<String> ids) async {
    var deleted = 0;
    for (var i = 0; i < ids.length; i += 40) {
      final chunk =
          ids.sublist(i, i + 40 > ids.length ? ids.length : i + 40);
      for (final id in chunk) {
        await _removeListingStorage(id);
      }
      await _db.from('listings').delete().inFilter('id', chunk);
      deleted += chunk.length;
    }
    return deleted;
  }

  Future<void> deleteRequest(String id) async {
    await _db.from('requests').delete().eq('id', id);
  }

  Future<int> deleteRequests(List<String> ids) async {
    var deleted = 0;
    for (var i = 0; i < ids.length; i += 400) {
      final chunk =
          ids.sublist(i, i + 400 > ids.length ? ids.length : i + 400);
      await _db.from('requests').delete().inFilter('id', chunk);
      deleted += chunk.length;
    }
    return deleted;
  }

  Future<void> deleteReport(String id) async {
    await _db.from('reports').delete().eq('id', id);
  }

  Future<void> setReportStatus(String id, String status) async {
    await _db.rpc('resolve_report', params: {
      'target': id,
      'new_status': status,
    });
  }

  /// Mark the report resolved and remove the reported listing.
  Future<void> resolveReportWithContent(Report r) async {
    await _db.rpc('resolve_report', params: {
      'target': r.id,
      'new_status': 'resolved',
    });
    if (r.listingId.isNotEmpty) {
      await deleteListing(r.listingId);
    }
  }

  // ---- User administration ----------------------------------------------

  Future<void> setUserDisabled(String uid, bool disabled,
      {String? reason}) async {
    await _db.rpc('set_user_disabled', params: {
      'target': uid,
      'value': disabled,
      'reason': disabled ? reason : null,
    });
  }

  /// Grant or revoke admin rights.
  Future<void> setAdmin(String uid, bool value) async {
    await _db.rpc('set_admin', params: {
      'target': uid,
      'value': value,
    });
  }

  /// Count of listings owned by [uid].
  Future<int> countUserListings(String uid) =>
      _count('listings', {'owner_id': uid});

  /// Count of requests authored by [uid].
  Future<int> countUserRequests(String uid) =>
      _count('requests', {'uid': uid});

  /// Permanently deletes everything [uid] owns: listings (+ stored images),
  /// board posts, reports, admin rights and the profile. The auth account
  /// itself is a separate administrative step (Admin API / service role).
  Future<void> deleteUserData(String uid) async {
    final rows = await _db.from('listings').select('id').eq('owner_id', uid);
    final ids =
        (rows as List).map((e) => (e as Map)['id'] as String).toList();
    for (final id in ids) {
      await _removeListingStorage(id);
    }
    await _db.rpc('delete_user_data', params: {'target': uid});
  }

  /// Removes the cover + gallery storage objects of a listing (rows cascade).
  Future<void> _removeListingStorage(String id) async {
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
        await _db.storage.from(kListingsBucket).remove(paths);
      } catch (_) {}
    }
  }
}
