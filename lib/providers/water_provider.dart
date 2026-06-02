import 'package:flutter/foundation.dart';
import '../data/models/water_log.dart';
import '../data/repositories/water_repository.dart';
import '../core/utils/date_utils.dart' as app_date;

/// Provider for managing water intake state
class WaterProvider with ChangeNotifier {
  final WaterRepository _repository;

  int _todaysWaterMl = 0;
  bool _isLoading = false;
  bool _isProcessing = false; // Guard for rapid clicks

  WaterProvider(this._repository) {
    _loadTodaysWater();
  }

  // Getters
  int get todaysWaterMl => _todaysWaterMl;
  int get total => _todaysWaterMl; // Alias for cleaner UI code
  int get goal => 2000; // Fallback or from settings
  bool get isLoading => _isLoading;
  int get completedGoalDays =>
      _todaysWaterMl >= 2000 ? 1 : 0; // Simple fallback

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

  /// Remove water intake (undo)
  Future<void> removeWater(int amountMl) async {
    if (_isProcessing) return;
    _isProcessing = true;
    notifyListeners();

    try {
      await _repository.removeLastLog(); // Or specific amount logic
      await _loadTodaysWater();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Clear water for today (for testing or reset)
  Future<void> resetToday() async {
    // This isn't strictly necessary for MVP but good for testing
  }

  /// Clear all water data (logout)
  Future<void> clear() async {
    await _repository.clearAll();
    _todaysWaterMl = 0;
    notifyListeners();
  }
}
