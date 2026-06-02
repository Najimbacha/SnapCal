import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/resilience/app_failure.dart';
import '../../core/resilience/timeout_policy.dart';

class SyncQueueService with ChangeNotifier {
  static final SyncQueueService _instance = SyncQueueService._internal();
  factory SyncQueueService() => _instance;
  SyncQueueService._internal();

  Box<dynamic>? _box;
  Future<void>? _initFuture;
  bool _initialized = false;
  bool _isFlushing = false;
  static const int _maxAttempts = 12;

  bool get isFlushing => _isFlushing;
  int get pendingCount => _box?.length ?? 0;

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
    if (!Hive.isBoxOpen(AppConstants.syncQueueBoxName)) {
      _box = await Hive.openBox<dynamic>(
        AppConstants.syncQueueBoxName,
      ).timeout(TimeoutPolicy.localStorage);
    } else {
      _box = Hive.box<dynamic>(AppConstants.syncQueueBoxName);
    }
  }

  Future<void> enqueueSet({
    required String id,
    required String documentPath,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    await init();
    await _box?.put(id, {
      'id': id,
      'type': 'set',
      'documentPath': documentPath,
      'data': data,
      'merge': merge,
      'attempts': 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'nextRetryAt': 0,
      'lastError': null,
    });
    notifyListeners();
  }

  Future<void> enqueueDelete({
    required String id,
    required String documentPath,
  }) async {
    await init();
    await _box?.put(id, {
      'id': id,
      'type': 'delete',
      'documentPath': documentPath,
      'attempts': 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'nextRetryAt': 0,
      'lastError': null,
    });
    notifyListeners();
  }

  Future<void> flushDue() async {
    await init();
    final box = _box;
    final user = FirebaseAuth.instance.currentUser;
    if (box == null || box.isEmpty || user == null || _isFlushing) return;

    _isFlushing = true;
    notifyListeners();
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final entries =
          box.keys.map((key) => MapEntry(key, _asMap(box.get(key)))).where((
            entry,
          ) {
            final op = entry.value;
            if (op == null) return false;
            final nextRetryAt = op['nextRetryAt'] as int? ?? 0;
            return nextRetryAt <= now;
          }).toList();

      for (final entry in entries) {
        final key = entry.key;
        final op = entry.value;
        if (op == null) continue;

        try {
          await _perform(op).timeout(TimeoutPolicy.firestore);
          await box.delete(key);
        } catch (error) {
          final failure = AppFailure.fromError(error);
          final attempts = (op['attempts'] as int? ?? 0) + 1;
          if (!failure.isRetryable || attempts >= _maxAttempts) {
            debugPrint(
              'Dropping sync queue item after $attempts attempts: $failure',
            );
            await box.delete(key);
            continue;
          }
          op['attempts'] = attempts;
          op['lastError'] = failure.message;
          op['nextRetryAt'] =
              DateTime.now()
                  .add(_backoff(attempts, failure.retryAfter))
                  .millisecondsSinceEpoch;
          await box.put(key, op);
        }
      }
    } finally {
      _isFlushing = false;
      notifyListeners();
    }
  }

  Future<void> _perform(Map<String, dynamic> op) async {
    final path = op['documentPath'] as String?;
    final type = op['type'] as String?;
    if (path == null || path.isEmpty || type == null) {
      throw const AppFailure(
        type: AppFailureType.badResponse,
        message: 'Sync queue operation is malformed.',
      );
    }

    final doc = FirebaseFirestore.instance.doc(path);
    if (type == 'delete') {
      await doc.delete();
      return;
    }

    final data = _asStringDynamicMap(op['data']);
    if (data == null) {
      throw const AppFailure(
        type: AppFailureType.badResponse,
        message: 'Sync queue payload is malformed.',
      );
    }

    final merge = op['merge'] as bool? ?? true;
    await doc.set(data, SetOptions(merge: merge));
  }

  Duration _backoff(int attempts, Duration? retryAfter) {
    if (retryAfter != null) return retryAfter;
    final seconds = min(60, pow(2, attempts).toInt());
    final jitterMs = Random().nextInt(500);
    return Duration(seconds: seconds, milliseconds: jitterMs);
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  Map<String, dynamic>? _asStringDynamicMap(dynamic value) {
    if (value is! Map) return null;
    return value.map((key, entryValue) {
      return MapEntry(key.toString(), _normalize(entryValue));
    });
  }

  dynamic _normalize(dynamic value) {
    if (value is Map) {
      return value.map((key, entryValue) {
        return MapEntry(key.toString(), _normalize(entryValue));
      });
    }
    if (value is List) return value.map(_normalize).toList();
    return value;
  }

  Future<void> clear() async {
    await init();
    await _box?.clear();
    notifyListeners();
  }
}
