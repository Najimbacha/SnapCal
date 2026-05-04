import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../../data/services/gemini_service.dart';
import '../../data/services/barcode_service.dart';
import '../../core/utils/image_utils.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/services/scan_gate_service.dart';

import '../../data/services/camera_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

class SnapController extends ChangeNotifier {
  bool _isCapturing = false;
  bool _isAnalyzing = false;
  bool _isScanningBarcode = false;
  FlashMode _flashMode = FlashMode.off;

  Uint8List? _capturedImageBytes;
  List<NutritionResult>? _analysisResults;
  String? _errorMessage;

  final AIService _geminiService = AIService();
  final BarcodeService _barcodeService = BarcodeService();

  SnapController() {
    CameraService().addListener(notifyListeners);
  }

  CameraController? get cameraController => CameraService().controller;
  bool get isInitialized => CameraService().isInitialized;
  bool get isCapturing => _isCapturing;
  bool get isAnalyzing => _isAnalyzing;
  bool get isScanningBarcode => _isScanningBarcode;
  FlashMode get flashMode => _flashMode;
  Uint8List? get capturedImageBytes => _capturedImageBytes;
  List<NutritionResult>? get analysisResults => _analysisResults;
  NutritionResult? get analysisResult => _analysisResults?.isNotEmpty == true ? _analysisResults!.first : null;
  String? get errorMessage => _errorMessage;

  set isScanningBarcode(bool value) {
    if (_isScanningBarcode == value) return;
    _isScanningBarcode = value;
    
    if (_isScanningBarcode) {
      CameraService().stop();
    } else {
      initializeCamera();
    }
    
    notifyListeners();
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
    notifyListeners();
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
    await CameraService().warmup();
    if (CameraService().error != null) {
      _errorMessage = CameraService().error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    CameraService().removeListener(notifyListeners);
    super.dispose();
  }

  Future<void> captureAndAnalyze({
    required BuildContext context,
    required MealProvider mealProvider,
    required SettingsProvider settingsProvider,
    required ConnectivityService connectivity,
    required Function() onShowPaywall,
    required Function() onShowResult,
    required Function() onShowManualInput,
  }) async {
    if (_isCapturing || _isAnalyzing) return;

    if (!connectivity.isOnline) {
      HapticFeedback.vibrate();
      _errorMessage = AppLocalizations.of(context)!.snap_offline_error;
      notifyListeners();
      return;
    }

    if (!ScanGateService().canScan(settingsProvider.isPro)) {
      onShowPaywall();
      return;
    }

    if (CameraService().controller == null ||
        !CameraService().controller!.value.isInitialized) {
      return;
    }

    HapticFeedback.mediumImpact();
    _isCapturing = true;
    _errorMessage = null;
    notifyListeners();

    await ScanGateService().incrementScanCount();

    try {
      final XFile imageFile = await CameraService().controller!.takePicture();
      final bytes = await imageFile.readAsBytes();
      _capturedImageBytes = await ImageUtils.compressImageBytesAsync(bytes);
      
      _isCapturing = false;
      _isAnalyzing = true;
      notifyListeners();

      try {
        final cached = mealProvider.getCachedAnalysis(_capturedImageBytes!);
        if (cached != null) {
          _analysisResults = cached;
        } else {
          _analysisResults = await _geminiService.analyzeFood(
            _capturedImageBytes!,
            language: settingsProvider.languageCode,
          );
          mealProvider.cacheAnalysis(_capturedImageBytes!, _analysisResults!);
        }
        
        _isAnalyzing = false;
        notifyListeners();
        onShowResult();
      } on GeminiException catch (_) {
        _isAnalyzing = false;
        if (!context.mounted) return;
        _errorMessage = AppLocalizations.of(context)!.error_scan_failed;
        notifyListeners();
        onShowManualInput();
      }
    } catch (e) {
      _isCapturing = false;
      _isAnalyzing = false;
      if (!context.mounted) return;
      _errorMessage = AppLocalizations.of(context)!.error_scan_failed;
      notifyListeners();
      onShowManualInput();
    }
  }

  Future<void> pickFromGallery({
    required BuildContext context,
    required MealProvider mealProvider,
    required SettingsProvider settingsProvider,
    required ConnectivityService connectivity,
    required Function() onShowPaywall,
    required Function() onShowResult,
    required Function() onShowManualInput,
  }) async {
    if (_isAnalyzing) return;

    if (!connectivity.isOnline) {
      HapticFeedback.vibrate();
      _errorMessage = AppLocalizations.of(context)!.snap_offline_error;
      notifyListeners();
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
      final bytes = await imageFile.readAsBytes();

      _isAnalyzing = true;
      _errorMessage = null;
      notifyListeners();

      await ScanGateService().incrementScanCount();
      _capturedImageBytes = await ImageUtils.compressImageBytesAsync(bytes);

      try {
        _analysisResults = await _geminiService.analyzeFood(
          _capturedImageBytes!,
          language: settingsProvider.languageCode,
        );
        _isAnalyzing = false;
        notifyListeners();
        onShowResult();
      } on GeminiException catch (_) {
        _isAnalyzing = false;
        if (!context.mounted) return;
        _errorMessage = AppLocalizations.of(context)!.error_scan_failed;
        notifyListeners();
        onShowManualInput();
      }
    } catch (e) {
      _isAnalyzing = false;
      if (!context.mounted) return;
      _errorMessage = AppLocalizations.of(context)!.error_scan_failed;
      notifyListeners();
    }
  }

  Future<void> handleBarcodeDetected(
    String code, {
    required BuildContext context,
    required SettingsProvider settingsProvider,
    required Function() onShowPaywall,
    required Function() onShowResult,
    required Function() onShowManualInput,
  }) async {
    if (_isAnalyzing) return;

    if (!ScanGateService().canScan(settingsProvider.isPro)) {
      isScanningBarcode = false;
      onShowPaywall();
      return;
    }

    isScanningBarcode = false;
    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    await ScanGateService().incrementScanCount();

    try {
      final result = await _barcodeService.fetchProductByBarcode(code);
      if (result != null) {
        _analysisResults = [result];
        _isAnalyzing = false;
        notifyListeners();
        onShowResult();
      } else {
        _isAnalyzing = false;
        if (!context.mounted) return;
        _errorMessage = AppLocalizations.of(context)!.error_barcode_not_found;
        notifyListeners();
        onShowManualInput();
      }
    } catch (e) {
      _isAnalyzing = false;
      if (!context.mounted) return;
      _errorMessage = AppLocalizations.of(context)!.error_scan_failed;
      notifyListeners();
      onShowManualInput();
    }
  }

  void reset() {
    _capturedImageBytes = null;
    _analysisResults = null;
    _errorMessage = null;
    _isAnalyzing = false;
    _isCapturing = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
