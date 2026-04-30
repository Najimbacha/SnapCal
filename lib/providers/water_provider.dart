import 'package:flutter/foundation.dart';
import '../data/models/water_log.dart';
import '../data/repositories/water_repository.dart';
import '../core/utils/date_utils.dart' as app_date;

/// Provider for managing water intake state
class WaterProvider with ChangeNotifier {
  final WaterRepository _repository;

  int _todaysWaterMl = 0;
  bool _isLoading = false;

  WaterProvider(this._repository) {
    _loadTodaysWater();
  }

  // Getters
  int get todaysWaterMl => _todaysWaterMl;
  bool get isLoading => _isLoading;

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
    final now = DateTime.now();
    final log = WaterLog(
      dateString: app_date.DateUtils.getDateString(now),
      amountMl: amountMl,
      timestamp: now.millisecondsSinceEpoch,
    );

    await _repository.addWater(log);
    await _loadTodaysWater();
  }

  /// Clear water for today (for testing or reset)
  Future<void> resetToday() async {
    // This isn't strictly necessary for MVP but good for testing
    // In a real app we might want to delete specific logs
  }

  /// Clear all water data (logout)
  Future<void> clear() async {
    await _repository.clearAll();
    _todaysWaterMl = 0;
    notifyListeners();
  }
}
