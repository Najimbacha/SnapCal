import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../core/services/security_service.dart';
import '../models/water_log.dart';
import '../../core/constants/app_constants.dart';

/// Repository for managing water intake data in Hive
class WaterRepository {
  Box<WaterLog>? _waterBox;

  /// Initialize the repository
  Future<void> init() async {
    try {
      final encryptionKey = await SecurityService().getEncryptionKey();
      _waterBox = await Hive.openBox<WaterLog>(
        AppConstants.waterBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('⚠️ WaterRepository: Box open failed, attempting recovery: $e');
      try {
        await Hive.deleteBoxFromDisk(AppConstants.waterBoxName);
        final encryptionKey = await SecurityService().getEncryptionKey();
        _waterBox = await Hive.openBox<WaterLog>(
          AppConstants.waterBoxName,
          encryptionCipher: HiveAesCipher(encryptionKey),
        );
        debugPrint('✅ WaterRepository: Recovery successful');
      } catch (retryError) {
        debugPrint('❌ WaterRepository: Fatal recovery failure: $retryError');
      }
    }
  }

  /// Get water for a specific date
  List<WaterLog> getWaterByDate(String dateString) {
    if (_waterBox == null) return [];
    return _waterBox!.values
        .where((log) => log.dateString == dateString)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get total water ml for a date
  int getTotalWater(String dateString) {
    final logs = getWaterByDate(dateString);
    return logs.fold(0, (sum, log) => sum + log.amountMl);
  }

  /// Add water entry
  Future<void> addWater(WaterLog log) async {
    await _waterBox?.add(log);
  }

  /// Remove the most recent water log
  Future<void> removeLastLog() async {
    if (_waterBox == null || _waterBox!.isEmpty) return;
    
    final logs = _waterBox!.values.toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (logs.isNotEmpty) {
      final latest = logs.first;
      final key = _waterBox!.keys.firstWhere(
        (k) => _waterBox!.get(k)?.timestamp == latest.timestamp,
        orElse: () => null,
      );
      if (key != null) {
        await _waterBox!.delete(key);
      }
    }
  }

  /// Get water logs for the last 7 days
  List<WaterLog> getWeeklyWater() {
    if (_waterBox == null) return [];
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _waterBox!.values
        .where((log) => DateTime.fromMillisecondsSinceEpoch(log.timestamp).isAfter(weekAgo))
        .toList();
  }

  /// Clear all (for testing)
  Future<void> clearAll() async {
    await _waterBox?.clear();
  }
}
