import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_utils.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/services/gemini_service.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import 'snap_controller.dart';
import 'widgets/analyzing_overlay.dart';
import 'widgets/barcode_scanner_view.dart';
import 'widgets/food_frame_guide.dart';
import 'widgets/multi_result_sheet.dart';
import 'widgets/result_modal.dart';
import 'widgets/shutter_button.dart';
import '../../data/services/scan_gate_service.dart';
import '../../data/services/camera_service.dart';
import '../../router.dart';

class SnapScreen extends StatefulWidget {
  const SnapScreen({super.key});

  @override
  State<SnapScreen> createState() => _SnapScreenState();
}

class _SnapScreenState extends State<SnapScreen>
    with WidgetsBindingObserver, RouteAware, TickerProviderStateMixin {
  late final SnapController _controller;
  bool _hasInitializedOnce = false;
  bool _isTickerActive = true;

  Offset? _focusPoint;
  AnimationController? _focusAnimController;
  Animation<double>? _focusOpacity;
  Animation<double>? _focusScale;

  @override
  void initState() {
    super.initState();
    _controller = SnapController();
    WidgetsBinding.instance.addObserver(this);

    _focusAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _focusOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _focusAnimController!, curve: const Interval(0.5, 1.0)),
    );
    _focusScale = Tween<double>(begin: 1.4, end: 1.0).animate(
      CurvedAnimation(parent: _focusAnimController!, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      routeObserver.subscribe(this, modalRoute as ModalRoute<dynamic>);
    }

    final tickerActive = TickerMode.of(context);
    if (_isTickerActive != tickerActive) {
      _isTickerActive = tickerActive;
      if (!tickerActive) {
        CameraService().stop();
      } else if (_hasInitializedOnce) {
        _controller.initializeCamera();
      }
    }

    if (_hasInitializedOnce) return;
    _hasInitializedOnce = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isTickerActive) _controller.initializeCamera();
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _focusAnimController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.initializeCamera();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      CameraService().stop();
    }
  }

  @override
  void didPushNext() {
    CameraService().stop();
  }

  @override
  void didPopNext() {
    _controller.initializeCamera();
  }

  void _showPaywall() {
    context.push('/paywall', extra: {'limitReached': true});
  }

  void _showResultModal() {
    final results = _controller.analysisResults;

    if (results != null && results.length > 1) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        builder: (context) => MultiResultSheet(
          results: results,
          onSaveAll: _saveMultipleMeals,
          onCancel: _controller.reset,
        ),
      );
    } else {
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
    String? portion,
  ) async {
    // 1. Capture dependencies before popping/navigating
    final mealProvider = context.read<MealProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final router = GoRouter.of(context);
    
    // 2. Close modal immediately
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    
    // 3. Navigate home immediately for that "Snap & Done" feeling
    HapticFeedback.heavyImpact();
    router.go('/'); 

    // 4. Perform database work in background
    await mealProvider.addMeal(
      foodName: name.isEmpty ? 'Unknown Food' : name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      portion: portion,
      settings: settingsProvider,
    );
    await settingsProvider.updateStreakOnMealLog();
    
    // 5. Reset camera controller state for next time
    _controller.reset();
  }

  Future<void> _saveMultipleMeals(List<NutritionResult> selectedItems) async {
    final mealProvider = context.read<MealProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final router = GoRouter.of(context);

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    HapticFeedback.heavyImpact();
    router.go('/');

    final currentMeals = mealProvider.todaysMealCount;
    final maxAllowed = AppConstants.freeTierDailyMealLimit;
    if (!settingsProvider.isPro && (currentMeals + selectedItems.length > maxAllowed)) {
      _showPaywall();
      _controller.reset();
      return;
    }

    for (final item in selectedItems) {
      await mealProvider.addMeal(
        foodName: item.foodName.isEmpty ? 'Unknown Food' : item.foodName,
        calories: item.calories,
        protein: item.protein,
        carbs: item.carbs,
        fat: item.fat,
        portion: item.portion,
        settings: settingsProvider,
      );
    }
    
    await settingsProvider.updateStreakOnMealLog();
    _controller.reset();
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
                            settingsProvider: context.read<SettingsProvider>(),
                            onShowPaywall: _showPaywall,
                            onShowResult: _showResultModal,
                            onShowManualInput: _showManualInputModal,
                          ),
                      onCancel: () => controller.isScanningBarcode = false,
                    ),
                  )
                else if (controller.isInitialized &&
                    controller.cameraController != null)
                  Positioned.fill(
                    child: GestureDetector(
                      onTapUp: (details) {
                        HapticFeedback.selectionClick();
                        final box = context.findRenderObject() as RenderBox;
                        final size = box.size;
                        final point = Offset(
                          details.localPosition.dx / size.width,
                          details.localPosition.dy / size.height,
                        );
                        _controller.setFocusPoint(point);
                        setState(() => _focusPoint = details.localPosition);
                        _focusAnimController?.reset();
                        _focusAnimController?.forward();
                      },
                      child: CameraPreview(controller.cameraController!),
                    ),
                  )
                else if (controller.errorMessage != null)
                  Positioned.fill(
                    child: _StatePanel(
                      icon: LucideIcons.cameraOff,
                      title: 'Camera unavailable',
                      body: controller.errorMessage!,
                      actionLabel: 'Retry',
                      onAction: _controller.initializeCamera,
                    ),
                  )
                else
                  const Positioned.fill(child: _CameraShimmerSkeleton()),

                if (controller.isInitialized &&
                    !controller.isScanningBarcode &&
                    !controller.isAnalyzing &&
                    controller.errorMessage == null)
                  const Positioned.fill(child: FoodFrameGuide()),

                // ── Tap-to-focus ring ──
                if (_focusPoint != null && _focusAnimController != null)
                  AnimatedBuilder(
                    animation: _focusAnimController!,
                    builder: (context, _) {
                      return Positioned(
                        left: _focusPoint!.dx - 30,
                        top: _focusPoint!.dy - 30,
                        child: Opacity(
                          opacity: _focusOpacity?.value ?? 0,
                          child: Transform.scale(
                            scale: _focusScale?.value ?? 1.0,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFFD700),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

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
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                            stops: const [0, 0.4, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                
                if (!controller.isScanningBarcode) ...[
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (controller.isInitialized && controller.errorMessage == null)
                          _flashButton(controller)
                        else
                          const SizedBox(width: 44),
                        _limitPill(),
                      ],
                    ),
                  ),
                  
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.paddingOf(context).bottom + 24,
                        top: 24,
                        left: 24,
                        right: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _statusText(),
                          const SizedBox(height: 24),
                          Row(
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
                        ],
                      ),
                    ),
                  ),
                ],
                if (controller.isAnalyzing)
                  Positioned.fill(
                    child: AnalyzingOverlay(
                      onManualEntry: _showManualInputModal,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _flashButton(SnapController controller) {
    IconData icon;
    bool isActive = false;
    switch (controller.flashMode) {
      case FlashMode.off:
        icon = LucideIcons.zapOff;
        break;
      case FlashMode.auto:
        icon = LucideIcons.zap;
        isActive = true;
        break;
      case FlashMode.always:
        icon = LucideIcons.zap;
        isActive = true;
        break;
      case FlashMode.torch:
        icon = LucideIcons.sun;
        isActive = true;
        break;
    }
    return GestureDetector(
      onTap: controller.toggleFlash,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? const Color(0xFFFFD700).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
        ),
        child: Icon(
          icon,
          color: isActive ? const Color(0xFFFFD700) : Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _limitPill() {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        final scanCount = ScanGateService().getTodayScanCount();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                settingsProvider.isPro
                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: settingsProvider.isPro
                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            settingsProvider.isPro ? '∞ Pro' : '$scanCount/3',
            style: AppTypography.labelSmall.copyWith(
              color: settingsProvider.isPro ? const Color(0xFF10B981) : Colors.white,
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

class _CameraShimmerSkeleton extends StatelessWidget {
  const _CameraShimmerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF121212), // Charcoal base
      highlightColor: const Color(0xFF1E1E1E), // Lighter highlight
      child: Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: 150, 
                height: 12, 
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
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
