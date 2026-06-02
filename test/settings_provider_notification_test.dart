import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/core/utils/date_utils.dart' as app_date;
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/repositories/settings_repository.dart';
import 'package:snapcal/data/services/notification_service.dart';
import 'package:snapcal/providers/settings_provider.dart';

class FakeSettingsRepository implements SettingsRepository {
  UserSettings _settings;
  final _controller = StreamController<UserSettings>.broadcast();

  FakeSettingsRepository(this._settings);

  @override
  UserSettings getSettings() => _settings;

  @override
  Future<void> saveSettings(UserSettings settings) async {
    _settings = settings;
    _controller.add(settings);
  }

  @override
  Stream<UserSettings> get settingsStream => _controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNotificationService implements NotificationService {
  final List<String> scheduledReminders = [];
  bool dailyMotivationScheduled = false;
  bool skipTodayValue = false;

  @override
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
    required int hour,
    required int minute,
  }) async {
    scheduledReminders.add('$id-$hour:$minute');
  }

  @override
  Future<void> scheduleDailyMotivation({
    required List<MotivationNotificationCopy> messages,
    required String channelName,
    required String channelDescription,
    required int hour,
    required int minute,
    bool skipToday = false,
  }) async {
    dailyMotivationScheduled = true;
    skipTodayValue = skipToday;
  }

  @override
  Future<void> cancelDailyMotivation() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  late FakeNotificationService fakeNotificationService;

  setUp(() {
    fakeNotificationService = FakeNotificationService();
    NotificationService.customInstance = fakeNotificationService;
  });

  tearDown(() {
    NotificationService.customInstance = null;
  });

  test('UserSettings dailyMotivationEnabled defaults to false', () {
    final defaults = UserSettings.defaults();
    expect(defaults.dailyMotivationEnabled, isFalse);

    final fromJson = UserSettings.fromJson({});
    expect(fromJson.dailyMotivationEnabled, isFalse);
  });

  test(
    'SettingsProvider initializes and updates lastOpenedDate to today if different',
    () async {
      final today = app_date.DateUtils.getTodayString();
      final initialSettings = UserSettings.defaults().copyWith(
        lastOpenedDate: '2000-01-01',
      );
      final repo = FakeSettingsRepository(initialSettings);
      final provider = SettingsProvider(repo);

      // Let the async updates run
      await Future.delayed(Duration.zero);

      expect(provider.settings.lastOpenedDate, today);
      expect(repo.getSettings().lastOpenedDate, today);
    },
  );

  test(
    'SettingsProvider passes skipToday: true if lastOpenedDate is today',
    () async {
      final today = app_date.DateUtils.getTodayString();
      final initialSettings = UserSettings.defaults().copyWith(
        lastOpenedDate: today,
        dailyMotivationEnabled: true,
        notificationsEnabled: true,
      );
      final repo = FakeSettingsRepository(initialSettings);
      SettingsProvider(repo);

      await Future.delayed(Duration.zero);

      expect(fakeNotificationService.dailyMotivationScheduled, isTrue);
      expect(fakeNotificationService.skipTodayValue, isTrue);
    },
  );

  test(
    'SettingsProvider passes skipToday: true if lastLoggedDate is today',
    () async {
      final today = app_date.DateUtils.getTodayString();
      final initialSettings = UserSettings.defaults().copyWith(
        lastOpenedDate: '2000-01-01',
        lastLoggedDate: today,
        dailyMotivationEnabled: true,
        notificationsEnabled: true,
      );
      final repo = FakeSettingsRepository(initialSettings);
      SettingsProvider(repo);

      await Future.delayed(Duration.zero);

      expect(fakeNotificationService.dailyMotivationScheduled, isTrue);
      expect(fakeNotificationService.skipTodayValue, isTrue);
    },
  );
}
