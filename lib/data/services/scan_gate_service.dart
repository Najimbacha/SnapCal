import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
import '../../core/services/config_service.dart';
import '../../core/utils/pref_scoping.dart';

/// Gates food scans for free users.
///
/// The free tier is **3 scans per calendar month (UTC)** — the same window the
/// server enforces via `/v1/scan` (402 past three per month). The client
/// counter is a display mirror of that authoritative quota; the server always
/// decides. Keys are UID-scoped so a new account on a shared device starts
/// with its own quota, and counters survive a device clock change because the
/// key is derived from UTC.
class ScanGateService {
  static final ScanGateService _instance = ScanGateService._internal();
  factory ScanGateService() => _instance;
  ScanGateService._internal();

  SharedPreferences? _prefs;
  bool _initialized = false;
  bool _repairRan = false;

  static const String _bonusScansKey = 'bonusScansCount';
  static const String _lastPeriodKey = 'scanGate_lastMonth';
  static const int _freeTierLimit = 3;

  /// The free monthly allowance, before bonus scans. Read this instead of
  /// re-deriving the number elsewhere.
  static int get freeTierLimit => _freeTierLimit;

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

  /// Carries the anonymous session's counters over to [uid].
  ///
  /// Quota keys are namespaced by Firebase UID, and the app signs users in
  /// anonymously at launch — so signing in with Google produced a fresh UID
  /// and a fresh, empty quota. Three free scans became six. Call this on
  /// sign-in, before the new scope is used.
  Future<void> migrateScopeTo(String uid) async {
    if (!_ready()) return;
    final prefs = _prefs!;
    final monthKey = utcMonthKey(DateTime.now());

    final fromCount = prefs.getInt('scanCount_$monthKey') ?? 0;
    final fromBonus = prefs.getInt(_bonusScansKey) ?? 0;
    if (fromCount == 0 && fromBonus == 0) return;

    final toCountKey = '$uid:scanCount_$monthKey';
    final toBonusKey = '$uid:$_bonusScansKey';

    // Take the higher count so a migration can never hand back free scans.
    final merged = (prefs.getInt(toCountKey) ?? 0);
    await prefs.setInt(toCountKey, fromCount > merged ? fromCount : merged);
    if (fromBonus > (prefs.getInt(toBonusKey) ?? 0)) {
      await prefs.setInt(toBonusKey, fromBonus);
    }
    await prefs.setString('$uid:$_lastPeriodKey', monthKey);

    await prefs.remove('scanCount_$monthKey');
    await prefs.remove(_bonusScansKey);
    debugPrint('🔀 ScanGateService: migrated anonymous quota into $uid');
  }

  bool _ready() {
    if (_initialized) return true;
    debugPrint('⚠️ ScanGateService: not initialized, using safe default');
    return false;
  }

  // ── Period helpers ───────────────────────────────────────────────────────

  /// `scanCount_YYYY-MM` in UTC — mirrors the server's monthly quota window.
  String _currentScanKey() {
    return scopedPrefKey('scanCount_${utcMonthKey(DateTime.now())}');
  }

  String _currentMonthStr() => utcMonthKey(DateTime.now());

  /// All stored scan-count keys for the current scope (any month).
  Iterable<String> _scanKeysForCurrentScope(SharedPreferences prefs) {
    final scope = resolvePrefScope();
    return prefs.getKeys().where((k) {
      if (!k.contains('scanCount_')) return false;
      if (scope == null || scope.isEmpty) return !k.contains(':');
      return k.startsWith('$scope:scanCount_');
    });
  }

  // ── Migration & repair (runs once per process) ───────────────────────────

  Future<void> _migrateAndRepair() async {
    if (_repairRan) return;
    _repairRan = true;
    if (_prefs == null) return;

    final prefs = _prefs!;
    final currentKey = _currentScanKey();
    final currentMonth = _currentMonthStr();

    // 1. Repair invalid values and remove stale keys from previous months,
    //    previous scopes, and the legacy daily (`scanCount_YYYY-MM-DD`)
    //    scheme.
    final ourKeys = _scanKeysForCurrentScope(prefs).toSet();
    for (final k in ourKeys) {
      final v = prefs.get(k);
      final valid = v is int && v >= 0 && v <= 100;
      if (!valid || k != currentKey) {
        debugPrint('🛠️ ScanGateService: removing stale key "$k" (value=$v)');
        await prefs.remove(k);
      }
    }

    // 2. Detect new-month boundary and reset.
    final storedMonth = prefs.getString(scopedPrefKey(_lastPeriodKey));
    if (storedMonth != currentMonth) {
      debugPrint(
        '🔄 ScanGateService: monthly reset '
        '(lastMonth=$storedMonth, now=$currentMonth)',
      );
      await prefs.setInt(currentKey, 0);
      await prefs.setString(scopedPrefKey(_lastPeriodKey), currentMonth);
    }

    _logState();
  }

  /// Removes every user-scoped counter. Invoked by SessionCleanupService on
  /// sign-out so the next account starts from zero.
  Future<void> resetSessionState() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final keys =
        prefs.getKeys().where((k) {
          return prefKeyBelongsTo(k, _bonusScansKey) ||
              prefKeyBelongsTo(k, _lastPeriodKey) ||
              k.contains('scanCount_');
        }).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
    _repairRan = false;
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

