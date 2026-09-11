import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_typography.dart';
import '../../core/utils/date_utils.dart' as app_date;
import '../../data/models/meal.dart';
import '../../data/models/user_settings.dart';
import '../../data/services/app_review_service.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/services/gemini_service.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../log/widgets/edit_meal_modal.dart';
import 'snap_controller.dart';
import 'widgets/analyzing_overlay.dart';
import 'widgets/barcode_scanner_view.dart';
import 'widgets/result_modal.dart';
import 'widgets/shutter_button.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import '../../data/services/camera_service.dart';
import '../../router.dart';

enum SnapInitialMode { food, barcode }

enum _ProblemChoice { primary, manual }

class SnapScreen extends ConsumerStatefulWidget {
  final SnapInitialMode initialMode;

  const SnapScreen({super.key, this.initialMode = SnapInitialMode.food});

  @override
  ConsumerState<SnapScreen> createState() => _SnapScreenState();
}

class _SnapScreenState extends ConsumerState<SnapScreen>
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
    _controller = SnapController()..onStateChanged = () => setState(() {});
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

  /// Whether this screen is the one on show and wants the photo camera.
  ///
  /// It lives on in the tab stack while Home or the diary is open, and a
  /// result or the paywall can sit on top of it. Starting the camera from
  /// there switched the hardware -- and the phone's camera-in-use dot -- on
  /// behind a screen that never used it, every time the app came back.
  bool get _cameraWanted =>
      mounted && _isTickerActive && !_controller.isScanningBarcode;

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _focusAnimController?.dispose();
    _controller.onStateChanged = null;
    _controller.dispose();
    CameraService().stop(); // Stop camera when leaving the screen
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_cameraWanted) _controller.initializeCamera();
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
    if (_cameraWanted) _controller.initializeCamera();
  }

  UserSettings get _settings =>
      ref.read(settingsProvider).valueOrNull ?? UserSettings.defaults();

  void _showPaywall() {
    PremiumConversionService().openPaywall(
      context,
      PaywallEntryPoint.scanLimit,
      limitReached: true,
      featureName: 'scan',
    );
  }

  void _capture() {
    _controller.captureAndAnalyze(
      mealProvider: ref.read(mealLogProvider.notifier),
      settingsProvider: _settings,
      isPro: ref.read(effectiveIsProProvider),
      connectivity: ConnectivityService(),
      onShowPaywall: _showPaywall,
      onShowResult: _showResultModal,
      onProblem: _showScanProblem,
    );
  }

  void _pickFromGallery() {
    _controller.pickFromGallery(
      mealProvider: ref.read(mealLogProvider.notifier),
      settingsProvider: _settings,
      isPro: ref.read(effectiveIsProProvider),
      connectivity: ConnectivityService(),
      onShowPaywall: _showPaywall,
      onShowResult: _showResultModal,
      onProblem: _showScanProblem,
    );
  }

  void _retryLastScan() {
    _controller.retryLastScan(
      mealProvider: ref.read(mealLogProvider.notifier),
      settingsProvider: _settings,
      isPro: ref.read(effectiveIsProProvider),
      connectivity: ConnectivityService(),
      onShowPaywall: _showPaywall,
      onShowResult: _showResultModal,
      onProblem: _showScanProblem,
    );
  }

  void _onBarcodeDetected(String code) {
    _controller.handleBarcodeDetected(
      code,
      connectivity: ConnectivityService(),
      onShowResult: _showResultModal,
      onProblem: _showScanProblem,
    );
  }

  void _showResultModal() {
    if (!mounted) return;
    _isSavingResult = false;
    _savedResultFingerprint = null;
    final results = _controller.analysisResults;

    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: true,
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
              onSave:
                  (name, calories, protein, carbs, fat, portion) => _saveMeals([
                    NutritionResult(
                      foodName: name,
                      portion: portion ?? '',
                      calories: calories,
                      protein: protein,
                      carbs: carbs,
                      fat: fat,
                    ),
                  ]),
              onSaveAll: _saveMeals,
              onCancel: _controller.reset,
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// Says why a scan produced nothing, and offers the two ways forward: the
  /// same attempt again, or the manual form.
  Future<void> _showScanProblem(ScanProblem problem) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final fromBarcode = _controller.lastAttemptWasBarcode;
    final canResend =
        !fromBarcode &&
        _controller.canRetryLastPhoto &&
        (problem == ScanProblem.offline ||
            problem == ScanProblem.slow ||
            problem == ScanProblem.failed);

    final (IconData icon, String title, String body) = switch (problem) {
      ScanProblem.offline => (
        LucideIcons.wifiOff,
        l10n.scan_problem_offline_title,
        l10n.scan_problem_offline_body,
      ),
      ScanProblem.slow => (
        LucideIcons.hourglass,
        l10n.scan_problem_slow_title,
        l10n.scan_problem_slow_body,
      ),
      ScanProblem.failed => (
        LucideIcons.alertCircle,
        l10n.scan_problem_failed_title,
        l10n.scan_problem_failed_body,
      ),
      ScanProblem.noFood => (
        LucideIcons.utensilsCrossed,
        l10n.scan_problem_no_food_title,
        l10n.scan_problem_no_food_body,
      ),
      ScanProblem.unreadableImage => (
        LucideIcons.imageOff,
        l10n.scan_problem_image_title,
        l10n.scan_problem_image_body,
      ),
      ScanProblem.barcodeNotFound => (
        LucideIcons.scanLine,
        l10n.scan_problem_barcode_title,
        l10n.scan_problem_barcode_body,
      ),
    };

    final String primaryLabel;
    if (fromBarcode) {
      primaryLabel = l10n.scan_problem_scan_again;
    } else if (canResend) {
      primaryLabel = l10n.common_try_again;
    } else if (problem == ScanProblem.noFood ||
        problem == ScanProblem.unreadableImage) {
      primaryLabel = l10n.result_retake;
    } else {
      primaryLabel = l10n.scan_problem_dismiss;
    }

    final choice = await showModalBottomSheet<_ProblemChoice>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => _ScanProblemSheet(
            icon: icon,
            title: title,
            body: body,
            primaryLabel: primaryLabel,
            manualLabel: l10n.log_add_manually,
            onPrimary: () => Navigator.pop(sheetContext, _ProblemChoice.primary),
            onManual: () => Navigator.pop(sheetContext, _ProblemChoice.manual),
          ),
    );
    if (!mounted) return;

    switch (choice) {
      case _ProblemChoice.primary:
        if (fromBarcode) {
          _controller.isScanningBarcode = true;
        } else if (canResend) {
          _retryLastScan();
        }
      case _ProblemChoice.manual:
        _controller.reset();
        await _openManualEntry();
      case null:
        break;
    }
  }

  /// "Add manually" on the waiting screen: stop waiting on the scan, and go
  /// to the form instead.
  void _manualInsteadOfWaiting() {
    _controller.cancelScan();
    _openManualEntry();
  }

  /// The diary's own manual form, for when a scan is not the way in: no
  /// signal, a failed scan, a product not in the database, or by choice.
  Future<void> _openManualEntry() async {
    if (!mounted) return;
    final now = DateTime.now();
    final draft = Meal(
      id: 'new',
      timestamp: now.millisecondsSinceEpoch,
      dateString: app_date.DateUtils.getDateString(now),
      foodName: '',
      calories: 0,
      macros: Macros.empty(),
      mealType: app_date.DateUtils.suggestedMealType(now),
      portion: '',
    );

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (modalContext) => EditMealModal(
            meal: draft,
            isNew: true,
            onSave: (meal) {
              Navigator.of(modalContext).pop();
              _saveManualMeal(meal);
            },
            onDelete: () => Navigator.of(modalContext).pop(),
            onCancel: () => Navigator.of(modalContext).pop(),
          ),
    );
  }

  Future<void> _saveManualMeal(Meal draft) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final mealNotifier = ref.read(mealLogProvider.notifier);
    final meal = draft.copyWith(id: mealNotifier.generateMealId());

    HapticFeedback.heavyImpact();
    router.go('/');
    try {
      await mealNotifier.addMeal(meal, mealDate: meal.dateString);
    } catch (error) {
      debugPrint('Saving manual meal failed: $error');
      messenger.showSnackBar(SnackBar(content: Text(l10n.meal_save_failed)));
    }
  }

  Future<void> _saveMeals(List<NutritionResult> items) async {
    final fingerprint = _saveFingerprint(items);
    if (!_beginResultSave(fingerprint)) return;

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final mealNotifier = ref.read(mealLogProvider.notifier);
    final router = GoRouter.of(context);
    final now = DateTime.now();
    final dateString = app_date.DateUtils.getDateString(now);
    final unknownFood = l10n.log_unknown_food;

    try {
      final imageUri = await _persistCapturedMealImage(now);
      HapticFeedback.heavyImpact();
      router.go('/');

      for (final item in items) {
        await mealNotifier.addMeal(
          Meal(
            id: mealNotifier.generateMealId(),
            timestamp: DateTime.now().millisecondsSinceEpoch,
            dateString: dateString,
            imageUri: imageUri,
            foodName: item.foodName.isEmpty ? unknownFood : item.foodName,
            calories: item.calories,
            macros: Macros(
              protein: item.protein,
              carbs: item.carbs,
              fat: item.fat,
            ),
            portion: item.portion,
            // The detector's own value when it gave one, and nothing when it
            // did not: this used to be a hardcoded 0.82 on every meal, beside
            // a sentence claiming an estimate that never happened.
            scanConfidence: item.confidence,
            scanSource: 'ai_scan',
            originalCalories: item.calories,
            weightG: item.weightG,
            nutritionMatchId: item.nutritionMatchId,
            nutritionPer100g: item.nutritionPer100g,
          ),
        );
      }

      _controller.reset();
      _askForReviewSoon();
    } catch (error) {
      // Home is already showing; without a word here the meal would simply
      // not be there.
      debugPrint('Saving scanned meal failed: $error');
      _savedResultFingerprint = null;
      messenger.showSnackBar(SnackBar(content: Text(l10n.meal_save_failed)));
    } finally {
      _isSavingResult = false;
    }
  }

  /// The user has just seen a scan work and is back on home with the meal
  /// saved: the moment to ask. AppReviewService decides whether Google Play's
  /// review sheet is actually requested -- enough use, not too soon, never
  /// twice for one version -- and Google decides whether it appears.
  void _askForReviewSoon() {
    unawaited(
      Future<void>.delayed(
        const Duration(milliseconds: 1500),
        AppReviewService.instance().requestReviewIfEligible,
      ),
    );
  }

  bool _beginResultSave(String fingerprint) {
    if (_isSavingResult || _savedResultFingerprint == fingerprint) {
      return false;
    }
    _isSavingResult = true;
    _savedResultFingerprint = fingerprint;
    return true;
  }

  Future<String?> _persistCapturedMealImage(DateTime capturedAt) async {
    final bytes = _controller.capturedImageBytes;
    if (bytes == null || bytes.isEmpty) return null;

    try {
      final root = await getApplicationSupportDirectory();
      final directory = Directory(
        '${root.path}${Platform.pathSeparator}meal_images',
      );
      await directory.create(recursive: true);
      final file = File(
        '${directory.path}${Platform.pathSeparator}meal_${capturedAt.millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(bytes, flush: false);
      return file.path;
    } catch (error) {
      debugPrint('Unable to save meal thumbnail: $error');
      return null;
    }
  }

  String _saveFingerprint(List<NutritionResult> items) {
    final imageKey = _controller.capturedImageBytes?.length ?? 0;
    return [
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
    final l10n = AppLocalizations.of(context)!;
    final topSafe = MediaQuery.of(context).padding.top;
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    const previewH = 16.0;
    const cornerRadius = 28.0;

    final cameraContent = <Widget>[];

    if (_controller.isScanningBarcode) {
      cameraContent.add(
        BarcodeScannerView(
          onBarcodeDetected: _onBarcodeDetected,
          onCancel: () => context.go('/'),
        ),
      );
    } else if (_controller.isInitialized &&
        _controller.cameraController != null) {
      cameraContent.add(
        GestureDetector(
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
              (_controller.cameraController?.value.isInitialized ?? false)
                  ? CameraPreview(
                    _controller.cameraController!,
                    key: ObjectKey(_controller.cameraController),
                  )
                  : const _CameraShimmerSkeleton(),
        ),
      );
    } else if (_controller.cameraProblem != null) {
      final problem = _controller.cameraProblem!;
      final needsPermission = problem == CameraProblem.permission;
      cameraContent.add(
        _StatePanel(
          icon: LucideIcons.cameraOff,
          title: l10n.error_camera,
          body: switch (problem) {
            CameraProblem.slow => l10n.snap_camera_slow,
            CameraProblem.permission => l10n.snap_camera_permission,
            CameraProblem.unavailable => l10n.snap_camera_unavailable,
          },
          actionLabel:
              needsPermission ? l10n.snap_open_settings : l10n.assistant_retry,
          onAction:
              needsPermission
                  ? () => unawaited(openAppSettings())
                  : _controller.initializeCamera,
        ),
      );
    } else {
      cameraContent.add(const _CameraShimmerSkeleton());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // ── Rounded camera preview area ──
          Positioned(
            top: topSafe + 56,
            left: previewH,
            right: previewH,
            bottom: 210 + bottomSafe,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(cornerRadius),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cornerRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 0.5,
                  ),
                ),
                child: Stack(
                  children: [
                    ...cameraContent,
                    // Tap-to-focus ring
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
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom gradient for readability ──
          if (!_controller.isScanningBarcode)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 200,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.60),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Top bar ──
          if (!_controller.isScanningBarcode)
            Positioned(
              top: topSafe + 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/'),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  if (_controller.isInitialized &&
                      _controller.cameraProblem == null)
                    GestureDetector(
                      onTap: _controller.toggleFlash,
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _controller.flashMode == FlashMode.off
                              ? LucideIcons.zapOff
                              : LucideIcons.zap,
                          color:
                              _controller.flashMode == FlashMode.off
                                  ? Colors.white54
                                  : const Color(0xFFFFD700),
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // ── Bottom controls ──
          if (!_controller.isScanningBarcode)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomSafe + 72,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      // Gallery
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickFromGallery,
                          child: _BottomIcon(
                            icon: LucideIcons.image,
                            label: l10n.snap_gallery,
                          ),
                        ),
                      ),
                      // Shutter
                      ShutterButton(
                        onPressed: _capture,
                        isLoading: _controller.isCapturing,
                      ),
                      // Barcode
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _controller.isScanningBarcode = true,
                          child: _BottomIcon(
                            icon: LucideIcons.scanLine,
                            label: l10n.snap_barcode,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // The way in without a photo: the same manual form the
                  // diary uses, where calories can actually be typed.
                  GestureDetector(
                    onTap: _openManualEntry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.pencil,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.log_add_manually,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Analyzing overlay ──
          if (_controller.isAnalyzing)
            Positioned.fill(
              child: AnalyzingOverlay(
                controller: _controller,
                onManualEntry: _manualInsteadOfWaiting,
              ),
            ),
        ],
      ),
    );
  }
}

class _ScanProblemSheet extends StatelessWidget {
  const _ScanProblemSheet({
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.manualLabel,
    required this.onPrimary,
    required this.onManual,
  });

  final IconData icon;
  final String title;
  final String body;
  final String primaryLabel;
  final String manualLabel;
  final VoidCallback onPrimary;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF1C1B1E) : const Color(0xFFFCFCFA);
    final ink = dark ? Colors.white : const Color(0xFF17251F);
    final muted = dark ? Colors.white70 : const Color(0xFF56675D);
    final accent = theme.colorScheme.primary;
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 4,
              decoration: BoxDecoration(
                color: (dark ? Colors.white : Colors.black).withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26, color: accent),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge.copyWith(
                color: ink,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('scan-problem-primary'),
                onPressed: onPrimary,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: buttonShape,
                ),
                child: Text(primaryLabel),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('scan-problem-manual'),
                onPressed: onManual,
                icon: const Icon(LucideIcons.pencil, size: 16),
                label: Text(manualLabel),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: buttonShape,
                ),
              ),
            ),
          ],
        ),
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

class _BottomIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BottomIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xD9FFFFFF),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
