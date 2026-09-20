import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/pref_scoping.dart';
import '../../core/network/api_client.dart';
import '../../core/services/config_service.dart';

typedef ScanQuotaRequest = ({String? scope, String month, int generation});

/// Gates food scans for free users.
///
/// The free tier defaults to 15 scans per calendar month (UTC). The client
/// counter is a display mirror of that authoritative quota; the server always
/// decides. Keys are UID-scoped so a new account on a shared device starts
/// with its own quota. UTC month keys match the backend; only the backend can
/// enforce quota independently of device clock changes.
class ScanGateService {
  static final ScanGateService _instance = ScanGateService._internal();
  factory ScanGateService() => _instance;
  ScanGateService._internal();

  @visibleForTesting
  ScanGateService.forTesting({
    required SharedPreferences preferences,
    required String? Function() scope,
    required DateTime Function() now,
  }) : _prefs = preferences,
       _initialized = true,
       _scope = scope,
       _now = now;

  String? Function() _scope = resolvePrefScope;
  DateTime Function() _now = DateTime.now;
  final ValueNotifier<int> changes = ValueNotifier(0);
  int _generation = 0;
  ScanQuotaRequest? _verified;
  Future<void>? _refresh;
  ScanQuotaRequest? _refreshRequest;

  String _key(String base, [String? scope]) {
    final uid = scope ?? _scope();
    return uid == null || uid.isEmpty ? base : '$uid:$base';
  }

  bool _isCurrent(ScanQuotaRequest request) =>
      request.scope == _scope() &&
      request.month == _currentMonthStr() &&
      request.generation == _generation;

  ScanQuotaRequest beginServerRefresh() => (
    scope: _scope(),
    month: _currentMonthStr(),
    generation: ++_generation,
  );

  /// Only show a confirmed count for the current account and UTC month.
  int? get verifiedRemaining {
    final request = _verified;
    if (request == null ||
        request.scope != _scope() ||
        request.month != _currentMonthStr()) {
      return null;
    }
    return getRemainingScans(false);
  }

  bool get isRefreshing =>
      _refreshRequest != null && _isCurrent(_refreshRequest!);

  void invalidateServerCount() {
    _generation++;
    _verified = null;
    changes.value++;
  }

  /// Reject unknown balances and late responses from an older scan/account.
  Future<void> syncQuotaFromServer(Map data, ScanQuotaRequest request) async {
    await init();
    if (!_initialized || !_isCurrent(request)) return;
    int? whole(dynamic value) =>
        value is num &&
                value.isFinite &&
                value >= 0 &&
                value == value.roundToDouble()
            ? value.toInt()
            : null;
    final base = whole(data['monthlyScanLimit']);
    final bonus = whole(data['bonusScans']);
    final remaining = whole(data['scansRemaining']);
    if (base == null ||
        base < 1 ||
        base > 100 ||
        bonus == null ||
        bonus > 100 ||
        remaining == null ||
        remaining > base + bonus) {
      return;
    }
    final allowance = whole(data['scanAllowance']);
    if (data.containsKey('scanAllowance') && allowance != base + bonus) return;
    final prefs = _prefs!;
    await Future.wait([
      prefs.setInt(_key(_scanLimitKey, request.scope), base),
      prefs.setInt(_key(_bonusScansKey, request.scope), bonus),
      prefs.setInt(
        _key('scanCount_${request.month}', request.scope),
        base + bonus - remaining,
      ),
      prefs.setString(_key(_lastPeriodKey, request.scope), request.month),
    ]);
    if (!_isCurrent(request)) return;
    _verified = request;
    changes.value++;
  }

  Future<void> refreshFromServer({Dio? client}) async {
    if (!_initialized || _scope() == null) return;
    final pending = _refresh;
    if (pending != null && isRefreshing) return pending;
    final request = beginServerRefresh();
    _refreshRequest = request;
    changes.value++;
    final work = _fetchQuota(request, client ?? ApiClient.dio);
    _refresh = work;
    await work;
  }