  /// Scans used in the current UTC month (the server-enforced window).
  int getPeriodScanCount() {
    if (!_ready()) return 0;
    final raw = _readInt(_currentScanKey());
    final limit = _freeTierLimit + getBonusScans();
    final clamped = raw.clamp(0, limit);
    if (clamped != raw) {
      debugPrint('🛠️ ScanGateService: clamped period count $raw ➜ $clamped');
      _prefs!.setInt(_currentScanKey(), clamped);
    }
    return clamped;
  }

  int getBonusScans() {
    if (!_ready()) return 0;
    final key = scopedPrefKey(_bonusScansKey);
    final raw = _readInt(key);
    final clamped = raw.clamp(0, 100);
    if (clamped != raw) {
      debugPrint('🛠️ ScanGateService: clamped bonus $raw ➜ $clamped');
      _prefs!.setInt(key, clamped);
    }
    return clamped;
  }

  /// Records one earned bonus scan, on the server first.
  ///
  /// This used to write straight to SharedPreferences. The server knew nothing
  /// about bonus scans and enforced a flat three a month, so a user watched a
  /// rewarded ad, got told "+1 bonus scan unlocked", and had that very scan
  /// refused with a 402. The local number was a promise the server never
  /// agreed to.
  ///
  /// The server owns the count now. It is asked first, and the local mirror is
  /// only updated with the number it returns -- so the two cannot drift, and a
  /// failure here means the user is told the truth instead of being sent into
  /// a scan that is going to bounce.
  ///
  /// Returns true when the bonus was actually granted.
  Future<bool> addBonusScans(int count) async {
    if (!_ready()) return false;
    if (count <= 0) return false;

    int? serverBonus;
    var granted = false;
    for (var i = 0; i < count; i++) {
      final result = await _grantBonusScanOnServer();
      if (result == null) return false;
      granted = granted || result.$1;
      serverBonus = result.$2;
      // The monthly cap was already reached; asking again cannot help.
      if (!result.$1) break;
    }

    if (serverBonus != null) {
      await _prefs!.setInt(scopedPrefKey(_bonusScansKey), serverBonus);
      debugPrint('📊 ScanGateService: bonus now $serverBonus (from server)');
    }
    return granted;
  }

  /// (granted, bonusScansTotal), or null when the server could not be reached.
  Future<(bool, int)?> _grantBonusScanOnServer() async {
    try {
      final response = await ApiClient.dio.post(
        '${ConfigService().backendProxyUrl}/api/scans/bonus',
      );
      final data = response.data;
      if (data is! Map) return null;
      final total = (data['bonusScans'] as num?)?.toInt();
      if (total == null) return null;
      return (data['granted'] == true, total);
    } catch (e) {
      debugPrint('⚠️ ScanGateService: bonus scan not recorded — $e');
      return null;
    }
  }

  /// Replaces the local bonus mirror with the server's number.
  ///
  /// Called from the premium-status refresh, so a device that granted itself
  /// bonuses under the old build (or lost a response) converges on what the
  /// server will actually honour.
  Future<void> syncBonusScansFromServer(int serverBonus) async {
    if (!_ready()) return;
    if (serverBonus < 0) return;
    final key = scopedPrefKey(_bonusScansKey);
    if (_readInt(key) == serverBonus) return;
    await _prefs!.setInt(key, serverBonus);
    debugPrint('🔄 ScanGateService: bonus synced to $serverBonus');
  }

  Future<void> incrementScanCount() async {
    if (!_ready()) return;
    final before = getPeriodScanCount();
    final limit = _freeTierLimit + getBonusScans();
    final after = (before + 1).clamp(0, limit);
    await _prefs!.setInt(_currentScanKey(), after);
    await _prefs!.setString(scopedPrefKey(_lastPeriodKey), _currentMonthStr());
    debugPrint('📊 ScanGateService: month count $before ➜ $after');
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

    final used = getPeriodScanCount();
    final limit = _freeTierLimit + getBonusScans();
    final ok = used < limit;

    debugPrint(
      '📊 ScanGateService: '
      'userId=$userId, '
      'isPro=$isPro, '
      'month=${_currentMonthStr()}, '
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
    return (limit - getPeriodScanCount()).clamp(0, limit);
  }

  // ── Diagnostics ──────────────────────────────────────────────────────────

  void _logState() {
    if (!_initialized) return;
    final used = _readInt(_currentScanKey());
    final bonus = getBonusScans();
    final limit = _freeTierLimit + bonus;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    debugPrint('═══════════ ScanGateService State ═══════════');
    debugPrint('  User ID        : $userId');
    debugPrint('  Current month  : ${_currentMonthStr()}');
    debugPrint(
      '  Last period    : ${_prefs!.getString(scopedPrefKey(_lastPeriodKey))}',
    );
    debugPrint('  Month count    : $used');
    debugPrint('  Bonus scans    : $bonus');
    debugPrint('  Free tier limit: $_freeTierLimit');
    debugPrint('  Effective limit: $limit');
    debugPrint('  Remaining      : ${(limit - used).clamp(0, limit)}');
    debugPrint('══════════════════════════════════════════════');
  }
}
