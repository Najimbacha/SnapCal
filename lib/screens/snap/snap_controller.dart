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
    // Listen to camera service changes so the UI rebuilds when 
    // initialization finishes or flash mode changes.
    CameraService().addListener(notifyListeners);
  }

  // Getters
  CameraController? get cameraController => CameraService().controller;
  bool get isInitialized => CameraService().isInitialized;
  bool get isCapturing => _isCapturing;
  bool get isAnalyzing => _isAnalyzing;
  bool get isScanningBarcode => _isScanningBarcode;
  FlashMode get flashMode => _flashMode;
  Uint8List? get capturedImageBytes => _capturedImageBytes;
  List<NutritionResult>? get analysisResults => _analysisResults;
  /// Backward-compat: first result for single-item flows
  NutritionResult? get analysisResult => _analysisResults?.isNotEmpty == true ? _analysisResults!.first : null;
  String? get errorMessage => _errorMessage;

  set isScanningBarcode(bool value) {
    if (_isScanningBarcode == value) return;
    _isScanningBarcode = value;
    
    // Safety: Ensure hardware is released when switching to barcode
    // and re-initialized when coming back to food scanner.
    if (_isScanningBarcode) {
      CameraService().stop();
    } else {
      initializeCamera();
    }
    
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

  /// Tap-to-focus: set focus and exposure point on the camera
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
    if (!connectivity.isOnline) {
      HapticFeedback.vibrate();
      _errorMessage = 'Working offline. AI analysis requires internet.';
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

    // Increment count because we are starting the AI scan process
    await ScanGateService().incrementScanCount();

    try {
      final timer = Stopwatch()..start();
      
      final XFile imageFile = await CameraService().controller!.takePicture();
      final capturedTime = timer.elapsedMilliseconds;
      debugPrint('📸 SnapController: Captured in ${capturedTime}ms');
      
      final bytes = await imageFile.readAsBytes();
      final readTime = timer.elapsedMilliseconds - capturedTime;
      debugPrint('📂 SnapController: Read in ${readTime}ms');

      // Async Compression
      _capturedImageBytes = await ImageUtils.compressImageBytesAsync(bytes);
      final compressTime = timer.elapsedMilliseconds - (capturedTime + readTime);
      debugPrint('🗜️ SnapController: Compressed in ${compressTime}ms');
      
      _isCapturing = false;
      _isAnalyzing = true;
      notifyListeners();

      try {
        debugPrint('🧠 SnapController: Starting AI Analysis...');
        
        // 1. Check Cache first
        final cached = mealProvider.getCachedAnalysis(_capturedImageBytes!);
        if (cached != null) {
          debugPrint('♻️ SnapController: Using cached analysis results');
          _analysisResults = cached;
        } else {
          // 2. Perform AI Scan
          final aiStartTime = timer.elapsedMilliseconds;
          _analysisResults = await _geminiService.analyzeFood(
            _capturedImageBytes!,
          );
          final aiDuration = timer.elapsedMilliseconds - aiStartTime;
          debugPrint('✅ SnapController: AI finished in ${aiDuration}ms');
          
          // 3. Store in cache
          mealProvider.cacheAnalysis(_capturedImageBytes!, _analysisResults!);
        }
        
        _isAnalyzing = false;
        notifyListeners();
        onShowResult();
      } on GeminiException catch (e) {
        _isAnalyzing = false;
        _errorMessage = 'AI logic check: ${e.message}';
        notifyListeners();
        onShowManualInput();
      }
    } catch (e) {
      _isCapturing = false;
      _errorMessage = 'Scan failed: ${e.toString()}';
      notifyListeners();
      onShowManualInput();
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
    if (!connectivity.isOnline) {
      HapticFeedback.vibrate();
      _errorMessage = 'AI analysis requires internet connection.';
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
    required SettingsProvider settingsProvider,
    required Function() onShowPaywall,
    required Function() onShowResult,
    required Function() onShowManualInput,
  }) async {
    if (!ScanGateService().canScan(settingsProvider.isPro)) {
      isScanningBarcode = false;
      onShowPaywall();
      return;
    }

    isScanningBarcode = false; // Use setter to restart camera
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
    _analysisResults = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
