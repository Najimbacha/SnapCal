import 'dart:typed_data';
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

import '../../data/services/camera_service.dart';

class SnapController extends ChangeNotifier {
  bool _isCapturing = false;
  bool _isAnalyzing = false;
  bool _isScanningBarcode = false;
  FlashMode _flashMode = FlashMode.off;

  Uint8List? _capturedImageBytes;
  NutritionResult? _analysisResult;
  String? _errorMessage;

  final AIService _geminiService = AIService();
  final BarcodeService _barcodeService = BarcodeService();

  // Getters
  CameraController? get cameraController => CameraService().controller;
  bool get isInitialized => CameraService().isInitialized;
  bool get isCapturing => _isCapturing;
  bool get isAnalyzing => _isAnalyzing;
  bool get isScanningBarcode => _isScanningBarcode;
  FlashMode get flashMode => _flashMode;
  Uint8List? get capturedImageBytes => _capturedImageBytes;
  NutritionResult? get analysisResult => _analysisResult;
  String? get errorMessage => _errorMessage;

  set isScanningBarcode(bool value) {
    _isScanningBarcode = value;
    notifyListeners();
  }

  /// Cycle flash mode: off → auto → always → torch → off
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
    // We don't dispose the global CameraService here to keep it warmed up
    super.dispose();
  }

  Future<void> captureAndAnalyze({
    required MealProvider mealProvider,
    required SettingsProvider settingsProvider,
    required ConnectivityService connectivity,
    required Function() onShowPaywall,
    required Function() onShowResult,
    required Function() onShowManualInput,
  }) async {
    if (!settingsProvider.canAddMeal(mealProvider.todaysMealCount)) {
      onShowPaywall();
      return;
    }

    if (CameraService().controller == null ||
        !CameraService().controller!.value.isInitialized) {
      return;
    }

    if (!connectivity.isOnline) {
      HapticFeedback.vibrate();
      _errorMessage = 'Working offline. AI analysis requires internet.';
      notifyListeners();
      return;
    }

    HapticFeedback.mediumImpact();
    _isCapturing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final XFile imageFile = await CameraService().controller!.takePicture();
      final bytes = await imageFile.readAsBytes();

      // Async Compression
      _capturedImageBytes = await ImageUtils.compressImageBytesAsync(bytes);
      _isCapturing = false;
      _isAnalyzing = true;
      notifyListeners();

      try {
        _analysisResult = await _geminiService.analyzeFood(
          _capturedImageBytes!,
        );
        _isAnalyzing = false;
        notifyListeners();
        onShowResult();
      } on GeminiException catch (e) {
        _isAnalyzing = false;
        _errorMessage = e.message;
        notifyListeners();
        onShowManualInput();
      }
    } catch (e) {
      _isCapturing = false;
      _errorMessage = 'Failed to capture image';
      notifyListeners();
    }
  }

  Future<void> pickFromGallery({
    required MealProvider mealProvider,
    required SettingsProvider settingsProvider,
    required ConnectivityService connectivity,
    required Function() onShowPaywall,
    required Function() onShowResult,
    required Function() onShowManualInput,
  }) async {
    if (!settingsProvider.canAddMeal(mealProvider.todaysMealCount)) {
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

      if (!connectivity.isOnline) {
        HapticFeedback.vibrate();
        _errorMessage = 'AI analysis requires internet connection.';
        notifyListeners();
        return;
      }

      HapticFeedback.selectionClick();
      final bytes = await imageFile.readAsBytes();

      _isAnalyzing = true;
      _errorMessage = null;
      notifyListeners();

      _capturedImageBytes = await ImageUtils.compressImageBytesAsync(bytes);

      try {
        _analysisResult = await _geminiService.analyzeFood(
          _capturedImageBytes!,
        );
        _isAnalyzing = false;
        notifyListeners();
        onShowResult();
      } on GeminiException catch (e) {
        _isAnalyzing = false;
        _errorMessage = e.message;
        notifyListeners();
        onShowManualInput();
      }
    } catch (e) {
      _errorMessage = 'Failed to pick image';
      notifyListeners();
    }
  }

  Future<void> handleBarcodeDetected(
    String code, {
    required Function() onShowResult,
    required Function() onShowManualInput,
  }) async {
    _isScanningBarcode = false;
    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _barcodeService.fetchProductByBarcode(code);
      if (result != null) {
        _analysisResult = result;
        _isAnalyzing = false;
        notifyListeners();
        onShowResult();
      } else {
        _isAnalyzing = false;
        _errorMessage = "Product not found. Try manual entry.";
        notifyListeners();
        onShowManualInput();
      }
    } catch (e) {
      _isAnalyzing = false;
      _errorMessage = "Barcode error: $e";
      notifyListeners();
      onShowManualInput();
    }
  }

  void reset() {
    _capturedImageBytes = null;
    _analysisResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
