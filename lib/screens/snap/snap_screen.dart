import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/services/connectivity_service.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../paywall/paywall_modal.dart';
import 'snap_controller.dart';
import 'widgets/analyzing_overlay.dart';
import 'widgets/barcode_scanner_view.dart';
import 'widgets/food_frame_guide.dart';
import 'widgets/result_modal.dart';
import 'widgets/shutter_button.dart';

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
    if (_hasInitializedOnce) return;
    _hasInitializedOnce = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.initializeCamera();
    });
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
          (context) => ResultModal(
            imageBytes: _controller.capturedImageBytes,
            result: _controller.analysisResult,
            onSave: _saveMeal,
            onCancel: _controller.reset,
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
          (context) => ResultModal(
            imageBytes: _controller.capturedImageBytes,
            result: null,
            onSave: _saveMeal,
            onCancel: _controller.reset,
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
    Navigator.pop(context);
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
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<SnapController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                if (controller.isScanningBarcode)
                  Positioned.fill(
                    child: BarcodeScannerView(
                      onBarcodeDetected:
                          (code) => controller.handleBarcodeDetected(
                            code,
                            onShowResult: _showResultModal,
                            onShowManualInput: _showManualInputModal,
                          ),
                      onCancel: () => controller.isScanningBarcode = false,
                    ),
                  )
                else if (controller.isInitialized &&
                    controller.cameraController != null)
                  Positioned.fill(
                    child: CameraPreview(controller.cameraController!),
                  )
                else if (controller.errorMessage != null)
                  _StatePanel(
                    icon: LucideIcons.cameraOff,
                    title: 'Camera unavailable',
                    body: controller.errorMessage ?? 'Unable to access camera.',
                    actionLabel: 'Retry',
                    onAction: _controller.initializeCamera,
                  )
                else
                  const _StatePanel(
                    icon: LucideIcons.loader,
                    title: 'Loading camera',
                    body: 'Preparing your food scanner.',
                  ),
                if (controller.isInitialized &&
                    !controller.isScanningBarcode &&
                    !controller.isAnalyzing)
                  const Positioned.fill(child: FoodFrameGuide()),
                if (!controller.isScanningBarcode)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                            stops: const [0, 0.4, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!controller.isScanningBarcode) ...[
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 24,
                    left: 24,
                    right: 24,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Snap Meal',
                                style: AppTypography.headlineLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Aim at your food for instant data.',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (controller.isInitialized) _flashButton(controller),
                        const SizedBox(width: 12),
                        _limitPill(),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: MediaQuery.of(context).padding.bottom + 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _statusText(),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1C1E).withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _controlButton(
                                icon: LucideIcons.image,
                                label: 'Gallery',
                                onTap:
                                    () => controller.pickFromGallery(
                                      mealProvider:
                                          context.read<MealProvider>(),
                                      settingsProvider:
                                          context.read<SettingsProvider>(),
                                      connectivity:
                                          context.read<ConnectivityService>(),
                                      onShowPaywall: _showPaywall,
                                      onShowResult: _showResultModal,
                                      onShowManualInput: _showManualInputModal,
                                    ),
                              ),
                              ShutterButton(
                                onPressed:
                                    () => controller.captureAndAnalyze(
                                      mealProvider:
                                          context.read<MealProvider>(),
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
                              _controlButton(
                                icon: LucideIcons.scan,
                                label: 'Barcode',
                                onTap:
                                    () => controller.isScanningBarcode = true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (controller.isAnalyzing)
                  const Positioned.fill(child: AnalyzingOverlay()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _flashButton(SnapController controller) {
    IconData icon = LucideIcons.zapOff;
    switch (controller.flashMode) {
      case FlashMode.off:
        icon = LucideIcons.zapOff;
        break;
      case FlashMode.auto:
      case FlashMode.always:
        icon = LucideIcons.zap;
        break;
      case FlashMode.torch:
        icon = LucideIcons.sun;
        break;
    }
    return _PillButton(
      icon: icon,
      label: 'Flash',
      onTap: controller.toggleFlash,
    );
  }

  Widget _limitPill() {
    return Consumer2<MealProvider, SettingsProvider>(
      builder: (context, mealProvider, settingsProvider, _) {
        final remaining = settingsProvider.getRemainingFreeMeals(
          mealProvider.todaysMealCount,
        );
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:
                settingsProvider.isPro
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            settingsProvider.isPro ? 'Pro Active' : '$remaining left',
            style: AppTypography.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusText() {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        return Text(
          connectivity.isOnline
              ? 'Center the food inside the guide.'
              : 'Offline: AI analysis unavailable.',
          textAlign: TextAlign.center,
          style: AppTypography.labelLarge.copyWith(
            color: connectivity.isOnline ? Colors.white70 : AppColors.error,
            fontWeight:
                connectivity.isOnline ? FontWeight.w500 : FontWeight.w700,
          ),
        );
      },
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label, 
              style: AppTypography.labelLarge.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatePanel({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1C1E),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 48),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTypography.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
