import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/services/notification_service.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  group('streak repair', () {
    test('a missed day breaks the streak', () {
      final settings = UserSettings.defaults().copyWith(
        currentStreak: 5,
        lastLoggedDate: '2026-09-08',
      );
      final repaired = Settings.repairStreak(settings, today: '2026-09-11');
      expect(repaired.currentStreak, 0);
    });

    test('a meal logged yesterday keeps it', () {
      final settings = UserSettings.defaults().copyWith(
        currentStreak: 5,
        lastLoggedDate: '2026-09-10',
      );
      final repaired = Settings.repairStreak(settings, today: '2026-09-11');
      expect(identical(repaired, settings), isTrue);
    });
  });

  group('reminder time zone', () {
    setUpAll(tz_data.initializeTimeZones);

    test('uses the zone the platform names', () {
      final location = NotificationService.resolveLocation(
        'Asia/Karachi',
        utcOffset: const Duration(hours: 5),
      );
      expect(location.name, 'Asia/Karachi');
    });

    // iOS reported no zone at all, and every reminder fell back to UTC.
    test('without a name, follows the phone clock instead of UTC', () {
      const offset = Duration(hours: 5, minutes: 30);
      final location = NotificationService.resolveLocation(
        null,
        utcOffset: offset,
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(location.timeZone(now).offset, offset);
    });
  });

  group('next reminder across daylight saving', () {
    setUpAll(tz_data.initializeTimeZones);

    // "Tomorrow" was today plus 24 hours. On the evening before a switch that
    // is an hour off, and DateTimeComponents.time repeated the wrong hour
    // every day after.
    test('Cairo: the night before clocks go back, 08:00 is still 08:00', () {
      final cairo = tz.getLocation('Africa/Cairo');
      // Egypt ends summer time at midnight on the last Thursday of October.
      final now = tz.TZDateTime(cairo, 2026, 10, 29, 22, 0);
      final next = NotificationService.nextDailyOccurrence(
        now,
        hour: 8,
        minute: 0,
      );
      expect(next.location, cairo);
      expect([next.year, next.month, next.day], [2026, 10, 30]);
      expect([next.hour, next.minute], [8, 0]);
    });

    test('Cairo: the night before clocks go forward, 08:00 is 08:00', () {
      final cairo = tz.getLocation('Africa/Cairo');
      // Summer time begins at midnight on the last Friday of April.
      final now = tz.TZDateTime(cairo, 2026, 4, 23, 22, 0);
      final next = NotificationService.nextDailyOccurrence(
        now,
        hour: 8,
        minute: 0,
      );
      expect([next.year, next.month, next.day], [2026, 4, 24]);
      expect([next.hour, next.minute], [8, 0]);
    });

    test('London: the night before the spring switch, 08:00 is 08:00', () {
      final london = tz.getLocation('Europe/London');
      final now = tz.TZDateTime(london, 2026, 3, 28, 9, 0);
      final next = NotificationService.nextDailyOccurrence(
        now,
        hour: 8,
        minute: 0,
      );
      expect([next.year, next.month, next.day], [2026, 3, 29]);
      expect([next.hour, next.minute], [8, 0]);
    });

    test('stays today while the time is still ahead', () {
      final london = tz.getLocation('Europe/London');
      final now = tz.TZDateTime(london, 2026, 3, 28, 7, 0);
      final next = NotificationService.nextDailyOccurrence(
        now,
        hour: 8,
        minute: 0,
      );
      expect(next.day, 28);
      expect(
        NotificationService.nextDailyOccurrence(
          now,
          hour: 8,
          minute: 0,
          startTomorrow: true,
        ).day,
        29,
      );
    });
  });
}
