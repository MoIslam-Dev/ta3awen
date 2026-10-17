import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase.dart';
import '../models/app_notification.dart';

/// Notification inbox data access. Reads stream the newest rows live via
/// Realtime; clients can only flip `read_at` (the DB grants nothing else), so
/// the only writes here are mark-as-read and delete.
class NotificationService {
  SupabaseClient get _db => supabase;

  /// Live list of the current user's newest notifications. RLS scopes the
  /// query to the recipient, so no explicit `user_id` filter is needed.
  Stream<List<AppNotification>> watchRecent({int limit = 50}) {
    return realtimeRefetch('notifications', () async {
      final data = await _db
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return (data as List)
          .map((e) =>
              AppNotification.fromRow(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }

  Future<void> markRead(String id, DateTime at) async {
    await _db
        .from('notifications')
        .update({'read_at': at.toUtc().toIso8601String()}).eq('id', id);
  }

  /// Marks every unread row of the current user as read (RLS scopes the write).
  Future<void> markAllRead(DateTime at) async {
    await _db
        .from('notifications')
        .update({'read_at': at.toUtc().toIso8601String()})
        .isFilter('read_at', null);
  }

  Future<void> delete(String id) async {
    await _db.from('notifications').delete().eq('id', id);
  }
}
