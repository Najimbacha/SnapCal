import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../../data/services/gemini_service.dart';
import '../../data/services/barcode_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/resilience/retry_policy.dart';
import '../../core/resilience/safe_async.dart';
import '../../core/resilience/timeout_policy.dart';
import '../../core/utils/image_utils.dart';
import '../../data/models/user_settings.dart';
import '../../data/services/connectivity_service.dart';
import '../../providers/meal_provider.dart';
import '../../data/services/scan_gate_service.dart';

import '../../data/services/camera_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

class SnapController {
  VoidCallback? onStateChanged;
  bool _isCapturing = false;
  bool _isAnalyzing = false;
  bool _isScanningBarcode = false;
  FlashMode _flashMode = FlashMode.off;

  Uint8List? _capturedImageBytes;
  List<NutritionResult>? _analysisResults;
  String? _errorMessage;

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
  String? get errorMessage => _errorMessage;

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
    } catch (_) {}
    onStateChanged?.call();
  }

  Future<void> setFocusPoint(Offset point) async {
    try {
      final ctrl = CameraService().controller;
      if (ctrl == null || !ctrl.value.isInitialized) return;
      await ctrl.setFocusPoint(point);
      await ctrl.setExposurePoint(point);
    } catch (_) {}
  }

  Future<void> initializeCamera() async {
    _errorMessage = null;
    await CameraService().warmup().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _errorMessage = 'Camera is taking longer than expected.';
      },
    );
    if (CameraService().error != null) {
      _errorMessage = CameraService().error;
    }
    onStateChanged?.call();
  }

  void dispose() {
    _disposed = true;
    _operationGeneration++;
    onStateChanged = null;
  }

  Future<void> captureAndAnalyze({
    required BuildContext context,
    required MealLog mealProvider,
    required UserSettings settingsProvider,
    required ConnectivityService connectivity,
    required Function() onShowPaywall,
    required Function() onShowResult,
    required Function() onShowManualInput,
  }) async {
    if (_isCapturing || _isAnalyzing) return;
    _isCapturing = true;
    _errorMessage = null;
    onStateChanged?.call();
    final op = ++_operationGeneration;

    final l10n = AppLocalizations.of(context)!;
    final hasInternet = await connectivity.refreshReachability(force: true);
    if (!hasInternet) {
      _isCapturing = false;
      onStateChanged?.call();
      HapticFeedback.vibrate();
      _errorMessage = l10n.snap_offline_error;
      onStateChanged?.call();
      onShowManualInput();
      return;
    }

    if (!ScanGateService().canScan(settingsProvider.isPro)) {
      _isCapturing = false;
      onStateChanged?.call();
      onShowPaywall();
      return;
    }

    if (CameraService().controller == null ||
        !CameraService().controller!.value.isInitialized) {
      _isCapturing = false;
      onStateChanged?.call();
      return;
    }

    HapticFeedback.mediumImpact();

    try {
      final XFile imageFile = await CameraService().controller!
          .takePicture()
          .timeout(TimeoutPolicy.camera);
      if (_disposed || op != _operationGeneration) return;
      final bytes = await imageFile.readAsBytes().timeout(
        TimeoutPolicy.gallery,
      );
      _capturedImageBytes = await ImageUtils.compressImageBytesAsync(bytes);
      if (_capturedImageBytes!.length > AppConstants.maxImageUploadBytes) {
        throw GeminiException('Image is too large to upload safely.');
      }
      if (_disposed || op != _operationGeneration) return;
      _isCapturing = false;
      _isAnalyzing = true;
      onStateChanged?.call();

      try {
        final imageKey = _capturedImageBytes!.hashCode.toString();
        final cached = mealProvider.getCachedAnalysis(imageKey);
        if (cached != null) {
          _analysisResults = cached;
        } else {
          final result = await SafeAsync.run<List<NutritionResult>>(
            label: 'AI food scan',
            operation:
                () => _geminiService.analyzeFood(
                  _capturedImageBytes!,
                  language: settingsProvider.languageCode ?? 'en',
                ),
            timeout: TimeoutPolicy.aiScan,
            retryPolicy: RetryPolicy.ai,
            operationKey: 'snap:cameraScan',
            isActive: () => !_disposed,
          );
          if (result.isFailure) throw GeminiException(result.failure!.message);
          _analysisResults = result.requireData;
          if (_analysisResults!.isEmpty) {
            throw GeminiException('No food detected.');
          }
          mealProvider.cacheAnalysis(imageKey, _analysisResults!);
        }

        if (_disposed || op != _operationGeneration) return;
        await _recordFreeScanIfNeeded(settingsProvider);
        _isAnalyzing = false;
        onStateChanged?.call();
        onShowResult();
      } on GeminiException catch (_) {
        _isAnalyzing = false;
        if (!context.mounted) return;
        _errorMessage = AppLocalizations.of(context)!.error_scan_failed;
        _capturedImageBytes = null;
        onStateChanged?.call();
        onShowManualInput();
      }
    } catch (e) {
      _isCapturing = false;
      _isAnalyzing = false;
      if (!context.mounted) return;
      _errorMessage = AppLocalizations.of(context)!.error_scan_failed;
      _capturedImageBytes = null;
      onStateChanged?.call();
      onShowManualInput();
    }
  }

  Future<void> pickFromGallery({
    required BuildContext context,
    required MealLog mealProvider,
    required UserSettings settingsProvider,
    required ConnectivityService connectivity,
    required Function() onShowPaywall,
    required Function() onShowResult,
    required Function() onShowManualInput,
  }) async {
    if (_isAnalyzing || _isCapturing) return;
    final op = ++_operationGeneration;

    final l10n = AppLocalizations.of(context)!;
    final hasInternet = await connectivity.refreshReachability(force: true);
    if (!hasInternet) {
      HapticFeedback.vibrate();
      _errorMessage = l10n.snap_offline_error;
      onStateChanged?.call();
      onShowManualInput();
      return;
    }

    if (!ScanGateService().canScan(settingsProvider.isPro)) {
      onShowPaywall();
      return;
    }

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? imageFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (imageFile == null) return;

      HapticFeedback.selectionClick();
      final bytes = await imageFile.readAsBytes().timeout(
        TimeoutPolicy.gallery,
      );

      _capturedImageBytes = await ImageUtils.compressImageBytesAsync(bytes);
      if (_capturedImageBytes!.length > AppConstants.maxImageUploadBytes) {
        throw GeminiException('Image is too large to upload safely.');
      }
      if (_disposed || op != _operationGeneration) return;
      _isAnalyzing = true;
      _errorMessage = null;
      onStateChanged?.call();

      try {
        final result = await SafeAsync.run<List<NutritionResult>>(
          label: 'Gallery food scan',
          operation:
              () => _geminiService.analyzeFood(
                _capturedImageBytes!,
                language: settingsProvider.languageCode ?? 'en',
              ),
          timeout: TimeoutPolicy.aiScan,
          retryPolicy: RetryPolicy.ai,
          operationKey: 'snap:galleryScan',
          isActive: () => !_disposed && op == _operationGeneration,
        );
        if (result.isFailure) throw GeminiException(result.failure!.message);
        _analysisResults = result.requireData;
        if (_analysisResults!.isEmpty) {
          throw GeminiException('No food detected.');
        }
        await _recordFreeScanIfNeeded(settingsProvider);
        _isAnalyzing = false;
        onStateChanged?.call();
        onShowResult();
      } on GeminiException catch (_) {
        _isAnalyzing = false;
        if (!context.mounted) return;
        _errorMessage = AppLocalizations.of(context)!.error_scan_failed;
        _capturedImageBytes = null;
        onStateChanged?.call();
        onShowManualInput();
      }
    } catch (e) {
      _isAnalyzing = false;
      if (!context.mounted) return;
      _errorMessage = AppLocalizations.of(context)!.error_scan_failed;
      _capturedImageBytes = null;
      onStateChanged?.call();
      onShowManualInput();
    }
  }

  Future<void> handleBarcodeDetected(
    String code, {
    required BuildContext context,
    required UserSettings settingsProvider,
    required ConnectivityService connectivity,
    required Function() onShowPaywall,
    required Function() onShowResult,
    required Function() onShowManualInput,
  }) async {
    if (_isAnalyzing) return;
    final op = ++_operationGeneration;
    final l10n = AppLocalizations.of(context)!;

    final hasInternet = await connectivity.refreshReachability(force: true);
    if (!hasInternet) {
      isScanningBarcode = false;
      HapticFeedback.vibrate();
      _errorMessage = l10n.snap_offline_error;
      onStateChanged?.call();
      onShowManualInput();
      return;
    }

    // Barcode scanning is free and unrestricted for all users
    isScanningBarcode = false;
    _isAnalyzing = true;
    _errorMessage = null;
    onStateChanged?.call();

    try {
      final lookup = await SafeAsync.run<NutritionResult?>(
        label: 'Barcode lookup',
        operation: () => _barcodeService.fetchProductByBarcode(code),
        timeout: TimeoutPolicy.barcode,
        retryPolicy: RetryPolicy.network,
        operationKey: 'snap:barcode:$code',
        isActive: () => !_disposed && op == _operationGeneration,
      );
      if (lookup.isFailure) throw lookup.failure!;
      final result = lookup.data;
      if (result != null) {
        _analysisResults = [result];
        // Barcode scans are free and do not increment the daily scan limit
        _isAnalyzing = false;
        onStateChanged?.call();
        onShowResult();
      } else {
        _isAnalyzing = false;
        if (!context.mounted) return;
        _errorMessage = l10n.error_barcode_not_found;
        onStateChanged?.call();
        onShowManualInput();
      }
    } catch (e) {
      _isAnalyzing = false;
      if (!context.mounted) return;
      _errorMessage = l10n.error_scan_failed;
      onStateChanged?.call();
      onShowManualInput();
    }
  }

  Future<void> _recordFreeScanIfNeeded(
    UserSettings settingsProvider,
  ) async {
    if (!settingsProvider.isPro) {
      await ScanGateService().incrementScanCount();
    }
  }

  void reset() {
    _capturedImageBytes = null;
    _analysisResults = null;
    _errorMessage = null;
    _isAnalyzing = false;
    _isCapturing = false;
    onStateChanged?.call();
  }

  void clearError() {
    _errorMessage = null;
    onStateChanged?.call();
  }
}
