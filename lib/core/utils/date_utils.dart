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

  /// Parse date string to DateTime
  static DateTime parseDate(String dateString) {
    final parts = dateString.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Get a human-readable date label
  static String getDateLabel(String dateString) {
    final date = parseDate(dateString);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    final difference = today.difference(targetDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference == -1) {
      return 'Tomorrow';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}';
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
