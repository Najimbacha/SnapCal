import 'package:flutter/foundation.dart';
import '../data/models/water_log.dart';
import '../data/repositories/water_repository.dart';
import '../core/utils/date_utils.dart' as app_date;

/// Provider for managing water intake state
class WaterProvider with ChangeNotifier {
  final WaterRepository _repository;

  int _todaysWaterMl = 0;
  int _goalMl = 2000;
  bool _isLoading = false;
  bool _isProcessing = false;

  WaterProvider(this._repository) {
    _loadTodaysWater();
  }

  int get todaysWaterMl => _todaysWaterMl;
  int get total => _todaysWaterMl;
  int get goal => _goalMl;
  bool get isLoading => _isLoading;
  int get completedGoalDays => _todaysWaterMl >= _goalMl ? 1 : 0;

  void setGoal(int ml) {
    _goalMl = ml;
    notifyListeners();
  }

  int getTotalForDate(String dateString) {
    if (app_date.DateUtils.isToday(dateString)) return _todaysWaterMl;
    return _repository.getTotalWater(dateString);
  }

  Map<String, int> getTotalsForRange(DateTime start, DateTime end) {
    final totals = <String, int>{};
    var current = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!current.isAfter(last)) {
      final dateString = app_date.DateUtils.getDateString(current);
      totals[dateString] = getTotalForDate(dateString);
      current = current.add(const Duration(days: 1));
    }
    return totals;
  }

  /// Load today's water intake
  Future<void> _loadTodaysWater() async {
    _isLoading = true;
    notifyListeners();

    final today = app_date.DateUtils.getTodayString();
    _todaysWaterMl = _repository.getTotalWater(today);

    _isLoading = false;
    notifyListeners();
  }

  /// Add water intake
  Future<void> addWater(int amountMl) async {
    if (_isProcessing) return;
    _isProcessing = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final log = WaterLog(
        dateString: app_date.DateUtils.getDateString(now),
        amountMl: amountMl,
        timestamp: now.millisecondsSinceEpoch,
      );

      await _repository.addWater(log);
      await _loadTodaysWater();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Undo the last water addition by removing the most recent log entry.
  Future<void> removeWater(int amountMl) async {
    if (_isProcessing) return;
    _isProcessing = true;
    notifyListeners();

    try {
      await _repository.removeLastLog();
      await _loadTodaysWater();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Clear all water logged today
  Future<void> resetToday() async {
    final today = app_date.DateUtils.getTodayString();
    await _repository.clearLogsForDate(today);
    _todaysWaterMl = 0;
    notifyListeners();
  }

  /// Clear all water data (logout)
  Future<void> clear() async {
    await _repository.clearAll();
    _todaysWaterMl = 0;
    _goalMl = 2000;
    notifyListeners();
  }
}