  Future<void> _fetchQuota(ScanQuotaRequest request, Dio client) async {
    try {
      final response = await client
          .get('${ConfigService().backendProxyUrl}/api/premium-status')
          .timeout(const Duration(seconds: 5));
      if (response.data is Map) {
        await syncQuotaFromServer(response.data as Map, request);
      }
    } catch (_) {
      // A balance refresh must never discard a successfully scanned meal.
      debugPrint('Scan balance unavailable; keeping the scan result.');
    } finally {
      if (_refreshRequest == request) {
        _refreshRequest = null;
        _refresh = null;
        changes.value++;
      }
    }
  }

  SharedPreferences? _prefs;
  bool _initialized = false;
  bool _repairRan = false;

  static const String _bonusScansKey = 'bonusScansCount';
  static const String _lastPeriodKey = 'scanGate_lastMonth';
  static const String _scanLimitKey = 'freeScanLimit';

  /// What a device assumes before the server has told it anything.
  ///
  /// This was 3, which is not the policy -- the free tier is 15 a month. A
  /// phone that cannot reach the backend, or whose App Check attestation
  /// fails, never learns the real number and silently offered 12 fewer scans
  /// than the user is entitled to. Guessing high is safe: the server is the
  /// enforcing copy and refuses a scan past the real allowance regardless of
  /// what the client believes.
  static const int _defaultFreeTierLimit = 15;

  /// The free monthly allowance, before bonus scans.
  ///
  /// The server decides this -- it is FREE_MONTHLY_SCANS on the backend, and the
  /// server is what actually refuses a scan. This used to be a hardcoded 3 on
  /// both sides, which meant raising the server's number changed nothing: the
  /// client blocked at 3 before the server was ever asked, so the environment
  /// variable looked like a live knob and was not one.
  ///
  /// The last value premium-status reported is cached here and used until the
  /// server says otherwise, so the limit survives being offline. 15 is only the
  /// fallback for a device that has never heard an answer.
  static int get freeTierLimit => _instance._storedFreeLimit();

  int _storedFreeLimit() {
    if (!_ready()) return _defaultFreeTierLimit;
    final raw = _readInt(_key(_scanLimitKey));
    if (raw <= 0) return _defaultFreeTierLimit;
    // A sane ceiling: a corrupted or hostile value must not turn the free
    // tier into an unlimited one.
    return raw.clamp(1, 100);
  }

