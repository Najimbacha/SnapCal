import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/resilience/app_failure.dart';
import '../../core/resilience/timeout_policy.dart';

class UploadQueueService with ChangeNotifier {
  static final UploadQueueService _instance = UploadQueueService._internal();
  factory UploadQueueService() => _instance;
  UploadQueueService._internal();

  Box<dynamic>? _box;
  Future<void>? _initFuture;
  bool _initialized = false;
  bool _isFlushing = false;
  UploadTask? _activeTask;
  String? _activeJobId;
  double _activeProgress = 0;

  static const int _maxAttempts = 8;

  bool get isFlushing => _isFlushing;
  int get pendingCount => _box?.length ?? 0;
  String? get activeJobId => _activeJobId;
  double get activeProgress => _activeProgress;

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
    if (!Hive.isBoxOpen(AppConstants.uploadQueueBoxName)) {
      _box = await Hive.openBox<dynamic>(
        AppConstants.uploadQueueBoxName,
      ).timeout(TimeoutPolicy.localStorage);
    } else {
      _box = Hive.box<dynamic>(AppConstants.uploadQueueBoxName);
    }
  }

  Future<void> enqueueFileUpload({
    required String id,
    required String localFilePath,
    required String storagePath,
    Map<String, String> metadata = const {},
    String? finalizeDocumentPath,
    String finalizeField = 'imageUrl',
    bool deleteLocalFileOnSuccess = false,
  }) async {
    await init();
    await _box?.put(id, {
      'id': id,
      'localFilePath': localFilePath,
      'storagePath': storagePath,
      'metadata': metadata,
      'finalizeDocumentPath': finalizeDocumentPath,
      'finalizeField': finalizeField,
      'deleteLocalFileOnSuccess': deleteLocalFileOnSuccess,
      'attempts': 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'nextRetryAt': 0,
      'lastError': null,
      'progress': 0.0,
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
            final job = entry.value;
            if (job == null) return false;
            final nextRetryAt = job['nextRetryAt'] as int? ?? 0;
            return nextRetryAt <= now;
          }).toList();

      for (final entry in entries) {
        final job = entry.value;
        if (job == null) continue;
        final key = entry.key;

        try {
          final downloadUrl = await _perform(job).timeout(TimeoutPolicy.upload);
          await _finalize(job, downloadUrl).timeout(TimeoutPolicy.firestore);
          await _cleanupLocalFile(job);
          await box.delete(key);
        } catch (error) {
          final failure = AppFailure.fromError(error);
          final attempts = (job['attempts'] as int? ?? 0) + 1;
          if (!failure.isRetryable || attempts >= _maxAttempts) {
            job['attempts'] = attempts;
            job['lastError'] = failure.message;
            job['nextRetryAt'] = 0;
            await box.put(key, job);
            debugPrint('Upload queue item stalled after $attempts attempts: $failure');
            continue;
          }
          job['attempts'] = attempts;
          job['lastError'] = failure.message;
          job['nextRetryAt'] =
              DateTime.now()
                  .add(_backoff(attempts, failure.retryAfter))
                  .millisecondsSinceEpoch;
          await box.put(key, job);
        } finally {
          _activeTask = null;
          _activeJobId = null;
          _activeProgress = 0;
          notifyListeners();
        }
      }
    } finally {
      _isFlushing = false;
      notifyListeners();
    }
  }

  Future<void> pauseActiveUpload() async {
    await _activeTask?.pause();
  }

  Future<void> resumeActiveUpload() async {
    await _activeTask?.resume();
  }

  Future<void> cancelActiveUpload() async {
    await _activeTask?.cancel();
    _activeTask = null;
    _activeJobId = null;
    _activeProgress = 0;
    notifyListeners();
  }

  Future<String> _perform(Map<String, dynamic> job) async {
    final id = job['id'] as String?;
    final localFilePath = job['localFilePath'] as String?;
    final storagePath = job['storagePath'] as String?;
    if (id == null ||
        id.isEmpty ||
        localFilePath == null ||
        localFilePath.isEmpty ||
        storagePath == null ||
        storagePath.isEmpty) {
      throw const AppFailure(
        type: AppFailureType.badResponse,
        message: 'Upload queue job is malformed.',
      );
    }

    final file = File(localFilePath);
    if (!file.existsSync()) {
      throw const AppFailure(
        type: AppFailureType.notFound,
        message: 'Upload file is missing.',
      );
    }

    _activeJobId = id;
    _activeProgress = (job['progress'] as num?)?.toDouble() ?? 0;
    notifyListeners();

    final metadata = _asStringMap(job['metadata']) ?? const <String, String>{};
    final ref = FirebaseStorage.instance.ref(storagePath);
    final task = ref.putFile(file, SettableMetadata(customMetadata: metadata));
    _activeTask = task;

    final subscription = task.snapshotEvents.listen((snapshot) {
      final total = snapshot.totalBytes;
      if (total <= 0) return;
      _activeProgress = snapshot.bytesTransferred / total;
      notifyListeners();
    });

    try {
      final snapshot = await task;
      return snapshot.ref.getDownloadURL();
    } on FirebaseException catch (error) {
      throw AppFailure.fromError(error).copyWith(
        type: AppFailureType.uploadInterrupted,
        message: error.message ?? 'Upload was interrupted. It will retry.',
      );
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> _finalize(Map<String, dynamic> job, String downloadUrl) async {
    final documentPath = job['finalizeDocumentPath'] as String?;
    if (documentPath == null || documentPath.isEmpty) return;
    final field = (job['finalizeField'] as String?) ?? 'imageUrl';
    await FirebaseFirestore.instance.doc(documentPath).set({
      field: downloadUrl,
      'uploadStatus': 'complete',
      'uploadedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _cleanupLocalFile(Map<String, dynamic> job) async {
    final deleteLocal = job['deleteLocalFileOnSuccess'] as bool? ?? false;
    if (!deleteLocal) return;
    final path = job['localFilePath'] as String?;
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (file.existsSync()) await file.delete();
  }

  Duration _backoff(int attempts, Duration? retryAfter) {
    if (retryAfter != null) return retryAfter;
    final seconds = min(90, pow(2, attempts).toInt());
    final jitterMs = Random().nextInt(700);
    return Duration(seconds: seconds, milliseconds: jitterMs);
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  Map<String, String>? _asStringMap(dynamic value) {
    if (value is! Map) return null;
    return value.map((key, entryValue) {
      return MapEntry(key.toString(), entryValue.toString());
    });
  }

  Future<void> clear() async {
    await init();
    await cancelActiveUpload();
    await _box?.clear();
    notifyListeners();
  }
}
