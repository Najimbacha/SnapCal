import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static NotificationService? customInstance;
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => customInstance ?? _instance;
  NotificationService._internal();

  /// Callback invoked when a food reminder notification is tapped.
  static VoidCallback? onFoodReminderTapped;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int _dailyMotivationBaseId = 1000;
  static const int _dailyMotivationScheduleDays = 14;
  static const String _androidNotificationIcon = 'ic_stat_notification';
  static const String _foodReminderPayload = 'food_reminder';
  static const String foodReminderChannelId = 'food_scan_reminders_v1';
  static const String foodReminderChannelName = 'Food Scan Reminders';
  static const String foodReminderChannelDesc = 'Gentle reminders to scan your meals.';
  static const MethodChannel _timeZoneChannel = MethodChannel(
    'snapcal/timezone',
  );

  bool _timeZoneInitialized = false;
  Future<void>? _timeZoneInitFuture;
  Future<void>? _initFuture;

  Future<void> init() async {
    _initFuture ??= _initSafely();
    return _initFuture!;
  }

  Future<void> _initSafely() async {
    try {
      await _ensureTimeZoneInitialized();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings(_androidNotificationIcon);

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings settings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notificationsPlugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (details) {
          if (details.payload == _foodReminderPayload) {
            onFoodReminderTapped?.call();
          }
        },
      );

      // Request permissions for Android 13+
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      }
    } catch (e, stack) {
      debugPrint('⚠️ NotificationService: init failed: $e');
      debugPrint(stack.toString());
    }
  }

  /// Schedule a daily reminder at a specific time
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
    required int hour,
    required int minute,
  }) async {
    await _ensureTimeZoneInitialized();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Use inexact scheduling for better battery efficiency and Google Play compliance
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'meal_reminders_v2',
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: _androidNotificationIcon,
          color: const Color(0xFF10B981),
          ledColor: const Color(0xFF10B981),
          ledOnMs: 1000,
          ledOffMs: 500,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule a rolling set of daily motivation notifications.
  ///
  /// Local notifications repeat with fixed content, so this schedules several
  /// one-shot notifications to keep the copy varied without server push.
  Future<void> scheduleDailyMotivation({
    required List<MotivationNotificationCopy> messages,
    required String channelName,
    required String channelDescription,
    required int hour,
    required int minute,
    bool skipToday = false,
  }) async {
    if (messages.isEmpty) return;

    await _ensureTimeZoneInitialized();
    await cancelDailyMotivation();

    final now = tz.TZDateTime.now(tz.local);
    var firstDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (skipToday || firstDate.isBefore(now)) {
      firstDate = firstDate.add(const Duration(days: 1));
    }

    int? previousIndex;
    for (var offset = 0; offset < _dailyMotivationScheduleDays; offset++) {
      final scheduledDate = firstDate.add(Duration(days: offset));
      final index = _randomMessageIndex(
        scheduledDate,
        messages.length,
        previousIndex,
      );
      previousIndex = index;
      final message = messages[index];

      await _notificationsPlugin.zonedSchedule(
        id: _dailyMotivationBaseId + offset,
        title: message.title,
        body: message.body,
        scheduledDate: scheduledDate,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_motivation_v1',
            channelName,
            channelDescription: channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: _androidNotificationIcon,
            color: Color(0xFF10B981),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  int _randomMessageIndex(
    tz.TZDateTime scheduledDate,
    int messageCount,
    int? previousIndex,
  ) {
    final daySeed =
        DateTime(
          scheduledDate.year,
          scheduledDate.month,
          scheduledDate.day,
        ).millisecondsSinceEpoch;
    var index = math.Random(daySeed).nextInt(messageCount);

    if (messageCount > 1 && index == previousIndex) {
      index = (index + 1) % messageCount;
    }

    return index;
  }

  Future<void> _ensureTimeZoneInitialized() async {
    if (_timeZoneInitialized) return;
    _timeZoneInitFuture ??= _initializeTimeZone();
    await _timeZoneInitFuture;
  }

  Future<void> _initializeTimeZone() async {
    if (_timeZoneInitialized) return;
    tz_data.initializeTimeZones();
    final timeZoneName = await _getLocalTimeZoneName();
    final location = _resolveLocation(timeZoneName);
    tz.setLocalLocation(location);
    _timeZoneInitialized = true;
  }

  Future<String?> _getLocalTimeZoneName() async {
    try {
      return await _timeZoneChannel.invokeMethod<String>('getLocalTimeZone');
    } on MissingPluginException catch (_) {
      return null;
    } on PlatformException catch (e) {
      debugPrint('⚠️ NotificationService: Unable to read local timezone: $e');
      return null;
    }
  }

  tz.Location _resolveLocation(String? timeZoneName) {
    if (timeZoneName != null &&
        tz.timeZoneDatabase.locations.containsKey(timeZoneName)) {
      return tz.getLocation(timeZoneName);
    }

    debugPrint(
      '⚠️ NotificationService: Falling back to UTC timezone for notifications',
    );
    return tz.getLocation('UTC');
  }

  /// Show an instant notification for goal completion
  Future<void> showGoalAlert({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    await _notificationsPlugin.show(
      id: 999, // Goal alert ID
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'goal_alerts_v2',
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: _androidNotificationIcon,
          color: const Color(0xFF10B981),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Show a food scan reminder notification (for foreground display)
  Future<void> showFoodReminderNotification({
    required String title,
    required String body,
  }) async {
    try {
      await _notificationsPlugin.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            foodReminderChannelId,
            foodReminderChannelName,
            channelDescription: foodReminderChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: _androidNotificationIcon,
            color: const Color(0xFF10B981),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: _foodReminderPayload,
      );
    } catch (e) {
      debugPrint('⚠️ NotificationService: food reminder display failed: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Cancel scheduled daily motivation notifications.
  Future<void> cancelDailyMotivation() async {
    for (var offset = 0; offset < _dailyMotivationScheduleDays; offset++) {
      await _notificationsPlugin.cancel(id: _dailyMotivationBaseId + offset);
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  @visibleForTesting
  Future<void> ensureTimeZoneInitializedForTesting() {
    return _ensureTimeZoneInitialized();
  }

  @visibleForTesting
  void resetForTesting() {
    _timeZoneInitialized = false;
    _timeZoneInitFuture = null;
    _initFuture = null;
  }
}

class MotivationNotificationCopy {
  final String title;
  final String body;

  const MotivationNotificationCopy({required this.title, required this.body});
}
