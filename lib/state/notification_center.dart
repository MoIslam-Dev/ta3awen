import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../services/notification_service.dart';

/// Holds the current user's notifications with a live head, plus an optimistic
/// "read" set so the badge updates instantly when a row is tapped (before the
/// Realtime echo lands).
///
/// One instance lives in [HomeShell]; the bell badge and the notifications
/// screen share it.
class NotificationCenter extends ChangeNotifier {
  NotificationCenter({NotificationService? service})
      : _service = service ?? NotificationService();

  final NotificationService _service;
  StreamSubscription<List<AppNotification>>? _sub;
  List<AppNotification> _items = const [];
  final Set<String> _pendingRead = {};
  bool _loading = true;
  Object? _error;

  List<AppNotification> get items => _items;
  bool get loading => _loading;
  Object? get error => _error;

  bool isUnread(AppNotification n) =>
      n.isUnread && !_pendingRead.contains(n.id);

  int get unreadCount => _items.where(isUnread).length;

  /// (Re)subscribes to the live head. Call on init and on retry.
  void start() {
    _sub?.cancel();
    _loading = true;
    _error = null;
    _sub = _service.watchRecent().listen(
      (items) {
        // Drop optimistic marks now confirmed by the server.
        _pendingRead.removeWhere(
          (id) => items.any((n) => n.id == id && !n.isUnread),
        );
        _items = items;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e;
        _loading = false;
        notifyListeners();
      },
    );
    notifyListeners();
  }

  Future<void> markRead(AppNotification n) async {
    if (!isUnread(n)) return;
    _pendingRead.add(n.id);
    notifyListeners();
    try {
      await _service.markRead(n.id, DateTime.now());
    } catch (_) {
      _pendingRead.remove(n.id);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markAllRead() async {
    final ids = _items.where(isUnread).map((n) => n.id).toList();
    if (ids.isEmpty) return;
    _pendingRead.addAll(ids);
    notifyListeners();
    try {
      await _service.markAllRead(DateTime.now());
    } catch (_) {
      _pendingRead.removeAll(ids);
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
