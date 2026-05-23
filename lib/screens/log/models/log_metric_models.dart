import '../../../core/utils/date_utils.dart' as app_date;

enum LogMetricPeriod { day, week, month, threeMonths, year }

enum LogMetricType {
  water,
  energy,
  steps,
  calories,
  carbs,
  fat,
  protein;

  static LogMetricType? fromId(String? id) {
    for (final type in values) {
      if (type.id == id) return type;
    }
    return null;
  }

  String get id {
    switch (this) {
      case LogMetricType.water:
        return 'water';
      case LogMetricType.energy:
        return 'energy';
      case LogMetricType.steps:
        return 'steps';
      case LogMetricType.calories:
        return 'calories';
      case LogMetricType.carbs:
        return 'carbs';
      case LogMetricType.fat:
        return 'fat';
      case LogMetricType.protein:
        return 'protein';
    }
  }

  bool get usesMealData {
    switch (this) {
      case LogMetricType.calories:
      case LogMetricType.carbs:
      case LogMetricType.fat:
      case LogMetricType.protein:
        return true;
      case LogMetricType.water:
      case LogMetricType.energy:
      case LogMetricType.steps:
        return false;
    }
  }
}

class MetricPeriodRange {
  final DateTime start;
  final DateTime end;

  const MetricPeriodRange({required this.start, required this.end});
}

class MetricBucket {
  final DateTime start;
  final DateTime end;

  const MetricBucket({required this.start, required this.end});
}

class MetricPoint {
  final DateTime start;
  final DateTime end;
  final int value;
  final int goal;
  final bool locked;

  const MetricPoint({
    required this.start,
    required this.end,
    required this.value,
    required this.goal,
    this.locked = false,
  });
}

DateTime normalizeMetricDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

MetricPeriodRange metricRangeFor(LogMetricPeriod period, DateTime anchor) {
  final date = normalizeMetricDate(anchor);
  switch (period) {
    case LogMetricPeriod.day:
      return MetricPeriodRange(start: date, end: date);
    case LogMetricPeriod.week:
      final start = date.subtract(Duration(days: date.weekday % 7));
      return MetricPeriodRange(
        start: start,
        end: start.add(const Duration(days: 6)),
      );
    case LogMetricPeriod.month:
      final start = DateTime(date.year, date.month);
      final end = DateTime(date.year, date.month + 1, 0);
      return MetricPeriodRange(start: start, end: end);
    case LogMetricPeriod.threeMonths:
      final start = DateTime(date.year, date.month - 2);
      final end = DateTime(date.year, date.month + 1, 0);
      return MetricPeriodRange(start: start, end: end);
    case LogMetricPeriod.year:
      final start = DateTime(date.year);
      final end = DateTime(date.year, 12, 31);
      return MetricPeriodRange(start: start, end: end);
  }
}

DateTime shiftMetricAnchor(
  LogMetricPeriod period,
  DateTime anchor,
  int direction,
) {
  switch (period) {
    case LogMetricPeriod.day:
      return normalizeMetricDate(anchor).add(Duration(days: direction));
    case LogMetricPeriod.week:
      return normalizeMetricDate(anchor).add(Duration(days: direction * 7));
    case LogMetricPeriod.month:
      return DateTime(anchor.year, anchor.month + direction, anchor.day);
    case LogMetricPeriod.threeMonths:
      return DateTime(anchor.year, anchor.month + (direction * 3), anchor.day);
    case LogMetricPeriod.year:
      return DateTime(anchor.year + direction, anchor.month, anchor.day);
  }
}

bool canMoveMetricPeriodForward(LogMetricPeriod period, DateTime anchor) {
  final today = normalizeMetricDate(DateTime.now());
  final nextRange = metricRangeFor(
    period,
    shiftMetricAnchor(period, anchor, 1),
  );
  return !nextRange.start.isAfter(today);
}

List<MetricBucket> metricBucketsFor(LogMetricPeriod period, DateTime anchor) {
  final range = metricRangeFor(period, anchor);
  switch (period) {
    case LogMetricPeriod.day:
      return [MetricBucket(start: range.start, end: range.end)];
    case LogMetricPeriod.week:
    case LogMetricPeriod.month:
      return _dailyBuckets(range);
    case LogMetricPeriod.threeMonths:
      return _weeklyBuckets(range);
    case LogMetricPeriod.year:
      return List.generate(12, (index) {
        final month = DateTime(range.start.year, index + 1);
        return MetricBucket(
          start: month,
          end: DateTime(month.year, month.month + 1, 0),
        );
      });
  }
}

bool isMetricDateLocked(
  LogMetricType type,
  String dateString,
  bool Function(String dateString) canViewDate,
) {
  return type.usesMealData && !canViewDate(dateString);
}

Iterable<DateTime> eachMetricDay(DateTime start, DateTime end) sync* {
  var current = normalizeMetricDate(start);
  final last = normalizeMetricDate(end);
  while (!current.isAfter(last)) {
    yield current;
    current = current.add(const Duration(days: 1));
  }
}

String metricDateString(DateTime date) {
  return app_date.DateUtils.getDateString(date);
}

List<MetricBucket> _dailyBuckets(MetricPeriodRange range) {
  return eachMetricDay(
    range.start,
    range.end,
  ).map((date) => MetricBucket(start: date, end: date)).toList();
}

List<MetricBucket> _weeklyBuckets(MetricPeriodRange range) {
  final buckets = <MetricBucket>[];
  var start = range.start;
  while (!start.isAfter(range.end)) {
    final end = start.add(const Duration(days: 6));
    buckets.add(
      MetricBucket(start: start, end: end.isAfter(range.end) ? range.end : end),
    );
    start = end.add(const Duration(days: 1));
  }
  return buckets;
}
