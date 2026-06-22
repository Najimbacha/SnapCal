import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

/// Top-level background message handler (required by firebase_messaging).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final service = FcmService();
  await service._handleBackgroundMessage(message);
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  static const String _tokenKey = 'fcm_token';
  static const String _topicAllUsers = 'snapcal_all_users';
  static const String _topicFoodReminders = 'food_scan_reminders';
  static const String _channelId = 'fcm_notifications_v1';
  static const String _channelName = 'SnapCal Updates';
  static const String _channelDesc = 'Push notifications from SnapCal';

  /// Callback invoked when a food reminder notification is tapped.
  VoidCallback? onFoodReminderTapped;

  SharedPreferences? _prefs;
  FirebaseMessaging? _messaging;
  bool _initialized = false;
  bool _topicSubscribed = false;

  /// For the debug screen — last received RemoteMessage data.
  RemoteMessage? _lastMessage;
  RemoteMessage? get lastMessage => _lastMessage;

  /// The current FCM token, cached in-memory after init.
  String? _cachedToken;
  String? get cachedToken => _cachedToken;

  /// Whether notification permission has been granted.
  bool _permissionGranted = false;
  bool get permissionGranted => _permissionGranted;

  /// Whether the user is subscribed to snapcal_all_users.
  bool get isSubscribed => _topicSubscribed;

  // ── Initialization ─────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      _messaging = FirebaseMessaging.instance;

      // 1. Create the FCM notification channel on Android.
      await _createNotificationChannel();

      // 2. Request notification permission.
      await _requestPermission();

      // 3. Get the current FCM token & store it.
      await _fetchAndStoreToken();

      // 4. Listen for token refreshes.
      _messaging!.onTokenRefresh.listen(_onTokenRefresh);

      // 5. Subscribe to the global all-users topic.
      await _subscribeToAllUsers();

      // 6. Configure foreground message handler.
      if (_permissionGranted) {
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      }

      // 7. Listen for notification taps that open the app from background.
      FirebaseMessaging.onMessageOpenedApp.listen(handleNotificationOpenedApp);

      // 8. Configure background message handler (top-level).
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 9. Check if the app was opened from a terminated-state notification.
      await _checkInitialMessage();

      _initialized = true;
      _logState();
      debugPrint('✅ FcmService: initialized successfully');
    } catch (e, stack) {
      debugPrint('❌ FcmService.init() failed: $e');
      debugPrint(stack.toString());
    }
  }

  // ── Android notification channel ──────────────────────────────────────────

  Future<void> _createNotificationChannel() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );
        debugPrint('📢 FcmService: notification channel "$_channelId" created');
      }
    } catch (e) {
      debugPrint('⚠️ FcmService: channel creation failed: $e');
    }
  }

  // ── Permission request ────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    if (_messaging == null) return;
    try {
      final settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      _permissionGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      debugPrint(
        '🔔 FcmService: permission status = ${settings.authorizationStatus.name} '
        '(granted=$_permissionGranted)',
      );
    } catch (e) {
      debugPrint('⚠️ FcmService: permission request failed: $e');
    }
  }

  // ── Token management ──────────────────────────────────────────────────────

  Future<void> _fetchAndStoreToken() async {
    if (_messaging == null) return;
    try {
      final token = await _messaging!.getToken();
      if (token != null) {
        _cachedToken = token;
        await _prefs?.setString(_tokenKey, token);
        debugPrint('🔑 FcmService: token obtained (len=${token.length})');
        debugPrint('🔑 FcmService: token preview=${token.substring(0, 20)}...');
      } else {
        debugPrint('⚠️ FcmService: getToken() returned null');
      }
    } catch (e) {
      debugPrint('⚠️ FcmService: getToken() failed: $e');
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    debugPrint('🔄 FcmService: token refreshed (len=${token.length})');
    _cachedToken = token;
    await _prefs?.setString(_tokenKey, token);
    _logState();
  }

  /// Manually refresh the token (useful for the debug screen).
  Future<void> refreshToken() async {
    await _fetchAndStoreToken();
  }

  // ── Topic subscription ────────────────────────────────────────────────────

  Future<void> _subscribeToAllUsers() async {
    if (_messaging == null) return;
    try {
      await _messaging!.subscribeToTopic(_topicAllUsers);
      _topicSubscribed = true;
      debugPrint('📬 FcmService: subscribed to "$_topicAllUsers"');
    } catch (e) {
      debugPrint('⚠️ FcmService: subscribeToTopic failed: $e');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    if (_messaging == null) return;
    try {
      await _messaging!.subscribeToTopic(topic);
      debugPrint('📬 FcmService: subscribed to "$topic"');
    } catch (e) {
      debugPrint('⚠️ FcmService: subscribeToTopic("$topic") failed: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (_messaging == null) return;
    try {
      await _messaging!.unsubscribeFromTopic(topic);
      if (topic == _topicAllUsers) _topicSubscribed = false;
      debugPrint('📭 FcmService: unsubscribed from "$topic"');
    } catch (e) {
      debugPrint('⚠️ FcmService: unsubscribeFromTopic("$topic") failed: $e');
    }
  }

  Future<void> unsubscribeAllUsers() async {
    await unsubscribeFromTopic(_topicAllUsers);
  }

  Future<void> subscribeToFoodReminders() async {
    await subscribeToTopic(_topicFoodReminders);
  }

  Future<void> unsubscribeFromFoodReminders() async {
    await unsubscribeFromTopic(_topicFoodReminders);
  }

  bool _isFoodReminder(RemoteMessage message) {
    return message.data['type'] == 'food_reminder';
  }

  // ── Message handling ──────────────────────────────────────────────────────

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _lastMessage = message;
    debugPrint('📩 FcmService: foreground message received');
    _logMessage(message);

    if (_isFoodReminder(message)) {
      final title = message.data['title'] ?? message.notification?.title ?? 'Time to scan your food';
      final body = message.data['body'] ?? message.notification?.body ?? '';
      await NotificationService().showFoodReminderNotification(title: title, body: body);
    } else {
      await _showLocalNotification(message);
    }
  }

  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    _lastMessage = message;
    debugPrint('📩 FcmService: background message received');
    _logMessage(message);
  }

  Future<void> _checkInitialMessage() async {
    if (_messaging == null) return;
    try {
      final message = await _messaging!.getInitialMessage();
      if (message != null) {
        _lastMessage = message;
        debugPrint('📩 FcmService: app opened from terminated notification');
        _logMessage(message);
        if (_isFoodReminder(message)) {
          onFoodReminderTapped?.call();
        }
      }
    } catch (e) {
      debugPrint('⚠️ FcmService: getInitialMessage() failed: $e');
    }
  }

  /// Call when a notification opens the app from background.
  Future<void> handleNotificationOpenedApp(RemoteMessage message) async {
    _lastMessage = message;
    debugPrint('📩 FcmService: notification opened app');
    _logMessage(message);
    if (_isFoodReminder(message)) {
      onFoodReminderTapped?.call();
    }
  }

  /// Show a local notification when the app is in the foreground
  /// (since FCM doesn't display notifications automatically in that state).
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;
    final title = notification?.title ?? data['title'] ?? 'SnapCal';
    final body = notification?.body ?? data['body'] ?? '';

    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_stat_notification',
            color: const Color(0xFF10B981),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ FcmService: local notification display failed: $e');
    }
  }

  // ── Debug logging ─────────────────────────────────────────────────────────

  void _logMessage(RemoteMessage message) {
    final n = message.notification;
    debugPrint('  ┌─ RemoteMessage ─────────────────────');
    debugPrint('  │ messageId : ${message.messageId}');
    debugPrint('  │ title     : ${n?.title}');
    debugPrint('  │ body      : ${n?.body}');
    debugPrint('  │ data      : ${jsonEncode(message.data)}');
    debugPrint('  │ sentTime  : ${message.sentTime}');
    debugPrint('  └─────────────────────────────────────');
  }

  void _logState() {
    debugPrint('═══════════ FcmService State ═══════════');
    debugPrint('  Initialized      : $_initialized');
    debugPrint('  Permission       : $_permissionGranted');
    debugPrint('  Token exists     : ${_cachedToken != null}');
    debugPrint('  Token length     : ${_cachedToken?.length ?? 0}');
    debugPrint('  Topic subscribed : $_topicSubscribed');
    debugPrint('  Last message     : ${_lastMessage?.messageId ?? 'none'}');
    debugPrint('══════════════════════════════════════════');
  }
}
