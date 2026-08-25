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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    final difference = today.difference(targetDate).inDays;

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
    final date = parseDate(dateString);
    final previousDay = date.subtract(const Duration(days: 1));
    return getDateString(previousDay);
  }

  /// Get next day
  static String getNextDay(String dateString) {
    final date = parseDate(dateString);
    final nextDay = date.add(const Duration(days: 1));
    return getDateString(nextDay);
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
