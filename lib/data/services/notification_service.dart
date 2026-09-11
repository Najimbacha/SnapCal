import 'force_update_service.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

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

  /// Payload of a "please update" notification shown while the app is open.
  static const String appUpdatePayload = 'app_update';
  static const String foodReminderChannelId = 'food_scan_reminders_v1';
  static const MethodChannel _timeZoneChannel = MethodChannel(
    'snapcal/timezone',
  );

  bool _timeZoneInitialized = false;
  Future<void>? _timeZoneInitFuture;
  Future<void>? _initFuture;

  /// Strings in the phone's own language. Channel names are shown in the
  /// phone's notification settings, which are in that language; they were
  /// English for everyone.
  static AppLocalizations deviceLocalizations() {
    final code = ui.PlatformDispatcher.instance.locale.languageCode;
    final supported = AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == code,
    );
    return lookupAppLocalizations(ui.Locale(supported ? code : 'en'));
  }

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
            // Asked for after onboarding, with a reason, instead.
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
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
          } else if (details.payload == appUpdatePayload) {
            ForceUpdateService().openStore();
          }
        },
      );

      // No permission request here. It fired the moment the app first
      // opened, before the user knew what SnapCal was; many said no, and
      // Android stops asking after that. NotificationPermissionPrompt asks
      // once, after onboarding, and says why.
      //
      // The food reminder channel is created up front, named in the phone's
      // language, so a reminder pushed while the app is closed lands in it
      // rather than in the default channel.
      final l10n = deviceLocalizations();
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            AndroidNotificationChannel(
              foodReminderChannelId,
              l10n.notif_food_reminders_channel,
              description: l10n.notif_food_reminders_channel_description,
              importance: Importance.high,
            ),
          );
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
    bool startTomorrow = false,
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

    // A meal already logged today skips today's reminder for it.
    if (scheduledDate.isBefore(now) || startTomorrow) {
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
          color: AppColors.primary,
          ledColor: AppColors.primary,
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
            color: AppColors.primary,
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
    final location = resolveLocation(timeZoneName);
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

  /// The zone reminders are scheduled in.
  ///
  /// The platform's zone name when there is one. Without it -- iOS had no
  /// handler for the channel at all -- this fell straight back to UTC, so an
  /// 8:00 breakfast reminder arrived at 8:00 UTC. Now it picks a zone whose
  /// current offset matches the phone's clock, which also covers half-hour
  /// offsets such as India's; UTC is left for when nothing matches.
  @visibleForTesting
  static tz.Location resolveLocation(
    String? timeZoneName, {
    Duration? utcOffset,
  }) {
    if (timeZoneName != null &&
        tz.timeZoneDatabase.locations.containsKey(timeZoneName)) {
      return tz.getLocation(timeZoneName);
    }

    final offset = utcOffset ?? DateTime.now().timeZoneOffset;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    for (final location in tz.timeZoneDatabase.locations.values) {
      if (location.timeZone(nowMs).offset == offset) return location;
    }

    debugPrint(
      '⚠️ NotificationService: Falling back to UTC timezone for notifications',
    );
    // tz.UTC, not getLocation('UTC'): the bundled database has no location
    // by that name, so the old fallback threw instead of falling back.
    return tz.UTC;
  }

  /// Show a food scan reminder notification (for foreground display)
  Future<void> showFoodReminderNotification({
    required String title,
    required String body,
  }) async {
    try {
      final l10n = deviceLocalizations();
      await _notificationsPlugin.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            foodReminderChannelId,
            l10n.notif_food_reminders_channel,
            channelDescription: l10n.notif_food_reminders_channel_description,
            importance: Importance.high,
            priority: Priority.high,
            icon: _androidNotificationIcon,
            color: AppColors.primary,
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
