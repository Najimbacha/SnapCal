import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/image_utils.dart';
import '../../data/services/gemini_service.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../paywall/paywall_modal.dart';
import 'widgets/shutter_button.dart';
import 'widgets/analyzing_overlay.dart';
import 'widgets/result_modal.dart';
import 'widgets/barcode_scanner_view.dart';
import '../../data/services/barcode_service.dart';

/// Camera screen for capturing and analyzing food images
class SnapScreen extends StatefulWidget {
  const SnapScreen({super.key});

  @override
  State<SnapScreen> createState() => _SnapScreenState();
}

class _SnapScreenState extends State<SnapScreen>
    with WidgetsBindingObserver, RouteAware {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isAnalyzing = false;
  bool _hasInitializedOnce = false;
  bool _isScanningBarcode = false;
  Uint8List? _capturedImageBytes;
  NutritionResult? _analysisResult;
  String? _errorMessage;

  final AIService _geminiService = AIService();
  final BarcodeService _barcodeService = BarcodeService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Don't initialize camera here - wait until screen is visible
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize camera only on first visible build to avoid blocking main thread
    if (!_hasInitializedOnce) {
      _hasInitializedOnce = true;
      // Use a post-frame callback to avoid blocking the build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initializeCamera();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras available';
        });
        return;
      }

      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize camera';
      });
    }
  }

  Future<void> _captureAndAnalyze() async {
    // Check free tier limit
    final mealProvider = context.read<MealProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    if (!settingsProvider.canAddMeal(mealProvider.todaysMealCount)) {
      _showPaywall();
      return;
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      final bytes = await imageFile.readAsBytes();

      // Compress image
      final compressedBytes = ImageUtils.compressImageBytes(bytes);

      setState(() {
        _capturedImageBytes = compressedBytes;
        _isCapturing = false;
        _isAnalyzing = true;
      });

      // Analyze with Gemini
      try {
        final result = await _geminiService.analyzeFood(compressedBytes);
        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
        });
        _showResultModal();
      } on GeminiException catch (e) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = e.message;
        });
        // Show manual input option
        _showManualInputModal();
      }
    } catch (e) {
      setState(() {
        _isCapturing = false;
        _errorMessage = 'Failed to capture image';
      });
    }
  }

  Future<void> _pickFromGallery() async {
    // Check free tier limit
    final mealProvider = context.read<MealProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    if (!settingsProvider.canAddMeal(mealProvider.todaysMealCount)) {
      _showPaywall();
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

      final bytes = await imageFile.readAsBytes();

      // Compress image
      final compressedBytes = ImageUtils.compressImageBytes(bytes);

      setState(() {
        _capturedImageBytes = compressedBytes;
        _isAnalyzing = true;
      });

      // Analyze with Gemini
      try {
        final result = await _geminiService.analyzeFood(compressedBytes);
        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
        });
        _showResultModal();
      } on GeminiException catch (e) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = e.message;
        });
        // Show manual input option
        _showManualInputModal();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image';
      });
    }
  }

  void _showPaywall() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => PaywallModal(
            onUpgrade: () {
              context.read<SettingsProvider>().upgradeToPro();
              Navigator.pop(context);
            },
            onCancel: () => Navigator.pop(context),
          ),
    );
  }

  void _showResultModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ResultModal(
              imageBytes: _capturedImageBytes,
              result: _analysisResult,
              onSave: _saveMeal,
              onCancel: _cancelCapture,
            ),
          ),
    );
  }

  void _showManualInputModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ResultModal(
              imageBytes: _capturedImageBytes,
              result: null,
              onSave: _saveMeal,
              onCancel: _cancelCapture,
            ),
          ),
    );
  }

  Future<void> _saveMeal(
    String name,
    int calories,
    int protein,
    int carbs,
    int fat,
  ) async {
    Navigator.pop(context); // Close modal

    final mealProvider = context.read<MealProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    await mealProvider.addMeal(
      foodName: name.isEmpty ? 'Unknown Food' : name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      settings: settingsProvider,
    );

    // Update streak
    await settingsProvider.updateStreakOnMealLog();

    // Reset state
    setState(() {
      _capturedImageBytes = null;
      _analysisResult = null;
    });

    // Navigate to home
    if (mounted) {
      context.go('/');
    }
  }

  void _cancelCapture() {
    Navigator.pop(context);
    setState(() {
      _capturedImageBytes = null;
      _analysisResult = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Stack(
        children: [
          // Camera preview
          if (_isScanningBarcode)
            Positioned.fill(
              child: BarcodeScannerView(
                onBarcodeDetected: _handleBarcodeDetected,
                onCancel: () => setState(() => _isScanningBarcode = false),
              ),
            )
          else if (_isInitialized && _cameraController != null)
            Positioned.fill(child: CameraPreview(_cameraController!))
          else if (_errorMessage != null)
            _buildErrorState()
          else
            _buildLoadingState(),

          // Top gradient overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.backgroundColor,
                    context.backgroundColor.withAlpha(0),
                  ],
                ),
              ),
            ),
          ),

          // Header
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Snap Your Food', style: AppTypography.heading2),
                _buildMealCounter(),
              ],
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 40,
                right: 40,
                top: 32,
                bottom: MediaQuery.of(context).padding.bottom + 100,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    context.backgroundColor,
                    context.backgroundColor.withAlpha(0),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Gallery button
                      IconButton(
                        onPressed: _pickFromGallery,
                        icon: const Icon(
                          LucideIcons.image,
                          color: Colors.white,
                          size: 28,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withAlpha(50),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(width: 40),
                      ShutterButton(
                        onPressed: _captureAndAnalyze,
                        isLoading: _isCapturing,
                      ),
                      const SizedBox(width: 40),
                      // Barcode button
                      IconButton(
                        onPressed:
                            () => setState(() => _isScanningBarcode = true),
                        icon: const Icon(
                          LucideIcons.scan,
                          color: Colors.white,
                          size: 28,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withAlpha(50),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isScanningBarcode
                        ? 'Align barcode in the center'
                        : 'Point camera or pick from gallery',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          // Analyzing overlay
          if (_isAnalyzing) const Positioned.fill(child: AnalyzingOverlay()),
        ],
      ),
    );
  }

  Future<void> _handleBarcodeDetected(String code) async {
    setState(() {
      _isScanningBarcode = false;
      _isAnalyzing = true;
    });

    try {
      final result = await _barcodeService.fetchProductByBarcode(code);
      if (result != null) {
        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
        });
        _showResultModal();
      } else {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = "Product not found. Try manual entry.";
        });
        _showManualInputModal();
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = "Barcode error: $e";
      });
      _showManualInputModal();
    }
  }

  Widget _buildMealCounter() {
    return Consumer2<MealProvider, SettingsProvider>(
      builder: (context, mealProvider, settingsProvider, child) {
        final remaining = settingsProvider.getRemainingFreeMeals(
          mealProvider.todaysMealCount,
        );

        if (settingsProvider.isPro) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.crown, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Pro',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.glassBorderColor),
          ),
          child: Text(
            '$remaining snaps left',
            style: AppTypography.labelMedium,
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Loading camera...',
            style: AppTypography.bodyMedium.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.cameraOff,
              size: 64,
              color: context.textSecondaryColor,
            ),
            const SizedBox(height: 24),
            Text('Camera Unavailable', style: AppTypography.heading3),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to access camera',
              style: AppTypography.bodyMedium.copyWith(
                color: context.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeCamera,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
