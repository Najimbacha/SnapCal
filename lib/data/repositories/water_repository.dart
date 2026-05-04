import 'package:hive/hive.dart';
import '../../core/services/security_service.dart';
import '../models/water_log.dart';
import '../../core/constants/app_constants.dart';

/// Repository for managing water intake data in Hive
class WaterRepository {
  Box<WaterLog>? _waterBox;

  /// Initialize the repository
  Future<void> init() async {
    final encryptionKey = await SecurityService().getEncryptionKey();
    _waterBox = await Hive.openBox<WaterLog>(
      AppConstants.waterBoxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
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

  /// Clear all (for testing)
  Future<void> clearAll() async {
    await _waterBox?.clear();
  }
}
