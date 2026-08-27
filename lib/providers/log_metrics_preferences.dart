import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/pref_scoping.dart';
import '../screens/log/models/log_metric_models.dart';

part 'log_metrics_preferences.g.dart';

/// Which metric cards are visible on the Log dashboard, persisted per user.
/// The customize sheet enforces the free-tier gate (macro rows are Pro-only);
/// this provider only owns visibility.
@Riverpod(keepAlive: true)
class VisibleLogMetrics extends _$VisibleLogMetrics {
  static const String _key = 'log_visible_metrics';
  bool _disposed = false;

  @override
  Set<LogMetricType> build() {
    ref.onDispose(() => _disposed = true);
    _load();
    return Set<LogMetricType>.from(LogMetricType.values);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(scopedPrefKey(_key));
    if (_disposed || raw == null) return;
    final restored =
        raw.map(LogMetricType.fromId).whereType<LogMetricType>().toSet();
    if (!_disposed && restored.isNotEmpty) state = restored;
  }

  Future<void> toggle(LogMetricType type) async {
    final next = Set<LogMetricType>.from(state);
    if (next.contains(type)) {
      // Never leave the dashboard without a single card.
      if (next.length == 1) return;
      next.remove(type);
    } else {
      next.add(type);
    }
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      scopedPrefKey(_key),
      next.map((t) => t.id).toList(),
    );
  }
}
