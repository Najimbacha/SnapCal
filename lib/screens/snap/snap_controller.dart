import 'dart:async';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/services/gemini_service.dart';
import '../../data/services/barcode_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/resilience/app_failure.dart';
import '../../core/resilience/retry_policy.dart';
import '../../core/resilience/safe_async.dart';
import '../../core/resilience/timeout_policy.dart';
import '../../core/utils/image_utils.dart';
import '../../data/models/user_settings.dart';
import '../../data/services/connectivity_service.dart';
import '../../providers/meal_provider.dart';
import '../../data/services/scan_gate_service.dart';

import '../../data/services/camera_service.dart';

/// Why a scan ended without a result, so the screen can say which.
///
/// Every failure used to open the result screen empty -- "Food item, 0 kcal"
/// with nothing to type calories into -- so a phone with no signal looked
/// like a photo with no food, and the only way out was back.
enum ScanProblem { offline, slow, noFood, unreadableImage, barcodeNotFound, failed }

/// Why the camera preview is not showing.
enum CameraProblem { slow, permission, unavailable }

enum _Gate { open, offline, limitReached }

class SnapController {
  VoidCallback? onStateChanged;
  bool _isCapturing = false;
  bool _isAnalyzing = false;
  bool _isScanningBarcode = false;
  bool _lastAttemptWasBarcode = false;
  FlashMode _flashMode = FlashMode.off;

  Uint8List? _capturedImageBytes;
  List<NutritionResult>? _analysisResults;
  CameraProblem? _cameraProblem;

  final AIService _geminiService = AIService();
  final BarcodeService _barcodeService = BarcodeService();
  int _operationGeneration = 0;
  bool _disposed = false;

  SnapController();

  CameraController? get cameraController => CameraService().controller;
  bool get isInitialized => CameraService().isInitialized;
  bool get isCapturing => _isCapturing;
  bool get isAnalyzing => _isAnalyzing;
  bool get isScanningBarcode => _isScanningBarcode;
  FlashMode get flashMode => _flashMode;
  Uint8List? get capturedImageBytes => _capturedImageBytes;
  List<NutritionResult>? get analysisResults => _analysisResults;
  NutritionResult? get analysisResult =>
      _analysisResults?.isNotEmpty == true ? _analysisResults!.first : null;
  CameraProblem? get cameraProblem => _cameraProblem;

  /// Whether the last attempt was a barcode, so a problem offers "Scan again"
  /// rather than a photo retry.
  bool get lastAttemptWasBarcode => _lastAttemptWasBarcode;

  /// A photo is kept from a scan that failed on the connection, so "Try
  /// again" can resend it without a retake once the signal is back.
  bool get canRetryLastPhoto =>
      !_lastAttemptWasBarcode &&
      _capturedImageBytes != null &&
      !_isCapturing &&
      !_isAnalyzing;

  set isScanningBarcode(bool value) {
    if (_isScanningBarcode == value) return;
    _isScanningBarcode = value;

    if (_isScanningBarcode) {
      CameraService().stop();
    } else {
      initializeCamera();
    }

    onStateChanged?.call();
  }

  Future<void> toggleFlash() async {
    final modes = [
      FlashMode.off,
      FlashMode.auto,
      FlashMode.always,
      FlashMode.torch,
    ];
    final nextIndex = (modes.indexOf(_flashMode) + 1) % modes.length;
    _flashMode = modes[nextIndex];

    try {
      await CameraService().controller?.setFlashMode(_flashMode);
    } catch (e) {
      debugPrint('Flash toggle unavailable: $e');
    }
    onStateChanged?.call();
  }

  Future<void> setFocusPoint(Offset point) async {
    try {
      final ctrl = CameraService().controller;
      if (ctrl == null || !ctrl.value.isInitialized) return;
      await ctrl.setFocusPoint(point);
      await ctrl.setExposurePoint(point);
    } catch (e) {
      debugPrint('Focus/exposure not supported here: $e');
    }
  }

