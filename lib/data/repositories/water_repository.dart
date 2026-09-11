import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../core/services/security_service.dart';
import '../models/water_log.dart';
import '../../core/constants/app_constants.dart';
import '../services/cloud_record_sync.dart';

/// Repository for managing water intake data in Hive, synced to the account
/// through [CloudRecordSync].
class WaterRepository {
  /// Singleton, for consistency with the other repositories: one Hive handle
  /// and one init future per box. See [SettingsRepository].
  static final WaterRepository _instance = WaterRepository._internal();
  factory WaterRepository() => _instance;
  WaterRepository._internal();

  Box<WaterLog>? _waterBox;
  Future<void>? _initFuture;
  bool _initialized = false;

  // Only the last month is pulled onto a new device: older water logs feed
  // nothing but long-range history, and there can be many of them.
  final CloudRecordSync _cloud = CloudRecordSync(
    'waterLogs',
    initialWindow: const Duration(days: 30),
  );

  /// A water log has no id of its own; its timestamp, to the millisecond, is
  /// unique enough to name it in the cloud.
  static String _recordId(WaterLog log) => log.timestamp.toString();

  @visibleForTesting
  static Map<String, dynamic> toCloud(WaterLog log) => {
    'dateString': log.dateString,
    'amountMl': log.amountMl,
    'timestamp': log.timestamp,
  };

  @visibleForTesting
  static WaterLog? fromCloud(Map<String, dynamic> data) {
    final date = data['dateString'];
    final amount = data['amountMl'];
    final timestamp = data['timestamp'];
    if (date is! String || amount is! num || timestamp is! num) return null;
    return WaterLog(
      dateString: date,
      amountMl: amount.toInt(),
      timestamp: timestamp.toInt(),
    );
  }

  /// Cloud writes run in the background: logging water is a single tap that
  /// must not wait on the network. A failed write is queued by [_cloud].
  void _inBackground(Future<void> write) {
    unawaited(
      write.catchError((Object e) => debugPrint('Water sync failed: $e')),
    );
  }

  dynamic _keyForTimestamp(int timestamp) {
    final box = _waterBox;
    if (box == null) return null;
    for (final key in box.keys) {
      if (box.get(key)?.timestamp == timestamp) return key;
    }
    return null;
  }

  /// Initialize the repository
  Future<void> init() async {
    if (_initialized) return;
    final existingInit = _initFuture;
    if (existingInit != null) return existingInit;

    final initFuture = _initInternal();
    _initFuture = initFuture;
    try {
      await initFuture;
      _initialized = true;
    } finally {
      if (!_initialized) _initFuture = null;
    }
  }

  Future<void> _initInternal() async {
    try {
      final encryptionKey = await SecurityService().getEncryptionKey();
      _waterBox = await Hive.openBox<WaterLog>(
        AppConstants.waterBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint(
        '⚠️ WaterRepository: Box open failed, attempting recovery: $e',
      );
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
    _inBackground(_cloud.push(_recordId(log), toCloud(log)));
  }

  /// Remove the most recent water log, of [dateString] when given.
  Future<void> removeLastLog({String? dateString}) async {
    if (_waterBox == null || _waterBox!.isEmpty) return;

    final logs =
        _waterBox!.values
            .where((log) => dateString == null || log.dateString == dateString)
            .toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (logs.isNotEmpty) {
      final latest = logs.first;
      final key = _waterBox!.keys.firstWhere(
        (k) => _waterBox!.get(k)?.timestamp == latest.timestamp,
        orElse: () => null,
      );
      if (key != null) {
        await _waterBox!.delete(key);
        _inBackground(_cloud.remove(_recordId(latest)));
      }
    }
  }

  /// Get water logs for the last 7 days
  List<WaterLog> getWeeklyWater() {
    if (_waterBox == null) return [];
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _waterBox!.values
        .where(
          (log) => DateTime.fromMillisecondsSinceEpoch(
            log.timestamp,
          ).isAfter(weekAgo),
        )
        .toList();
  }

  /// Clear all logs for a specific date
  Future<void> clearLogsForDate(String dateString) async {
    if (_waterBox == null) return;
    final keysToDelete = <dynamic>[];
    final removed = <WaterLog>[];
    for (final key in _waterBox!.keys) {
      final log = _waterBox!.get(key);
      if (log != null && log.dateString == dateString) {
        keysToDelete.add(key);
        removed.add(log);
      }
    }
    for (final key in keysToDelete) {
      await _waterBox!.delete(key);
    }
    for (final log in removed) {
      _inBackground(_cloud.remove(_recordId(log)));
    }
  }

  /// Applies water logged or removed on the user's other devices. Returns
  /// whether anything on this phone changed.
  Future<bool> pullFromCloud() async {
    await init();
    return _cloud.pull(
      upsert: (id, data) async {
        final log = fromCloud(data);
        if (log == null || _waterBox == null) return false;
        if (_keyForTimestamp(log.timestamp) != null) return false;
        await _waterBox!.add(log);
        return true;
      },
      delete: (id) async {
        final timestamp = int.tryParse(id);
        final key = timestamp == null ? null : _keyForTimestamp(timestamp);
        if (key == null) return false;
        await _waterBox!.delete(key);
        return true;
      },
    );
  }

  /// Uploads every water log on this phone to the signed-in account.
  Future<void> pushAllLocal() async {
    await init();
    final box = _waterBox;
    if (box == null) return;
    await _cloud.pushAll({
      for (final log in box.values) _recordId(log): toCloud(log),
    });
  }

  /// Clear all (for testing)
  Future<void> clearAll() async {
    await _waterBox?.clear();
  }
}
