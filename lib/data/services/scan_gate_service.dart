import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScanGateService {
  static final ScanGateService _instance = ScanGateService._internal();
  factory ScanGateService() => _instance;
  ScanGateService._internal();

  SharedPreferences? _prefs;
  bool _initialized = false;
  bool _repairRan = false;

  static const String _bonusScansKey = 'bonusScansCount';
  static const String _lastDateKey = 'scanGate_lastDate';
  static const int _freeTierLimit = 3;

  Future<void> init() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      await _migrateAndRepair();
    } catch (e) {
      debugPrint('❌ ScanGateService.init() failed: $e');
    }
  }

  bool _ready() {
    if (_initialized) return true;
    debugPrint('⚠️ ScanGateService: not initialized, using safe default');
    return false;
  }

  // ── Date helpers ─────────────────────────────────────────────────────────

  String _todayKey() {
    final n = DateTime.now();
    return 'scanCount_${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  // ── Migration & repair (runs once per process) ───────────────────────────

  Future<void> _migrateAndRepair() async {
    if (_repairRan) return;
    _repairRan = true;
    if (_prefs == null) return;

    final prefs = _prefs!;
    final todayKey = _todayKey();
    final todayStr = _todayStr();

    // 1.  Scan every scanCount_* key and repair invalid values.
    for (final k in prefs.getKeys()) {
      if (!k.startsWith('scanCount_')) continue;
      final v = prefs.get(k);
      final valid = v is int && v >= 0 && v <= 100;
      if (!valid) {
        debugPrint('🛠️ ScanGateService: repairing key "$k" (value=$v)');
        if (k == todayKey) {
          await prefs.setInt(k, 0);
        } else {
          await prefs.remove(k);
        }
      }
    }

    // 2.  Detect new-day boundary.
    //     If storedDate is null → first launch after update → reset.
    //     If storedDate != today    → new calendar day  → reset.
    final storedDate = prefs.getString(_lastDateKey);
    if (storedDate != todayStr) {
      debugPrint(
        '🔄 ScanGateService: daily reset '
        '(lastDate=$storedDate, today=$todayStr)',
      );
      await prefs.setInt(todayKey, 0);
      await prefs.setString(_lastDateKey, todayStr);
    }

    _logState();
  }

  // ── Safe SharedPreferences reads ─────────────────────────────────────────

  /// Returns the stored int for [key], or 0 if the value is missing, negative,
  /// NaN, infinite, or of an unexpected type.
  int _readInt(String key) {
    final raw = _prefs!.get(key);
    if (raw is int) return raw;
    if (raw is double && !raw.isNaN && !raw.isInfinite && raw >= 0) {
      return raw.toInt();
    }
    return 0;
  }

  // ── Public API ───────────────────────────────────────────────────────────

  int getTodayScanCount() {
    if (!_ready()) return 0;
    final raw = _readInt(_todayKey());
    final limit = _freeTierLimit + getBonusScans();
    final clamped = raw.clamp(0, limit);
    if (clamped != raw) {
      debugPrint('🛠️ ScanGateService: clamped today count $raw ➜ $clamped');
      _prefs!.setInt(_todayKey(), clamped);
    }
    return clamped;
  }

  int getBonusScans() {
    if (!_ready()) return 0;
    final raw = _readInt(_bonusScansKey);
    final clamped = raw.clamp(0, 100);
    if (clamped != raw) {
      debugPrint('🛠️ ScanGateService: clamped bonus $raw ➜ $clamped');
      _prefs!.setInt(_bonusScansKey, clamped);
    }
    return clamped;
  }

  Future<void> addBonusScans(int count) async {
    if (!_ready()) return;
    final cur = getBonusScans();
    final next = cur + count;
    await _prefs!.setInt(_bonusScansKey, next);
    debugPrint('📊 ScanGateService: bonus $cur ➜ $next');
  }

  Future<void> incrementScanCount() async {
    if (!_ready()) return;
    final before = getTodayScanCount();
    final limit = _freeTierLimit + getBonusScans();
    final after = (before + 1).clamp(0, limit);
    await _prefs!.setInt(_todayKey(), after);
    await _prefs!.setString(_lastDateKey, _todayStr());
    debugPrint('📊 ScanGateService: today count $before ➜ $after');
    _logState();
  }

  bool canScan(bool isPro) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anon';

    if (isPro) {
      debugPrint(
        '✅ ScanGateService: userId=$userId, isPro=true → scan allowed',
      );
      return true;
    }

    if (!_ready()) {
      debugPrint(
        '⚠️ ScanGateService: userId=$userId, isPro=false, not ready → '
        'allowing scan',
      );
      return true;
    }

    final used = getTodayScanCount();
    final limit = _freeTierLimit + getBonusScans();
    final ok = used < limit;

    debugPrint(
      '📊 ScanGateService: '
      'userId=$userId, '
      'isPro=$isPro, '
      'today=$_todayStr(), '
      'scansUsed=$used, '
      'scansRemaining=${limit - used}, '
      'limit=$limit '
      '→ ${ok ? "ALLOW" : "BLOCK"}',
    );

    return ok;
  }

  int getRemainingScans(bool isPro) {
    if (isPro) return -1;
    if (!_ready()) return _freeTierLimit;
    final limit = _freeTierLimit + getBonusScans();
    return (limit - getTodayScanCount()).clamp(0, limit);
  }

  // ── Diagnostics ──────────────────────────────────────────────────────────

  void _logState() {
    if (!_initialized) return;
    final todayKey = _todayKey();
    final todayStr = _todayStr();
    final used = _readInt(todayKey);
    final bonus = _readInt(_bonusScansKey);
    final limit = _freeTierLimit + bonus;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    debugPrint('═══════════ ScanGateService State ═══════════');
    debugPrint('  User ID        : $userId');
    debugPrint('  Today date     : $todayStr');
    debugPrint('  Last used date : ${_prefs!.getString(_lastDateKey)}');
    debugPrint('  Today key      : $todayKey');
    debugPrint('  Today count    : $used');
    debugPrint('  Bonus scans    : $bonus');
    debugPrint('  Free tier limit: $_freeTierLimit');
    debugPrint('  Effective limit: $limit');
    debugPrint('  Remaining      : ${(limit - used).clamp(0, limit)}');
    debugPrint('══════════════════════════════════════════════');
  }
}
