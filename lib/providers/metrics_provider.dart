import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/resilience/app_failure.dart';
import '../core/resilience/resilient_provider_mixin.dart';
import '../core/resilience/retry_policy.dart';
import '../core/resilience/safe_async.dart';
import '../core/resilience/timeout_policy.dart';
import '../core/services/security_service.dart';
import '../core/state/async_ui_state.dart';
import '../data/models/body_metric.dart';
import '../data/services/upload_queue_service.dart';
import 'settings_provider.dart';

class MetricsProvider with ChangeNotifier, ResilientProviderMixin {
  static const String _boxName = 'body_metrics_box';
  Box<BodyMetric>? _box;
  SettingsProvider _settingsProvider;

  MetricsProvider(this._settingsProvider) {
    _init();
  }

  void updateSettings(SettingsProvider settings) {
    _settingsProvider = settings;
    notifyListeners();
  }

  AsyncUiState _uiState = const AsyncUiState.loading();
  bool get isLoading => _uiState.isBlocking;
  bool get isRefreshing => _uiState.isRefreshing;
  AsyncUiState get uiState => _uiState;

  List<BodyMetric> _metrics = [];
  List<BodyMetric> get metrics => _metrics;

  List<BodyMetric> get metricsWithPhotos =>
      _metrics
          .where((m) => m.photoFrontPath != null || m.photoSidePath != null)
          .toList();

  int get photosCount => metricsWithPhotos.length;

  Future<void> _init() async {
    final result = await SafeAsync.run<void>(
      label: 'Progress metrics init',
      operation: () async {
        if (!Hive.isBoxOpen(_boxName)) {
          final encryptionKey = await SecurityService().getEncryptionKey();
          _box = await Hive.openBox<BodyMetric>(
            _boxName,
            encryptionCipher: HiveAesCipher(encryptionKey),
          );
        } else {
          _box = Hive.box<BodyMetric>(_boxName);
        }
        _sortMetrics();
      },
      timeout: TimeoutPolicy.localStorage,
      retryPolicy: RetryPolicy.localStorage,
      isActive: () => isProviderActive,
    );
    if (!isProviderActive) return;

    if (result.isSuccess) {
      _uiState =
          _metrics.isEmpty
              ? const AsyncUiState.empty()
              : const AsyncUiState.success();
    } else {
      debugPrint(
        '⚠️ MetricsProvider: failed to initialize: ${result.failure}',
      );
      _uiState = stateFromFailure(result.failure!);
    }
    notifyListeners();
  }

