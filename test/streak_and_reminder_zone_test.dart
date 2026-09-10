import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/services/notification_service.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

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
}
