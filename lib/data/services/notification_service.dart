import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int _dailyMotivationBaseId = 1000;
  static const int _dailyMotivationScheduleDays = 14;
  static const MethodChannel _timeZoneChannel = MethodChannel(
    'snapcal/timezone',
  );

  bool _timeZoneInitialized = false;

  Future<void> init() async {
    await _ensureTimeZoneInitialized();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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
        // Handle notification tap
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

    if (firstDate.isBefore(now)) {
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
          icon: '@mipmap/ic_launcher',
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
}

class MotivationNotificationCopy {
  final String title;
  final String body;

  const MotivationNotificationCopy({required this.title, required this.body});
}
