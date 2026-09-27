import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/screens/log/models/log_metric_models.dart';

void main() {
  test('weekly range starts on Sunday and ends on Saturday', () {
    final range = metricRangeFor(LogMetricPeriod.week, DateTime(2026, 5, 20));

    expect(range.start, DateTime(2026, 5, 17));
    expect(range.end, DateTime(2026, 5, 23));
  });

  test('month period creates one bucket per day in the month', () {
    final buckets = metricBucketsFor(
      LogMetricPeriod.month,
      DateTime(2026, 2, 14),
    );

    expect(buckets.length, 28);
    expect(buckets.first.start, DateTime(2026, 2));
    expect(buckets.last.end, DateTime(2026, 2, 28));
  });

  test('three month period is grouped into weekly buckets', () {
    final buckets = metricBucketsFor(
      LogMetricPeriod.threeMonths,
      DateTime(2026, 5, 14),
    );

    expect(buckets.first.start, DateTime(2026, 3));
    expect(buckets.last.end, DateTime(2026, 5, 31));
    expect(
      buckets.every((bucket) {
        return bucket.end.difference(bucket.start).inDays <= 6;
      }),
      isTrue,
    );
  });

  test('history lock only applies to meal-derived metrics', () {
    bool canViewDate(String _) => false;

    expect(
      isMetricDateLocked(LogMetricType.calories, '2026-05-01', canViewDate),
      isTrue,
    );
    expect(
      isMetricDateLocked(LogMetricType.protein, '2026-05-01', canViewDate),
      isTrue,
    );
    expect(
      isMetricDateLocked(LogMetricType.water, '2026-05-01', canViewDate),
      isFalse,
    );
    expect(
      isMetricDateLocked(LogMetricType.steps, '2026-05-01', canViewDate),
      isFalse,
    );
  });
}