  Future<void> initializeCamera() async {
    _cameraProblem = null;
    final warmup = CameraService().warmup();
    var slow = false;
    await warmup.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        slow = true;
      },
    );
    if (_disposed) return;
    if (slow) {
      _cameraProblem = CameraProblem.slow;
      onStateChanged?.call();
      // The warm-up carries on past the timeout. Without this the "taking
      // longer" panel stayed up after the camera was ready, until something
      // else happened to rebuild the screen.
      unawaited(warmup.then((_) => _settleCameraProblem()));
      return;
    }
    await _settleCameraProblem();
  }

  Future<void> _settleCameraProblem() async {
    if (_disposed) return;
    if (CameraService().error == null) {
      _cameraProblem = null;
    } else {
      final status = await Permission.camera.status;
      if (_disposed) return;
      _cameraProblem =
          status.isGranted ? CameraProblem.unavailable : CameraProblem.permission;
    }
    onStateChanged?.call();
  }

  void dispose() {
    _disposed = true;
    _operationGeneration++;
    onStateChanged = null;
  }

  bool _isCurrent(int op) => !_disposed && op == _operationGeneration;

  /// Stops waiting on a scan in flight, for "Add manually" on the waiting
  /// screen. The request finishes in the background and its answer is
  /// ignored.
  void cancelScan() {
    _operationGeneration++;
    _isCapturing = false;
    _isAnalyzing = false;
    _capturedImageBytes = null;
    onStateChanged?.call();
  }

  /// What a scan's failure means to the person holding the phone.
  @visibleForTesting
  static ScanProblem problemFor(AppFailure failure) {
    switch (failure.type) {
      case AppFailureType.offline:
        return ScanProblem.offline;
      case AppFailureType.timeout:
        return ScanProblem.slow;
      default:
        return failure.rawError is UnsupportedImageException
            ? ScanProblem.unreadableImage
            : ScanProblem.failed;
    }
  }

  Future<_Gate> _gate(ConnectivityService connectivity, bool isPro) async {
    if (!await connectivity.refreshReachability(force: true)) {
      return _Gate.offline;
    }
    if (!ScanGateService().canScan(isPro)) return _Gate.limitReached;
    return _Gate.open;
  }

  void _reportGate(
    _Gate gate,
    VoidCallback onShowPaywall,
    void Function(ScanProblem problem) onProblem,
  ) {
    if (gate == _Gate.offline) {
      HapticFeedback.vibrate();
      onProblem(ScanProblem.offline);
    } else if (gate == _Gate.limitReached) {
      onShowPaywall();
    }
  }

  /// Ends an attempt with [problem], unless it has been overtaken.
  void _endAttempt(
    int op,
    ScanProblem problem,
    void Function(ScanProblem problem) onProblem,
  ) {
    if (!_isCurrent(op)) return;
    _isCapturing = false;
    _isAnalyzing = false;
    if (problem == ScanProblem.unreadableImage ||
        problem == ScanProblem.noFood) {
      // Not worth resending: the answer would be the same.
      _capturedImageBytes = null;
    }
    onStateChanged?.call();
    onProblem(problem);
  }

  /// Compresses a photo for upload. Throws [UnsupportedImageException] when it
  /// cannot be read, or is still too large to send.
  Future<Uint8List> _prepare(Uint8List bytes) async {
    final compressed = await ImageUtils.compressImageBytesAsync(bytes);
    if (compressed == null ||
        compressed.length > AppConstants.maxImageUploadBytes) {
      throw const UnsupportedImageException();
    }
    return compressed;
  }

  Future<void> captureAndAnalyze({
    required MealLog mealProvider,
    required UserSettings settingsProvider,
    required bool isPro,
    required ConnectivityService connectivity,
    required VoidCallback onShowPaywall,
    required VoidCallback onShowResult,
    required void Function(ScanProblem problem) onProblem,
  }) async {
    if (_isCapturing || _isAnalyzing) return;
    final op = ++_operationGeneration;
    _lastAttemptWasBarcode = false;
    _capturedImageBytes = null;
    _isCapturing = true;
    onStateChanged?.call();

    final gate = await _gate(connectivity, isPro);
    if (!_isCurrent(op)) return;
    final camera = CameraService().controller;
    if (gate != _Gate.open || camera == null || !camera.value.isInitialized) {
      _isCapturing = false;
      onStateChanged?.call();
      _reportGate(gate, onShowPaywall, onProblem);
      return;
    }

    HapticFeedback.mediumImpact();

    try {
      final XFile imageFile = await camera.takePicture().timeout(
        TimeoutPolicy.camera,
      );
      if (!_isCurrent(op)) return;
      final bytes = await imageFile.readAsBytes().timeout(
        TimeoutPolicy.gallery,
      );
      _capturedImageBytes = await _prepare(bytes);
    } on UnsupportedImageException {
      _endAttempt(op, ScanProblem.unreadableImage, onProblem);
      return;
    } catch (e) {
      debugPrint('Camera capture failed: $e');
      _endAttempt(op, ScanProblem.failed, onProblem);
      return;
    }
    if (!_isCurrent(op)) return;

    await _analyze(
      op: op,
      label: 'AI food scan',
      mealProvider: mealProvider,
      settings: settingsProvider,
      isPro: isPro,
      onShowPaywall: onShowPaywall,
      onShowResult: onShowResult,
      onProblem: onProblem,
    );
  }

  Future<void> pickFromGallery({
    required MealLog mealProvider,
    required UserSettings settingsProvider,
    required bool isPro,
    required ConnectivityService connectivity,
    required VoidCallback onShowPaywall,
    required VoidCallback onShowResult,
    required void Function(ScanProblem problem) onProblem,
  }) async {
    if (_isAnalyzing || _isCapturing) return;
    final op = ++_operationGeneration;
    _lastAttemptWasBarcode = false;
    _capturedImageBytes = null;

    final gate = await _gate(connectivity, isPro);
    if (!_isCurrent(op)) return;
    if (gate != _Gate.open) {
      _reportGate(gate, onShowPaywall, onProblem);
      return;
    }

    try {
      final XFile? imageFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (imageFile == null || !_isCurrent(op)) return;

      HapticFeedback.selectionClick();
      final bytes = await imageFile.readAsBytes().timeout(
        TimeoutPolicy.gallery,
      );
      _capturedImageBytes = await _prepare(bytes);
    } on UnsupportedImageException {
      _endAttempt(op, ScanProblem.unreadableImage, onProblem);
      return;
    } catch (e) {
      debugPrint('Gallery pick failed: $e');
      _endAttempt(op, ScanProblem.unreadableImage, onProblem);
      return;
    }
    if (!_isCurrent(op)) return;

    await _analyze(
      op: op,
      label: 'Gallery food scan',
      mealProvider: mealProvider,
      settings: settingsProvider,
      isPro: isPro,
      onShowPaywall: onShowPaywall,
      onShowResult: onShowResult,
      onProblem: onProblem,
    );
  }

  /// Sends the photo from a scan that failed on the connection again.
  Future<void> retryLastScan({
    required MealLog mealProvider,
    required UserSettings settingsProvider,
    required bool isPro,
    required ConnectivityService connectivity,
    required VoidCallback onShowPaywall,
    required VoidCallback onShowResult,
    required void Function(ScanProblem problem) onProblem,
  }) async {
    if (!canRetryLastPhoto) return;
    final op = ++_operationGeneration;
    // The waiting screen, while the connection is checked.
    _isAnalyzing = true;
    onStateChanged?.call();

    final gate = await _gate(connectivity, isPro);
    if (!_isCurrent(op)) return;
    if (gate != _Gate.open) {
      _isAnalyzing = false;
      onStateChanged?.call();
      _reportGate(gate, onShowPaywall, onProblem);
      return;
    }

    await _analyze(
      op: op,
      label: 'Retried food scan',
      mealProvider: mealProvider,
      settings: settingsProvider,
      isPro: isPro,
      onShowPaywall: onShowPaywall,
      onShowResult: onShowResult,
      onProblem: onProblem,
    );
  }

  Future<void> _analyze({
    required int op,
    required String label,
    required MealLog mealProvider,
    required UserSettings settings,
    required bool isPro,
    required VoidCallback onShowPaywall,
    required VoidCallback onShowResult,
    required void Function(ScanProblem problem) onProblem,
  }) async {
    final bytes = _capturedImageBytes;
    if (bytes == null) return;
    _isCapturing = false;
    _isAnalyzing = true;
    onStateChanged?.call();

    final imageKey = bytes.hashCode.toString();
    var items = mealProvider.getCachedAnalysis(imageKey);
    if (items == null) {
      final result = await SafeAsync.run<List<NutritionResult>>(
        label: label,
        operation:
            () => _geminiService.analyzeFood(
              bytes,
              language: settings.languageCode ?? 'en',
            ),
        timeout: TimeoutPolicy.aiScan,
        retryPolicy: RetryPolicy.ai,
        // One key per attempt: a scan abandoned for manual entry may still be
        // in flight, and a shared key would turn the next scan away as
        // "already running".
        operationKey: 'snap:scan:$op',
        isActive: () => _isCurrent(op),
      );
      if (!_isCurrent(op)) return;

      if (result.isFailure) {
        final failure = result.failure!;
        if (failure.type == AppFailureType.cancelled) {
          _isAnalyzing = false;
          onStateChanged?.call();
          return;
        }
        // Free-tier monthly limit hit (HTTP 402): this is the moment of
        // highest intent — show the paywall, not an error.
        if (failure.type == AppFailureType.quotaExceeded) {
          _isAnalyzing = false;
          _capturedImageBytes = null;
          onStateChanged?.call();
          onShowPaywall();
          return;
        }
        _endAttempt(op, problemFor(failure), onProblem);
        return;
      }

      items = result.requireData;
      if (items.isEmpty) {
        _endAttempt(op, ScanProblem.noFood, onProblem);
        return;
      }
      mealProvider.cacheAnalysis(imageKey, items);
    }

    _analysisResults = items;
    await _recordFreeScanIfNeeded(isPro);
    if (!_isCurrent(op)) return;
    _isAnalyzing = false;
    onStateChanged?.call();
    onShowResult();
  }

  Future<void> handleBarcodeDetected(
    String code, {
    required ConnectivityService connectivity,
    required VoidCallback onShowResult,
    required void Function(ScanProblem problem) onProblem,
  }) async {
    if (_isAnalyzing) return;
    final op = ++_operationGeneration;
    _lastAttemptWasBarcode = true;
    _capturedImageBytes = null;

    final hasInternet = await connectivity.refreshReachability(force: true);
    if (!_isCurrent(op)) return;
    if (!hasInternet) {
      isScanningBarcode = false;
      HapticFeedback.vibrate();
      onProblem(ScanProblem.offline);
      return;
    }

    // Barcode scanning is free and unrestricted for all users
    isScanningBarcode = false;
    _isAnalyzing = true;
    onStateChanged?.call();

    final lookup = await SafeAsync.run<NutritionResult?>(
      label: 'Barcode lookup',
      operation: () => _barcodeService.fetchProductByBarcode(code),
      timeout: TimeoutPolicy.barcode,
      retryPolicy: RetryPolicy.network,
      operationKey: 'snap:barcode:$code',
      isActive: () => _isCurrent(op),
    );
    if (!_isCurrent(op)) return;

    if (lookup.isFailure) {
      final failure = lookup.failure!;
      if (failure.type == AppFailureType.cancelled) {
        _isAnalyzing = false;
        onStateChanged?.call();
        return;
      }
      final problem =
          failure.type == AppFailureType.notFound
              ? ScanProblem.barcodeNotFound
              : problemFor(failure);
      _endAttempt(
        op,
        problem == ScanProblem.unreadableImage ? ScanProblem.failed : problem,
        onProblem,
      );
      return;
    }

    final result = lookup.data;
    if (result == null) {
      _endAttempt(op, ScanProblem.barcodeNotFound, onProblem);
      return;
    }
    _analysisResults = [result];
    // Barcode scans are free and do not increment the monthly scan limit
    _isAnalyzing = false;
    onStateChanged?.call();
    onShowResult();
  }

  Future<void> _recordFreeScanIfNeeded(bool isPro) async {
    if (!isPro) {
      await ScanGateService().incrementScanCount();
    }
  }

  void reset() {
    _capturedImageBytes = null;
    _analysisResults = null;
    _isAnalyzing = false;
    _isCapturing = false;
    onStateChanged?.call();
  }
}
