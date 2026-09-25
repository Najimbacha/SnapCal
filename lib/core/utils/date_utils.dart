import 'package:intl/intl.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

/// Utility class for date operations
class DateUtils {
  DateUtils._();

  /// Get date string in YYYY-MM-DD format
  static String getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get today's date string
  static String getTodayString() {
    return getDateString(DateTime.now());
  }

  /// [date] moved by [days] calendar days, keeping its time of day.
  ///
  /// Not `date.add(Duration(days: n))`: a Duration is a fixed number of
  /// hours, and Dart documents `Duration(days: 1)` as exactly 24 of them.
  /// Where daylight saving switches at midnight -- Egypt and Lebanon do --
  /// midnight plus 24 hours is 23:00 the same day, or 01:00 the day after
  /// next, and "yesterday" came out two days ago. That reset streaks every
  /// April for anyone in Cairo. The constructor normalises an overflowed
  /// day into the right month and resolves the wall-clock time in the
  /// local zone, which is what a calendar day means.
  static DateTime addDays(DateTime date, int days) => DateTime(
    date.year,
    date.month,
    date.day + days,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
    date.microsecond,
  );

  /// Whole calendar days from [from] to [to], ignoring the time of day.
  ///
  /// `DateTime.difference().inDays` counts 24-hour spans, so across a
  /// daylight-saving change a day is 23 hours and counts as none. Done in
  /// UTC, where every day is 24 hours, so the answer is the calendar's.
  static int calendarDaysBetween(DateTime from, DateTime to) =>
      DateTime.utc(to.year, to.month, to.day)
          .difference(DateTime.utc(from.year, from.month, from.day))
          .inDays;

  /// The meal a new entry most likely is, by the time of day. The gap before
  /// dinner, like the small hours, reads as a snack.
  static String suggestedMealType([DateTime? at]) {
    final hour = (at ?? DateTime.now()).hour;
    if (hour >= 5 && hour < 11) return 'Breakfast';
    if (hour >= 11 && hour < 16) return 'Lunch';
    if (hour >= 18 && hour < 23) return 'Dinner';
    return 'Snack';
  }

  /// Parse date string to DateTime.
  ///
  /// Stored date strings come from Hive (`Meal.dateString`) and can be
  /// truncated or corrupted; this must never throw from deep inside list
  /// rendering. Falls back to today for unparseable input so one bad row
  /// degrades gracefully instead of crashing the screen (BUG-014).
  static DateTime parseDate(String dateString) {
    final parsed = DateTime.tryParse(dateString);
    if (parsed != null) return parsed;

    final parts = dateString.split('-');
    if (parts.length >= 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year != null &&
          month != null &&
          day != null &&
          month >= 1 &&
          month <= 12 &&
          day >= 1 &&
          day <= 31) {
        return DateTime(year, month, day);
      }
    }

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Get a human-readable date label
  static String getDateLabel(
    String dateString, {
    AppLocalizations? l10n,
    String? localeName,
  }) {
    final date = parseDate(dateString);
    final difference = calendarDaysBetween(date, DateTime.now());

    if (difference == 0) {
      return l10n?.common_today ?? 'Today';
    } else if (difference == 1) {
      return l10n?.common_yesterday ?? 'Yesterday';
    } else if (difference == -1) {
      return l10n?.common_tomorrow ?? 'Tomorrow';
    } else {
      return DateFormat.MMMd(localeName ?? l10n?.localeName).format(date);
    }
  }

  /// Get previous day
  static String getPreviousDay(String dateString) {
    return getDateString(addDays(parseDate(dateString), -1));
  }

  /// Get next day
  static String getNextDay(String dateString) {
    return getDateString(addDays(parseDate(dateString), 1));
  }

  /// Check if date is today
  static bool isToday(String dateString) {
    return dateString == getTodayString();
  }

  /// Check if date is in the future
  static bool isFuture(String dateString) {
    final date = parseDate(dateString);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isAfter(today);
  }
}
