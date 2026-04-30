import 'package:shared_preferences/shared_preferences.dart';

class ScanGateService {
  static final ScanGateService _instance = ScanGateService._internal();
  factory ScanGateService() => _instance;
  ScanGateService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  static const String _bonusScansKey = "bonusScansCount";

  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  String _getTodayKey() {
    final now = DateTime.now(); // Reset at midnight local time
    return "scanCount_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  int getTodayScanCount() {
    if (!_initialized) return 0;
    return _prefs.getInt(_getTodayKey()) ?? 0;
  }

  int getBonusScans() {
    if (!_initialized) return 0;
    return _prefs.getInt(_bonusScansKey) ?? 0;
  }

  Future<void> addBonusScans(int count) async {
    if (!_initialized) return;
    final current = getBonusScans();
    await _prefs.setInt(_bonusScansKey, current + count);
  }

  Future<void> incrementScanCount() async {
    if (!_initialized) return;
    final currentCount = getTodayScanCount();
    await _prefs.setInt(_getTodayKey(), currentCount + 1);
  }

  bool canScan(bool isPro) {
    if (isPro) return true;
    final baseLimit = 3;
    final bonus = getBonusScans();
    return getTodayScanCount() < (baseLimit + bonus);
  }

  int getRemainingScans(bool isPro) {
    if (isPro) return -1;
    final limit = 3 + getBonusScans();
    return (limit - getTodayScanCount()).clamp(0, limit);
  }
}
