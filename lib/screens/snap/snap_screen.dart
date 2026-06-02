import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_typography.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/services/gemini_service.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import 'snap_controller.dart';
import 'widgets/analyzing_overlay.dart';
import 'widgets/barcode_scanner_view.dart';
import 'widgets/food_frame_guide.dart';
import 'widgets/result_modal.dart';
import 'widgets/shutter_button.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import '../../data/services/camera_service.dart';
import '../../router.dart';

enum SnapInitialMode { food, barcode }

class SnapScreen extends StatefulWidget {
  final SnapInitialMode initialMode;

  const SnapScreen({super.key, this.initialMode = SnapInitialMode.food});

  @override
  State<SnapScreen> createState() => _SnapScreenState();
}

class _SnapScreenState extends State<SnapScreen>
    with WidgetsBindingObserver, RouteAware, TickerProviderStateMixin {
  late final SnapController _controller;
  bool _hasInitializedOnce = false;
  bool _isTickerActive = true;
  bool _isSavingResult = false;
  String? _savedResultFingerprint;

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
      CurvedAnimation(
        parent: _focusAnimController!,
        curve: const Interval(0.5, 1.0),
      ),
    );
    _focusScale = Tween<double>(begin: 1.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _focusAnimController!,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant SnapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMode == widget.initialMode) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLaunchMode();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      routeObserver.subscribe(this, modalRoute as ModalRoute<dynamic>);
    }

    final tickerActive = TickerMode.valuesOf(context).enabled;
    if (_isTickerActive != tickerActive) {
      _isTickerActive = tickerActive;
      if (!tickerActive) {
        CameraService().stop();
      } else if (_hasInitializedOnce) {
        _startLaunchMode();
      }
    }

    if (_hasInitializedOnce) return;
    _hasInitializedOnce = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLaunchMode();
    });
  }

  void _startLaunchMode() {
    if (!mounted || !_isTickerActive) return;
    if (widget.initialMode == SnapInitialMode.barcode) {
      _controller.isScanningBarcode = true;
      return;
    }
    if (_controller.isScanningBarcode) {
      _controller.isScanningBarcode = false;
    } else {
      _controller.initializeCamera();
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _focusAnimController?.dispose();
    _controller.dispose();
    CameraService().stop(); // Stop camera when leaving the screen
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.initializeCamera();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
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
    PremiumConversionService().openPaywall(
      context,
      PaywallEntryPoint.scanLimit,
      limitReached: true,
      featureName: 'scan',
    );
  }

  void _showResultModal() {
    if (!mounted) return;
    _isSavingResult = false;
    _savedResultFingerprint = null;
    final results = _controller.analysisResults;

    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.3),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: ResultModal(
              imageBytes: _controller.capturedImageBytes,
              result:
                  results != null && results.length == 1 ? results.first : null,
              results: results != null && results.length > 1 ? results : null,
              onSave: _saveMeal,
              onSaveAll: _saveMultipleMeals,
              onCancel: _controller.reset,
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showManualInputModal() {
    if (!mounted) return;
    _isSavingResult = false;
    _savedResultFingerprint = null;
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.3),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: ResultModal(
              imageBytes: _controller.capturedImageBytes,
              result: null,
              onSave: _saveMeal,
              onSaveAll: _saveMultipleMeals,
              onCancel: _controller.reset,
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
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
    final fingerprint = _singleSaveFingerprint(
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      portion: portion,
    );
    if (!_beginResultSave(fingerprint)) return;

    final mealProvider = context.read<MealProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final router = GoRouter.of(context);

    try {
      HapticFeedback.heavyImpact();
      router.go('/');

      await mealProvider.addMeal(
        foodName:
            name.isEmpty
                ? AppLocalizations.of(context)!.log_unknown_food
                : name,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        portion: portion,
        settings: settingsProvider,
        scanConfidence: 0.82,
        scanSource: 'ai_scan',
        aiRationale:
            'Estimated from the photo, visible portion size, and macro balance. Review the portion before logging.',
        originalCalories: calories,
      );

      _controller.reset();
    } finally {
      _isSavingResult = false;
    }
  }

  Future<void> _saveMultipleMeals(List<NutritionResult> selectedItems) async {
    final fingerprint = _multiSaveFingerprint(selectedItems);
    if (!_beginResultSave(fingerprint)) return;

    final mealProvider = context.read<MealProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final router = GoRouter.of(context);

    try {
      HapticFeedback.heavyImpact();
      router.go('/');

      for (final item in selectedItems) {
        await mealProvider.addMeal(
          foodName:
              item.foodName.isEmpty
                  ? AppLocalizations.of(context)!.log_unknown_food
                  : item.foodName,
          calories: item.calories,
          protein: item.protein,
          carbs: item.carbs,
          fat: item.fat,
          portion: item.portion,
          settings: settingsProvider,
          scanConfidence: 0.82,
          scanSource: 'ai_scan',
          aiRationale:
              'Estimated from the photo, visible portion size, and macro balance. Review the portion before logging.',
          originalCalories: item.calories,
        );
      }

      _controller.reset();
    } finally {
      _isSavingResult = false;
    }
  }

  bool _beginResultSave(String fingerprint) {
    if (_isSavingResult || _savedResultFingerprint == fingerprint) {
      return false;
    }
    _isSavingResult = true;
    _savedResultFingerprint = fingerprint;
    return true;
  }

  String _singleSaveFingerprint({
    required String name,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    required String? portion,
  }) {
    final imageKey = _controller.capturedImageBytes?.length ?? 0;
    return [
      'single',
      imageKey,
      name.trim().toLowerCase(),
      calories,
      protein,
      carbs,
      fat,
      portion?.trim().toLowerCase() ?? '',
    ].join('|');
  }

  String _multiSaveFingerprint(List<NutritionResult> items) {
    final imageKey = _controller.capturedImageBytes?.length ?? 0;
    return [
      'multi',
      imageKey,
      ...items.map(
        (item) => [
          item.foodName.trim().toLowerCase(),
          item.calories,
          item.protein,
          item.carbs,
          item.fat,
          item.portion.trim().toLowerCase(),
        ].join(':'),
      ),
    ].join('|');
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
                            context: context,
                            settingsProvider: context.read<SettingsProvider>(),
                            connectivity: context.read<ConnectivityService>(),
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
                      child:
                          (controller.cameraController?.value.isInitialized ??
                                  false)
                              ? CameraPreview(
                                controller.cameraController!,
                                key: ObjectKey(controller.cameraController),
                              )
                              : const _CameraShimmerSkeleton(),
                    ),
                  )
                else if (controller.errorMessage != null)
                  Positioned.fill(
                    child: _StatePanel(
                      icon: LucideIcons.cameraOff,
                      title: AppLocalizations.of(context)!.error_camera,
                      body: controller.errorMessage!,
                      actionLabel:
                          AppLocalizations.of(context)!.assistant_retry,
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
                              Colors.black.withValues(alpha: 0.35),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.50),
                            ],
                            stops: const [0, 0.35, 1],
                          ),
                        ),
                      ),
                    ),
                  ),

                if (!controller.isScanningBarcode) ...[
                  // Top bar
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Close
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.x, color: Colors.white, size: 18),
                          ),
                        ),
                        // Flash
                        if (controller.isInitialized && controller.errorMessage == null)
                          GestureDetector(
                            onTap: controller.toggleFlash,
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                controller.flashMode == FlashMode.off
                                    ? LucideIcons.zapOff
                                    : LucideIcons.zap,
                                color: controller.flashMode == FlashMode.off
                                    ? Colors.white54
                                    : const Color(0xFFFFD700),
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Bottom controls
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.paddingOf(context).bottom + 20,
                        top: 12,
                        left: 32,
                        right: 32,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Gallery
                          GestureDetector(
                            onTap: () => controller.pickFromGallery(
                              context: context,
                              mealProvider: context.read<MealProvider>(),
                              settingsProvider: context.read<SettingsProvider>(),
                              connectivity: context.read<ConnectivityService>(),
                              onShowPaywall: _showPaywall,
                              onShowResult: _showResultModal,
                              onShowManualInput: _showManualInputModal,
                            ),
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(LucideIcons.image, color: Colors.white, size: 22),
                            ),
                          ),
                          // Shutter
                          ShutterButton(
                            onPressed: () => controller.captureAndAnalyze(
                              context: context,
                              mealProvider: context.read<MealProvider>(),
                              settingsProvider: context.read<SettingsProvider>(),
                              connectivity: context.read<ConnectivityService>(),
                              onShowPaywall: _showPaywall,
                              onShowResult: _showResultModal,
                              onShowManualInput: _showManualInputModal,
                            ),
                            isLoading: controller.isCapturing,
                          ),
                          // Barcode
                          GestureDetector(
                            onTap: () => controller.isScanningBarcode = true,
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(LucideIcons.scan, color: Colors.white, size: 22),
                            ),
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
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 2,
                  ),
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
