import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../paywall/paywall_modal.dart';
import 'widgets/shutter_button.dart';
import 'widgets/analyzing_overlay.dart';
import 'widgets/result_modal.dart';
import 'widgets/barcode_scanner_view.dart';
import 'widgets/food_frame_guide.dart';
import '../../data/services/connectivity_service.dart';
import 'snap_controller.dart';

/// Camera screen for capturing and analyzing food images
class SnapScreen extends StatefulWidget {
  const SnapScreen({super.key});

  @override
  State<SnapScreen> createState() => _SnapScreenState();
}

class _SnapScreenState extends State<SnapScreen>
    with WidgetsBindingObserver, RouteAware {
  late final SnapController _controller;
  bool _hasInitializedOnce = false;

  @override
  void initState() {
    super.initState();
    _controller = SnapController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedOnce) {
      _hasInitializedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.initializeCamera();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.initializeCamera();
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
              imageBytes: _controller.capturedImageBytes,
              result: _controller.analysisResult,
              onSave: _saveMeal,
              onCancel: _controller.reset,
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
              imageBytes: _controller.capturedImageBytes,
              result: null,
              onSave: _saveMeal,
              onCancel: _controller.reset,
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

    await settingsProvider.updateStreakOnMealLog();
    _controller.reset();

    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<SnapController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: context.backgroundColor,
            body: Stack(
              children: [
                // Camera preview
                if (controller.isScanningBarcode)
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: BarcodeScannerView(
                        onBarcodeDetected:
                            (code) => controller.handleBarcodeDetected(
                              code,
                              onShowResult: _showResultModal,
                              onShowManualInput: _showManualInputModal,
                            ),
                        onCancel: () => controller.isScanningBarcode = false,
                      ),
                    ),
                  )
                else if (controller.isInitialized &&
                    controller.cameraController != null)
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CameraPreview(controller.cameraController!),
                    ),
                  )
                else if (controller.errorMessage != null)
                  _buildErrorState()
                else
                  _buildLoadingState(),

                // Food viewfinder guide (only when camera is active)
                if (controller.isInitialized &&
                    !controller.isScanningBarcode &&
                    !controller.isAnalyzing)
                  const Positioned.fill(child: FoodFrameGuide()),

                // Top gradient overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 140,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Header row
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Snap Your Food',
                        style: AppTypography.heading2.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          // Flash toggle
                          if (controller.isInitialized &&
                              !controller.isScanningBarcode)
                            _buildFlashButton(controller),
                          const SizedBox(width: 8),
                          _buildMealCounter(),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bottom controls area
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      left: 32,
                      right: 32,
                      top: 40,
                      bottom: MediaQuery.of(context).padding.bottom + 40,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: const [0.0, 0.4, 1.0],
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Gallery button
                            _buildControlButton(
                              icon: LucideIcons.image,
                              label: 'Gallery',
                              onTap:
                                  () => controller.pickFromGallery(
                                    mealProvider: context.read<MealProvider>(),
                                    settingsProvider:
                                        context.read<SettingsProvider>(),
                                    connectivity:
                                        context.read<ConnectivityService>(),
                                    onShowPaywall: _showPaywall,
                                    onShowResult: _showResultModal,
                                    onShowManualInput: _showManualInputModal,
                                  ),
                            ),
                            // Shutter button
                            ShutterButton(
                              onPressed:
                                  () => controller.captureAndAnalyze(
                                    mealProvider: context.read<MealProvider>(),
                                    settingsProvider:
                                        context.read<SettingsProvider>(),
                                    connectivity:
                                        context.read<ConnectivityService>(),
                                    onShowPaywall: _showPaywall,
                                    onShowResult: _showResultModal,
                                    onShowManualInput: _showManualInputModal,
                                  ),
                              isLoading: controller.isCapturing,
                            ),
                            // Barcode button
                            _buildControlButton(
                              icon: LucideIcons.scan,
                              label: 'Barcode',
                              onTap: () => controller.isScanningBarcode = true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStatusText(),
                      ],
                    ),
                  ),
                ),

                // Analyzing overlay
                if (controller.isAnalyzing)
                  const Positioned.fill(
                    child: RepaintBoundary(child: AnalyzingOverlay()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Glassmorphic control button with label
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Flash toggle button
  Widget _buildFlashButton(SnapController controller) {
    IconData icon;
    String tooltip;

    switch (controller.flashMode) {
      case FlashMode.off:
        icon = LucideIcons.zapOff;
        tooltip = 'Flash Off';
        break;
      case FlashMode.auto:
        icon = LucideIcons.zap;
        tooltip = 'Flash Auto';
        break;
      case FlashMode.always:
        icon = LucideIcons.zap;
        tooltip = 'Flash On';
        break;
      case FlashMode.torch:
        icon = LucideIcons.sun;
        tooltip = 'Torch';
        break;
    }

    final isActive = controller.flashMode != FlashMode.off;

    return GestureDetector(
      onTap: controller.toggleFlash,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              isActive
                  ? AppColors.primary.withOpacity(0.3)
                  : Colors.white.withOpacity(0.15),
          border: Border.all(
            color:
                isActive
                    ? AppColors.primary.withOpacity(0.5)
                    : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.primary : Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildStatusText() {
    return Consumer2<SnapController, ConnectivityService>(
      builder: (context, controller, connectivity, _) {
        String text = 'Point camera or pick from gallery';
        Color color = Colors.white.withOpacity(0.7);
        FontWeight? weight;

        if (controller.isScanningBarcode) {
          text = 'Align barcode in the center';
        } else if (!connectivity.isOnline) {
          text = '⚠️ Offline: AI features unavailable';
          color = AppColors.error;
          weight = FontWeight.bold;
        }

        return Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            color: color,
            fontWeight: weight,
          ),
        );
      },
    );
  }

  Widget _buildMealCounter() {
    return Consumer2<MealProvider, SettingsProvider>(
      builder: (context, mealProvider, settingsProvider, child) {
        final remaining = settingsProvider.getRemainingFreeMeals(
          mealProvider.todaysMealCount,
        );

        if (settingsProvider.isPro) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.crown, size: 13, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Pro',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Text(
            '$remaining left',
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
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
              _controller.errorMessage ?? 'Unable to access camera',
              style: AppTypography.bodyMedium.copyWith(
                color: context.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _controller.initializeCamera,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