  /// Sort/reload metrics from box without notifying listeners
  void _sortMetrics() {
    if (_box == null) {
      _metrics = [];
      return;
    }
    _metrics = _box!.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  void _loadMetrics() {
    _sortMetrics();
    notifyListeners();
  }

  /// Add or update a weight entry
  Future<void> logWeight(
    double weight, {
    double? bodyFat,
    DateTime? date,
  }) async {
    const opKey = 'metrics:logWeight';
    if (!canStartOperation(opKey)) return;
    _uiState =
        _metrics.isEmpty
            ? const AsyncUiState.loading()
            : const AsyncUiState.refreshing();
    notifyListeners();

    try {
      final entryDate = date ?? DateTime.now();
      final result = await SafeAsync.run<void>(
        label: 'Log progress weight',
        operation: () async {
          final existingIndex = _metrics.indexWhere(
            (m) =>
                m.date.year == entryDate.year &&
                m.date.month == entryDate.month &&
                m.date.day == entryDate.day,
          );

          if (existingIndex != -1) {
            final existing = _metrics[existingIndex];
            final updated = existing.copyWith(
              weight: weight,
              bodyFat: bodyFat ?? existing.bodyFat,
              date: entryDate,
            );
            await _box?.put(existing.key, updated);
          } else {
            final newMetric = BodyMetric(
              date: entryDate,
              weight: weight,
              bodyFat: bodyFat,
            );
            await _box?.add(newMetric);
          }
          _sortMetrics();
        },
        timeout: TimeoutPolicy.localStorage,
        retryPolicy: RetryPolicy.localStorage,
        isActive: () => isProviderActive,
      );

      if (result.isFailure) {
        _uiState = stateFromFailure(
          result.failure!,
          hasFallback: _metrics.isNotEmpty,
        );
        return;
      }

      _uiState =
          _metrics.isEmpty
              ? const AsyncUiState.empty()
              : const AsyncUiState.success();

      unawaited(
        SafeAsync.fireAndReport(
          label: 'Recalculate nutrition plan after weight log',
          operation:
              () => _settingsProvider
                  .recalculatePlan(currentWeightKg: weight)
                  .then((_) {}),
          timeout: TimeoutPolicy.localStorage,
          retryPolicy: RetryPolicy.none,
        ),
      );
    } finally {
      finishOperation(opKey);
      notifyListeners();
    }
  }

  /// Add a progress photo to a specific date's entry (or today)
  Future<void> logProgressPhoto(
    String photoPath, {
    required bool isFront,
    DateTime? date,
  }) async {
    const opKey = 'metrics:logProgressPhoto';
    if (!canStartOperation(opKey)) return;
    if (!File(photoPath).existsSync()) {
      _uiState = const AsyncUiState.error(
        'Progress photo file is missing.',
        AppFailure(
          type: AppFailureType.notFound,
          message: 'Progress photo file is missing.',
        ),
      );
      notifyListeners();
      finishOperation(opKey);
      return;
    }

    _uiState =
        _metrics.isEmpty
            ? const AsyncUiState.loading()
            : const AsyncUiState.refreshing();
    notifyListeners();

    try {
      final entryDate = date ?? DateTime.now();
      final result = await SafeAsync.run<void>(
        label: 'Log progress photo',
        operation: () async {
          final existingIndex = _metrics.indexWhere(
            (m) =>
                m.date.year == entryDate.year &&
                m.date.month == entryDate.month &&
                m.date.day == entryDate.day,
          );

          if (existingIndex != -1) {
            final existing = _metrics[existingIndex];
            final updated = existing.copyWith(
              photoFrontPath: isFront ? photoPath : existing.photoFrontPath,
              photoSidePath: !isFront ? photoPath : existing.photoSidePath,
            );
            await _box?.put(existing.key, updated);
          } else {
            final weight =
                currentWeight ??
                _settingsProvider.settings.startingWeight ??
                70.0;
            final newMetric = BodyMetric(
              date: entryDate,
              weight: weight,
              photoFrontPath: isFront ? photoPath : null,
              photoSidePath: !isFront ? photoPath : null,
            );
            await _box?.add(newMetric);
          }

          _sortMetrics();
          await _enqueueProgressPhotoUpload(photoPath, entryDate, isFront);
        },
        timeout: TimeoutPolicy.localStorage,
        retryPolicy: RetryPolicy.localStorage,
        isActive: () => isProviderActive,
      );

      _uiState =
          result.isSuccess
              ? (_metrics.isEmpty
                  ? const AsyncUiState.empty()
                  : AsyncUiState.partial(
                      message:
                          'Photo saved locally and will upload in background.',
                      pendingCount: UploadQueueService().pendingCount,
                    ))
              : stateFromFailure(
                  result.failure!,
                  hasFallback: _metrics.isNotEmpty,
                  pendingCount: UploadQueueService().pendingCount,
                );
    } finally {
      finishOperation(opKey);
      notifyListeners();
    }
  }

  Future<void> _enqueueProgressPhotoUpload(
    String photoPath,
    DateTime entryDate,
    bool isFront,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final normalizedDate =
        '${entryDate.year.toString().padLeft(4, '0')}'
        '${entryDate.month.toString().padLeft(2, '0')}'
        '${entryDate.day.toString().padLeft(2, '0')}';
    final side = isFront ? 'front' : 'side';
    final id = 'progress-photo:${user.uid}:$normalizedDate:$side';
    final extension = photoPath.split('.').last.toLowerCase();
    final safeExtension =
        extension == 'png' || extension == 'webp' ? extension : 'jpg';

    await UploadQueueService().enqueueFileUpload(
      id: id,
      localFilePath: photoPath,
      storagePath:
          'users/${user.uid}/progress_photos/'
          '$normalizedDate-$side.$safeExtension',
      metadata: {
        'kind': 'progress_photo',
        'date': normalizedDate,
        'side': side,
      },
    );
  }

  /// Check if user can add a photo based on premium status
  bool get canAddPhoto {
    if (_settingsProvider.isPro) return true;

    // Free tier: 1 photo per month
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;

    final photosThisMonth =
        _metrics
            .where(
              (m) =>
                  (m.photoFrontPath != null || m.photoSidePath != null) &&
                  m.date.month == currentMonth &&
                  m.date.year == currentYear,
            )
            .length;

    return photosThisMonth < 1;
  }

  /// Delete an entry
  Future<void> deleteMetric(String id) async {
    final metric = _metrics.firstWhere((m) => m.id == id);
    await metric.delete();
    _loadMetrics();
  }

  /// Get current weight (latest entry)
  double? get currentWeight {
    if (_metrics.isEmpty) return null;
    return _metrics.first.weight;
  }

  /// Get starting weight (first entry)
  double? get startWeight {
    if (_metrics.isEmpty) return null;
    return _metrics.last.weight; // Since list is sorted newest first
  }

  /// Calculate BMI
  double? get bmi {
    final weight = currentWeight;
    final heightCm = _settingsProvider.settings.height;

    if (weight == null || heightCm == null || heightCm == 0) return null;

    final heightM = heightCm / 100;
    return weight / (heightM * heightM);
  }

  /// Get BMI Category
  String get bmiCategory {
    final val = bmi;
    if (val == null) return 'Unknown';
    if (val < 18.5) return 'Underweight';
    if (val < 25) return 'Normal';
    if (val < 30) return 'Overweight';
    return 'Obese';
  }

  /// Get weight trend data (last 30 days)
  List<BodyMetric> get recentTrend {
    return _metrics.take(30).toList(); // Already sorted newest first
  }

  /// Clear all metrics on logout
  Future<void> clear() async {
    await _box?.clear();
    _metrics = [];
    _uiState = const AsyncUiState.empty();
    notifyListeners();
  }
}
