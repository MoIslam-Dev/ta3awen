import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/navigator.dart';
import '../core/supabase.dart';
import '../screens/listing/listing_details_screen.dart';
import '../screens/requests/request_details_screen.dart';
import '../state/app_settings.dart';

/// Bridges Firebase Cloud Messaging to the app:
/// * registers this device's FCM token against the signed-in user (server-side
///   push fan-out lives in the `notifications_push_trg` DB trigger + Edge
///   Function);
/// * shows a heads-up notification while the app is in the foreground (Android
///   does not auto-display those);
/// * routes a tap — foreground, background or terminated — to the referenced
///   listing/post.
///
/// Background and terminated delivery is handled by the OS from the message's
/// `notification` payload, so no background isolate is needed.
class PushService {
  PushService._();

  static final PushService instance = PushService._();

  static const String _channelId = 'ta3awen_default';
  static const String _channelName = 'Ta3awen';
  static const String _channelDescription = 'Ta3awen notifications';

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  // Lazily resolved: `FirebaseMessaging.instance` throws until
  // `Firebase.initializeApp()` has run, so this must NOT be a field initializer.
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  StreamSubscription<AuthState>? _authSub;
  bool _initialized = false;
  String? _token;
  int _notifId = 0;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await Firebase.initializeApp();
      await _initLocalNotifications();
      _listenMessaging();
      _authSub = supabase.auth.onAuthStateChange.listen((state) {
        if (state.session != null) {
          _syncToken();
        } else {
          _removeToken();
        }
      });
      AppSettings.instance.locale.addListener(_syncToken);
      await _requestPermission();
      await _fetchToken();
      await _syncToken();
    } catch (e, st) {
      debugPrint('PushService.init failed: $e\n$st');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );
    await _local.initialize(
      settings,
      onDidReceiveNotificationResponse: _onLocalTap,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );
  }

  void _listenMessaging() {
    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _openFromData(m.data));
    // App launched from a terminated state by tapping a notification.
    _messaging.getInitialMessage().then((message) {
      if (message == null) return;
      Future<void>.delayed(
        const Duration(milliseconds: 350),
        () => _openFromData(message.data),
      );
    });
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission();
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _fetchToken() async {
    // ignore: deprecated_member_use
    _token = await _messaging.getToken();
    // ignore: deprecated_member_use
    _messaging.onTokenRefresh.listen((token) {
      _token = token;
      _syncToken();
    });
  }

  Future<void> _syncToken() async {
    final token = _token;
    final user = supabase.auth.currentUser;
    if (token == null || user == null) return;
    final code = AppSettings.instance.locale.value.languageCode;
    try {
      await supabase.rpc(
        'register_device_token',
        params: {'p_token': token, 'p_platform': 'android', 'p_locale': code},
      );
    } catch (e) {
      debugPrint('register_device_token failed: $e');
    }
  }

  Future<void> _removeToken() async {
    final token = _token;
    if (token == null) return;
    try {
      await supabase.rpc(
        'unregister_device_token',
        params: {'p_token': token},
      );
    } catch (e) {
      debugPrint('unregister_device_token failed: $e');
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? '';
    final body = notification?.body ?? '';
    if (title.isEmpty && body.isEmpty) return;
    await _local.show(
      _notifId++,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _onLocalTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      _openFromData(Map<String, dynamic>.from(jsonDecode(payload) as Map));
    } catch (_) {
      // Malformed payload: nothing to route to.
    }
  }

  void _openFromData(Map<String, dynamic> data) {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    final listingId = data['listing_id'];
    final requestId = data['request_id'];
    if (listingId is String && listingId.isNotEmpty) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ListingDetailsScreen(listingId: listingId),
        ),
      );
    } else if (requestId is String && requestId.isNotEmpty) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => RequestDetailsScreen(requestId: requestId),
        ),
      );
    }
  }

  void dispose() {
    _authSub?.cancel();
    AppSettings.instance.locale.removeListener(_syncToken);
  }
}
