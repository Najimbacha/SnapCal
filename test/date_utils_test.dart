import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/core/utils/date_utils.dart';

// The day arithmetic used to be `Duration(days: 1)`, which Dart defines as
// exactly 24 hours. Where daylight saving switches at midnight (Egypt,
// Lebanon) that is 23:00 the same day or 01:00 two days on, so "yesterday"
// was two days ago and streaks reset. A test cannot pick its own time zone,
// so these pin the calendar semantics the fix relies on; the zone-specific
// case is covered where the zone can be chosen, in the reminder tests.
void main() {
  group('addDays', () {
    test('crosses a month boundary', () {
      expect(
        DateUtils.getDateString(DateUtils.addDays(DateTime(2026, 3, 1), -1)),
        '2026-02-28',
      );
      expect(
        DateUtils.getDateString(DateUtils.addDays(DateTime(2026, 1, 31), 1)),
        '2026-02-01',
      );
    });

    test('crosses a year boundary and a leap day', () {
      expect(
        DateUtils.getDateString(DateUtils.addDays(DateTime(2025, 12, 31), 1)),
        '2026-01-01',
      );
      expect(
        DateUtils.getDateString(DateUtils.addDays(DateTime(2028, 2, 28), 1)),
        '2028-02-29',
      );
    });

    test('keeps the time of day', () {
      final moved = DateUtils.addDays(DateTime(2026, 4, 24, 8, 30), 1);
      expect(moved.hour, 8);
      expect(moved.minute, 30);
      expect(moved.day, 25);
    });
  });

  group('previous and next day', () {
    test('are inverses across a month end', () {
      expect(DateUtils.getPreviousDay('2026-05-01'), '2026-04-30');
      expect(DateUtils.getNextDay('2026-04-30'), '2026-05-01');
    });

    test('a week of next days never repeats or skips a date', () {
      var day = '2026-10-26';
      final seen = <String>[day];
      for (var i = 0; i < 7; i++) {
        day = DateUtils.getNextDay(day);
        seen.add(day);
      }
      expect(seen, [
        '2026-10-26',
        '2026-10-27',
        '2026-10-28',
        '2026-10-29',
        '2026-10-30',
        '2026-10-31',
        '2026-11-01',
        '2026-11-02',
      ]);
    });
  });

  group('calendarDaysBetween', () {
    test('counts whole calendar days, ignoring the time of day', () {
      expect(
        DateUtils.calendarDaysBetween(
          DateTime(2026, 4, 24, 23, 59),
          DateTime(2026, 4, 25, 0, 1),
        ),
        1,
      );
      expect(
        DateUtils.calendarDaysBetween(DateTime(2026, 1, 1), DateTime(2026, 1, 1)),
        0,
      );
      expect(
        DateUtils.calendarDaysBetween(DateTime(2026, 1, 2), DateTime(2026, 1, 1)),
        -1,
      );
    });
  });

  group('getDateLabel', () {
    test('labels today, yesterday and tomorrow', () {
      final today = DateUtils.getTodayString();
      expect(DateUtils.getDateLabel(today), 'Today');
      expect(DateUtils.getDateLabel(DateUtils.getPreviousDay(today)), 'Yesterday');
      expect(DateUtils.getDateLabel(DateUtils.getNextDay(today)), 'Tomorrow');
    });
  });
}
