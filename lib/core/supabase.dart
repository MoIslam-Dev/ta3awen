import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase project configuration (public — safe to ship in the client).
const String kSupabaseUrl = 'https://qljsfelmqgfritayostb.supabase.co';
const String kSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsanNmZWxtcWdmcml0YXlvc3RiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIxMDExMzUsImV4cCI6MjEwNzY3NzEzNX0.LET-ne8shJOomD7v0D-RSQhimT1jNAExwD8cwWewap4';

/// Google OAuth *web* client id, passed as `serverClientId` so the id token
/// audience is the one Supabase verifies.
const String kGoogleServerClientId =
    '72351529323-ugvingt5n6u11k8jb29jf3o945rsk7f3.apps.googleusercontent.com';

/// Public Storage bucket holding listing photos.
const String kListingsBucket = 'listings';

Future<void> initSupabase() async {
  await Supabase.initialize(url: kSupabaseUrl, publishableKey: kSupabaseAnonKey);
}

SupabaseClient get supabase => Supabase.instance.client;

/// Public URL of a Storage object in the listings bucket. Pure string work —
/// no client needed, so models can resolve cover paths transparently.
String storagePublicUrl(String path) =>
    '$kSupabaseUrl/storage/v1/object/public/$kListingsBucket/$path';

int _channelSeq = 0;

/// Live "head" helper: emits [fetch] immediately, then re-runs it whenever any
/// row in [table] changes (Supabase Realtime). This keeps a refreshing first
/// page without the single-filter limitation of `from(table).stream()`.
Stream<T> realtimeRefetch<T>(String table, Future<T> Function() fetch) {
  final controller = StreamController<T>();
  RealtimeChannel? channel;
  var closed = false;

  Future<void> emit() async {
    try {
      final value = await fetch();
      if (!closed) controller.add(value);
    } catch (e, st) {
      if (!closed) controller.addError(e, st);
    }
  }

  controller.onListen = () async {
    await emit();
    channel = supabase.channel('rt-$table-${_channelSeq++}');
    channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: (_) => emit(),
        )
        .subscribe();
  };
  controller.onCancel = () async {
    closed = true;
    await channel?.unsubscribe();
    await controller.close();
  };
  return controller.stream;
}