  /// Records the allowance the server just reported.
  ///
  /// Called from the premium-status refresh. Takes the base monthly limit,
  /// not the allowance including bonuses -- the client adds its own bonus
  /// count on top, and syncing the combined number would count them twice.
  Future<void> syncFreeLimitFromServer(int serverLimit) async {
    if (!_ready()) return;
    if (serverLimit <= 0 || serverLimit > 100) return;
    final key = _key(_scanLimitKey);
    if (_readInt(key) == serverLimit) return;
    await _prefs!.setInt(key, serverLimit);
    debugPrint('🔄 ScanGateService: free limit synced to $serverLimit');
  }

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
    final monthKey = _currentMonthStr();

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
    debugPrint('🔀 ScanGateService: migrated anonymous quota');
  }

  bool _ready() {
    if (_initialized) return true;
    debugPrint('⚠️ ScanGateService: not initialized, using safe default');
    return false;
  }

  // ── Period helpers ───────────────────────────────────────────────────────

  /// `scanCount_YYYY-MM` in UTC — mirrors the server's monthly quota window.
  String _currentScanKey() {
    return _key('scanCount_${_currentMonthStr()}');
  }

  String _currentMonthStr() => utcMonthKey(_now());

  /// All stored scan-count keys for the current scope (any month).
  Iterable<String> _scanKeysForCurrentScope(SharedPreferences prefs) {
    final scope = _scope();
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
    final storedMonth = prefs.getString(_key(_lastPeriodKey));
    if (storedMonth != currentMonth) {
      debugPrint(
        '🔄 ScanGateService: monthly reset '
        '(lastMonth=$storedMonth, now=$currentMonth)',
      );
      await prefs.setInt(currentKey, 0);
      await prefs.setString(_key(_lastPeriodKey), currentMonth);
    }

    _logState();
  }

  /// Removes every user-scoped counter. Invoked by SessionCleanupService on
  /// sign-out so the next account starts from zero.
  Future<void> resetSessionState() async {
    invalidateServerCount();
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
    final limit = _storedFreeLimit() + getBonusScans();
    final clamped = raw.clamp(0, limit);
    if (clamped != raw) {
      debugPrint('🛠️ ScanGateService: clamped period count $raw ➜ $clamped');
      _prefs!.setInt(_currentScanKey(), clamped);
    }
    return clamped;
  }

  int getBonusScans() {
    if (!_ready()) return 0;
    final key = _key(_bonusScansKey);
    final raw = _readInt(key);
    final clamped = raw.clamp(0, 100);
    if (clamped != raw) {
      debugPrint('🛠️ ScanGateService: clamped bonus $raw ➜ $clamped');
      _prefs!.setInt(key, clamped);
    }
    return clamped;
  }
  // addBonusScans and _grantBonusScanOnServer lived here.
  //
  // They asked the server for a free scan, and the server granted one to any
  // authenticated caller -- no proof, just a token. They existed for rewarded
  // ads; the ads were removed and nothing has called addBonusScans since.
  // The endpoint is gone too. getBonusScans and syncBonusScansFromServer stay,
  // so bonuses already banked on the server are still read and honoured.

  /// Replaces the local bonus mirror with the server's number.
  ///
  /// Called from the premium-status refresh, so a device that granted itself
  /// bonuses under the old build (or lost a response) converges on what the
  /// server will actually honour.
  Future<void> syncBonusScansFromServer(int serverBonus) async {
    if (!_ready()) return;
    if (serverBonus < 0) return;
    final key = _key(_bonusScansKey);
    if (_readInt(key) == serverBonus) return;
    await _prefs!.setInt(key, serverBonus);
    debugPrint('🔄 ScanGateService: bonus synced to $serverBonus');
  }

  bool canScan(bool isPro) {
    final userId = _scope() ?? 'anon';

    if (isPro) {
      debugPrint(
        '✅ ScanGateService: userId=$userId, isPro=true → scan allowed',
      );
      return true;
    }

    if (!_ready() || verifiedRemaining == null) {
      debugPrint(
        '⚠️ ScanGateService: userId=$userId, isPro=false, not ready → '
        'allowing scan',
      );
      return true;
    }

    final used = getPeriodScanCount();
    final limit = _storedFreeLimit() + getBonusScans();
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

  /// The full monthly allowance: the server's free limit plus earned bonuses.
  ///
  /// The paywall needs this to state a true number. Reading it here rather
  /// than hardcoding one keeps the screen honest when FREE_MONTHLY_SCANS
  /// changes on the server, and counts bonus scans the same way canScan does.
  int getMonthlyLimit() => _storedFreeLimit() + getBonusScans();

  int getRemainingScans(bool isPro) {
    if (isPro) return -1;
    if (!_ready()) return _defaultFreeTierLimit;
    final limit = _storedFreeLimit() + getBonusScans();
    return (limit - getPeriodScanCount()).clamp(0, limit);
  }

  // ── Diagnostics ──────────────────────────────────────────────────────────

  void _logState() {
    if (!_initialized) return;
    final used = _readInt(_currentScanKey());
    final bonus = getBonusScans();
    final limit = _storedFreeLimit() + bonus;
    final userId = _scope() ?? 'anon';
    debugPrint('═══════════ ScanGateService State ═══════════');
    debugPrint('  User ID        : $userId');
    debugPrint('  Current month  : ${_currentMonthStr()}');
    debugPrint('  Last period    : ${_prefs!.getString(_key(_lastPeriodKey))}');
    debugPrint('  Month count    : $used');
    debugPrint('  Bonus scans    : $bonus');
    debugPrint('  Free tier limit: ${_storedFreeLimit()}');
    debugPrint('  Effective limit: $limit');
    debugPrint('  Remaining      : ${(limit - used).clamp(0, limit)}');
    debugPrint('══════════════════════════════════════════════');
  }
}
