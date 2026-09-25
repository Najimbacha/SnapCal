import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/wazn_icons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/resilience/app_failure.dart';
import '../../core/resilience/retry_policy.dart';
import '../../core/resilience/safe_async.dart';
import '../../core/resilience/timeout_policy.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_utils.dart' as app_date;
import '../../data/models/meal.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/app_review_service.dart';
import '../../data/services/gemini_service.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../data/services/speech_recognition_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../snap/widgets/result_modal.dart';
import '../../widgets/motion/reveal.dart';

enum _VoicePhase { ready, listening, analyzing }

class VoiceMealScreen extends ConsumerStatefulWidget {
  const VoiceMealScreen({super.key});

  @override
  ConsumerState<VoiceMealScreen> createState() => _VoiceMealScreenState();
}

class _VoiceMealScreenState extends ConsumerState<VoiceMealScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  /// How far along the Analyze button's fill is: it creeps towards the end
  /// while the meal is worked out, and fills the rest when it is done.
  late final AnimationController _fill;
  bool _analyzed = false;
  final _transcriptController = TextEditingController();
  final _focusNode = FocusNode();
  final _speech = SpeechRecognitionService();
  final _ai = AIService();
  final _analytics = AnalyticsService();

  _VoicePhase _phase = _VoicePhase.ready;
  Timer? _countdown;
  int _secondsLeft = 30;
  double _soundLevel = 0;
  bool _speechInitialized = false;
  bool _speechUnavailable = false;
  bool _permanentlyDenied = false;
  bool _saving = false;
  String? _error;

  bool get _isListening => _phase == _VoicePhase.listening;
  bool get _isAnalyzing => _phase == _VoicePhase.analyzing;
  bool get _canAnalyze =>
      !_isAnalyzing &&
      !_isListening &&
      _transcriptController.text.trim().length >= 2;

  @override
  void initState() {
    super.initState();
    _fill = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _isListening) {
      unawaited(_cancelListening());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdown?.cancel();
    unawaited(_speech.cancel());
    _transcriptController.dispose();
    _focusNode.dispose();
    _fill.dispose();
    super.dispose();
  }

  Future<void> _startListening({bool clearFirst = false}) async {
    if (_isAnalyzing || _isListening) return;
    _focusNode.unfocus();
    if (clearFirst) _transcriptController.clear();
    setState(() {
      _error = null;
      _permanentlyDenied = false;
    });

    var permission = await Permission.microphone.status;
    if (!permission.isGranted) {
      permission = await Permission.microphone.request();
    }
    if (!mounted) return;
    if (!permission.isGranted) {
      setState(() {
        _permanentlyDenied = permission.isPermanentlyDenied;
        _error = AppLocalizations.of(context)!.voice_permission_denied;
      });
      return;
    }

    if (!_speechInitialized) {
      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
      if (!mounted) return;
      _speechInitialized = available;
      _speechUnavailable = !available;
      if (!available) {
        setState(
          () => _error = AppLocalizations.of(context)!.voice_unavailable,
        );
        return;
      }
    }

    final languageCode = Localizations.localeOf(context).languageCode;
    final localeId = await _speech.bestLocaleFor(languageCode);
    if (!mounted) return;

    setState(() {
      _phase = _VoicePhase.listening;
      _secondsLeft = 30;
      _soundLevel = 0;
    });
    _startCountdown();
    HapticFeedback.mediumImpact();
    _analytics.logEvent(
      'voice_log_started',
      parameters: {'language': languageCode},
    );

    try {
      await _speech.listen(
        localeId: localeId,
        onWords: _onSpeechWords,
        onSoundLevel: _onSoundLevel,
      );
    } catch (_) {
      if (!mounted) return;
      _finishListening(error: AppLocalizations.of(context)!.voice_unavailable);
    }
  }

  void _startCountdown() {
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isListening) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        unawaited(_stopListening());
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _onSpeechWords(String words, bool isFinal) {
    if (!mounted || words.trim().isEmpty) return;
    final limited = words.trim().characters.take(500).toString();
    _transcriptController.value = TextEditingValue(
      text: limited,
      selection: TextSelection.collapsed(offset: limited.length),
    );
    setState(() => _error = null);
    if (isFinal) _finishListening();
  }

  void _onSoundLevel(double level) {
    if (!mounted || !_isListening) return;
    // Native recognizers use different ranges. A bounded relative value is
    // enough for responsive bars without presenting it as a measurement.
    setState(() => _soundLevel = (level.abs() / 12).clamp(0.08, 1));
  }

  void _onSpeechStatus(String status) {
    if (!mounted || !_isListening) return;
    if (status == 'done' || status == 'notListening') {
      _finishListening();
    }
  }

  void _onSpeechError(String message, bool permanent) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final noSpeech = message.contains('no_match') || message.contains('speech');
    _finishListening(
      error: noSpeech ? l10n.voice_no_speech : l10n.voice_unavailable,
    );
  }

  void _finishListening({String? error}) {
    _countdown?.cancel();
    if (!mounted) return;
    setState(() {
      _phase = _VoicePhase.ready;
      _soundLevel = 0;
      if (error != null) _error = error;
      if (_transcriptController.text.trim().isEmpty && error == null) {
        _error = AppLocalizations.of(context)!.voice_no_speech;
      }
    });
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;
    await _speech.stop();
    _finishListening();
  }

  Future<void> _cancelListening() async {
    _countdown?.cancel();
    await _speech.cancel();
    if (!mounted) return;
    setState(() {
      _phase = _VoicePhase.ready;
      _soundLevel = 0;
    });
  }

  Future<void> _analyze() async {
    if (!_canAnalyze) return;
    final l10n = AppLocalizations.of(context)!;
    final transcript = _transcriptController.text.trim();
    _focusNode.unfocus();
    setState(() {
      _phase = _VoicePhase.analyzing;
      _error = null;
      _analyzed = false;
    });
    if (!AppMotion.reduceMotion(context)) {
      unawaited(
        _fill.animateTo(
          .9,
          duration: const Duration(seconds: 7),
          curve: Curves.easeOutCubic,
        ),
      );
    }

    final language =
        ref.read(settingsProvider).valueOrNull?.languageCode ??
        Localizations.localeOf(context).languageCode;
    final result = await SafeAsync.run<List<NutritionResult>>(
      label: 'Voice meal analysis',
      operation: () => _ai.analyzeMealText(transcript, language: language),
      timeout: TimeoutPolicy.aiScan,
      retryPolicy: RetryPolicy.ai,
      operationKey: 'voice-meal-analysis',
      isActive: () => mounted,
    );
    if (!mounted) return;

    if (result.isFailure) {
      final failure = result.failure!;
      _fill.value = 0;
      setState(() => _phase = _VoicePhase.ready);
      _analytics.logEvent(
        'voice_log_failed',
        parameters: {'reason': failure.type.name},
      );
      if (failure.type == AppFailureType.quotaExceeded &&
          failure.statusCode == 402) {
        PremiumConversionService().openPaywall(
          context,
          PaywallEntryPoint.scanLimit,
          limitReached: true,
          featureName: 'voice_scan',
        );
        return;
      }
      setState(() => _error = l10n.voice_analysis_failed);
      return;
    }

    final items = result.requireData;
    if (items.isEmpty) {
      _fill.value = 0;
      setState(() {
        _phase = _VoicePhase.ready;
        _error = l10n.voice_no_food;
      });
      return;
    }
    // The fill completes and a tick lands before the meal opens.
    if (!AppMotion.reduceMotion(context)) {
      await _fill.animateTo(1, duration: const Duration(milliseconds: 250));
      if (!mounted) return;
      setState(() => _analyzed = true);
      await Future<void>.delayed(const Duration(milliseconds: 380));
      if (!mounted) return;
    }
    _fill.value = 0;
    setState(() {
      _phase = _VoicePhase.ready;
      _analyzed = false;
    });

    _analytics.logEvent(
      'voice_log_analyzed',
      parameters: {'item_count': items.length, 'language': language},
    );
    _showResult(items);
  }

  void _showResult(List<NutritionResult> items) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: true,
        barrierDismissible: false,
        pageBuilder:
            (context, animation, secondaryAnimation) => FadeTransition(
              opacity: animation,
              child: ResultModal(
                results: items,
                onSave:
                    (name, calories, protein, carbs, fat, portion) =>
                        _saveMeals([
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
                // Retake returns to the editable transcript instead of
                // reopening the microphone without consent.
                onCancel: () {},
              ),
            ),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  Future<void> _saveMeals(List<NutritionResult> items) async {
    if (_saving) return;
    _saving = true;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final mealNotifier = ref.read(mealLogProvider.notifier);
    final now = DateTime.now();
    final dateString = app_date.DateUtils.getDateString(now);

    HapticFeedback.heavyImpact();
    router.go('/');
    try {
      for (final item in items) {
        await mealNotifier.addMeal(
          Meal(
            id: mealNotifier.generateMealId(),
            timestamp: DateTime.now().millisecondsSinceEpoch,
            dateString: dateString,
            foodName:
                item.foodName.trim().isEmpty
                    ? l10n.log_unknown_food
                    : item.foodName,
            calories: item.calories,
            macros: Macros(
              protein: item.protein,
              carbs: item.carbs,
              fat: item.fat,
            ),
            portion: item.portion,
            scanConfidence: item.confidence,
            scanSource: 'voice_scan',
            originalCalories: item.calories,
            weightG: item.weightG,
            nutritionMatchId: item.nutritionMatchId,
            nutritionPer100g: item.nutritionPer100g,
          ),
        );
      }
      _analytics.logEvent(
        'voice_log_saved',
        parameters: {'item_count': items.length},
      );
      unawaited(
        Future<void>.delayed(
          const Duration(milliseconds: 1500),
          AppReviewService.instance().requestReviewIfEligible,
        ),
      );
    } catch (error) {
      debugPrint('Saving voice meal failed: $error');
      messenger.showSnackBar(SnackBar(content: Text(l10n.meal_save_failed)));
    } finally {
      _saving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final surface = dark ? AppColors.darkBackground : AppColors.lightBackground;
    final card = dark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = dark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryText =
        dark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final border =
        dark ? Colors.white.withValues(alpha: 0.09) : AppColors.lightCardBorder;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _isListening) unawaited(_speech.cancel());
      },
      child: Scaffold(
        backgroundColor: surface,
        appBar: AppBar(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 64,
          leading: IconButton(
            key: const ValueKey('voice-close'),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => context.pop(),
            style: IconButton.styleFrom(
              backgroundColor: card,
              side: BorderSide(color: border),
            ),
            icon: const Icon(WaznIcons.close, size: 20),
          ),
          titleSpacing: 8,
          title: Text(
            l10n.voice_log_title,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          centerTitle: false,
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder:
                (context, constraints) => SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(20, 10, 20, 24 + bottomInset),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 40).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.voice_heading,
                          style: AppTypography.headlineSmall.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.voice_subtitle,
                          style: AppTypography.bodyMedium.copyWith(
                            color: secondaryText,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border),
                          ),
                          child: _MicControl(
                            listening: _isListening,
                            analyzing: _isAnalyzing,
                            soundLevel: _soundLevel,
                            secondsLeft: _secondsLeft,
                            onTap:
                                _isAnalyzing
                                    ? null
                                    : _isListening
                                    ? _stopListening
                                    : _startListening,
                            readyLabel: l10n.voice_tap_to_speak,
                            listeningLabel: l10n.voice_listening,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.voice_transcript_label,
                          style: AppTypography.titleSmall.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Stack(
                          children: [
                            TextField(
                              key: const ValueKey('voice-transcript'),
                              controller: _transcriptController,
                              focusNode: _focusNode,
                              enabled: !_isAnalyzing,
                              minLines: 3,
                              maxLines: 5,
                              maxLength: 500,
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: (_) => setState(() => _error = null),
                              decoration: InputDecoration(
                                hintText: l10n.voice_transcript_hint,
                                helperText: l10n.voice_example,
                                helperMaxLines: 2,
                                filled: true,
                                fillColor: card,
                                contentPadding: const EdgeInsets.all(14),
                                hintStyle: TextStyle(
                                  color: secondaryText.withValues(alpha: 0.72),
                                ),
                                helperStyle: TextStyle(
                                  color: secondaryText,
                                  height: 1.3,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: border),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                                counterText: '',
                              ),
                            ),
                            // While listening, each word fades in as it is
                            // heard; the field takes over again after.
                            if (_isListening &&
                                _transcriptController.text.trim().isNotEmpty)
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 0,
                                child: IgnorePointer(
                                  child: _LiveWords(
                                    text: _transcriptController.text,
                                    background: card,
                                    border: AppColors.primary,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              WaznIcons.shieldCheck,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                l10n.voice_privacy_note,
                                textAlign: TextAlign.center,
                                style: AppTypography.labelSmall.copyWith(
                                  color: secondaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          _ErrorBanner(
                            message: _error!,
                            showSettings: _permanentlyDenied,
                            settingsLabel: l10n.voice_open_settings,
                            onSettings: openAppSettings,
                          ),
                        ],
                        const SizedBox(height: 18),
                        _FillingButton(
                          fill: _fill,
                          child: FilledButton.icon(
                            key: const ValueKey('voice-analyze'),
                            onPressed: _canAnalyze ? _analyze : null,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              backgroundColor: AppColors.emeraldDark,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  dark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : AppColors.lightCardBorder,
                              disabledForegroundColor: secondaryText,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            icon: AnimatedSwitcher(
                              duration: AppMotion.maybeZero(
                                context,
                                const Duration(milliseconds: 320),
                              ),
                              transitionBuilder:
                                  (child, animation) => ScaleTransition(
                                    scale: CurvedAnimation(
                                      parent: animation,
                                      curve: AppMotion.springCurve,
                                    ),
                                    child: child,
                                  ),
                              child:
                                  _analyzed
                                      ? const Icon(
                                        WaznIcons.success,
                                        key: ValueKey('done'),
                                        size: 20,
                                      )
                                      : _isAnalyzing
                                      ? const SizedBox(
                                        key: ValueKey('busy'),
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : const Icon(
                                        WaznIcons.ai,
                                        key: ValueKey('idle'),
                                        size: 19,
                                      ),
                            ),
                            label: Text(
                              _isAnalyzing
                                  ? l10n.voice_analyzing
                                  : l10n.voice_analyze,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (_transcriptController.text.trim().isNotEmpty &&
                            !_isAnalyzing) ...[
                          const SizedBox(height: 6),
                          TextButton.icon(
                            key: const ValueKey('voice-speak-again'),
                            onPressed:
                                _speechUnavailable
                                    ? null
                                    : () => _startListening(clearFirst: true),
                            icon: const Icon(WaznIcons.rotateCcw, size: 17),
                            label: Text(l10n.voice_speak_again),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  dark
                                      ? AppColors.emeraldLight
                                      : AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

class _MicControl extends StatefulWidget {
  const _MicControl({
    required this.listening,
    required this.analyzing,
    required this.soundLevel,
    required this.secondsLeft,
    required this.onTap,
    required this.readyLabel,
    required this.listeningLabel,
  });

  final bool listening;
  final bool analyzing;
  final double soundLevel;
  final int secondsLeft;
  final Future<void> Function()? onTap;
  final String readyLabel;
  final String listeningLabel;

  @override
  State<_MicControl> createState() => _MicControlState();
}

class _MicControlState extends State<_MicControl>
    with SingleTickerProviderStateMixin {
  /// Rings rippling out from the microphone while it listens.
  late final AnimationController _ripple;

  @override
  void initState() {
    super.initState();
    _ripple = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_MicControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.listening && !AppMotion.reduceMotion(context)) {
      if (!_ripple.isAnimating) _ripple.repeat();
    } else if (_ripple.isAnimating || _ripple.value != 0) {
      _ripple
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final label =
        widget.listening
            ? '${widget.listeningLabel} · ${widget.secondsLeft}s'
            : widget.readyLabel;
    final muted = dark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Column(
      children: [
        Semantics(
          button: true,
          label: label,
          child: InkResponse(
            key: const ValueKey('voice-mic'),
            onTap: widget.onTap,
            radius: 60,
            // Rings ripple out while listening, stronger the louder the
            // voice, and the halo swells with it.
            child: AnimatedBuilder(
              animation: _ripple,
              builder:
                  (context, child) => CustomPaint(
                    painter: _RipplePainter(
                      progress: _ripple.value,
                      level: widget.listening ? widget.soundLevel : 0,
                      color: AppColors.primary,
                    ),
                    child: child,
                  ),
              child: AnimatedScale(
                scale: widget.listening ? 1 + widget.soundLevel * 0.1 : 1,
                duration: const Duration(milliseconds: 120),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 108,
                  height: 108,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(
                      alpha: widget.listening ? 0.13 : 0.075,
                    ),
                    border: Border.all(
                      color: AppColors.primary.withValues(
                        alpha: widget.listening ? 0.36 : 0.16,
                      ),
                    ),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(
                            alpha: widget.listening ? 0.30 : 0.18,
                          ),
                          blurRadius: widget.listening ? 24 : 16,
                          spreadRadius: widget.listening ? 2 : 0,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: AppMotion.maybeZero(
                        context,
                        const Duration(milliseconds: 360),
                      ),
                      transitionBuilder:
                          (child, animation) => RotationTransition(
                            turns: Tween(
                              begin: -.125,
                              end: 0.0,
                            ).animate(animation),
                            child: ScaleTransition(
                              scale: CurvedAnimation(
                                parent: animation,
                                curve: AppMotion.springCurve,
                              ),
                              child: child,
                            ),
                          ),
                      child: Icon(
                        widget.listening ? WaznIcons.square : WaznIcons.voice,
                        key: ValueKey(widget.listening),
                        size: widget.listening ? 25 : 31,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 22,
          child:
              widget.listening
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(7, (index) {
                      final distance = (index - 3).abs();
                      final factor = 1 - distance * 0.12;
                      final height = 5 + (17 * widget.soundLevel * factor);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: 3,
                        height: height,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  )
                  : widget.analyzing
                  ? Icon(
                    WaznIcons.loader,
                    size: 18,
                    color: muted.withValues(alpha: 0.55),
                  )
                  : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: widget.listening ? AppColors.primary : muted,
          ),
        ),
      ],
    );
  }
}

/// Three rings spreading from the microphone, each a third of a beat
/// behind the last.
class _RipplePainter extends CustomPainter {
  const _RipplePainter({
    required this.progress,
    required this.level,
    required this.color,
  });

  final double progress;
  final double level;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (level <= 0) return;
    final centre = size.center(Offset.zero);
    final base = size.shortestSide / 2;
    for (var i = 0; i < 3; i++) {
      final t = (progress + i / 3) % 1;
      canvas.drawCircle(
        centre,
        base * (1 + t * 0.7),
        Paint()
          ..color = color.withValues(
            alpha: (1 - t) * 0.45 * (0.4 + level * 0.6),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.progress != progress || old.level != level || old.color != color;
}

/// The words heard so far, each new one fading up into place.
class _LiveWords extends StatelessWidget {
  const _LiveWords({
    required this.text,
    required this.background,
    required this.border,
    required this.style,
  });

  final String text;
  final Color background;
  final Color border;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final words = text.trim().split(RegExp(r'\s+'));
    return Container(
      key: const ValueKey('voice-live-words'),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            for (var i = 0; i < words.length; i++) ...[
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: Reveal(
                  key: ValueKey('$i-${words[i]}'),
                  offset: const Offset(0, 6),
                  duration: const Duration(milliseconds: 380),
                  child: Text(words[i], style: style),
                ),
              ),
              if (i < words.length - 1) const TextSpan(text: ' '),
            ],
          ],
        ),
      ),
    );
  }
}

/// A button with a lighter band filling it from the start while its work
/// goes on.
class _FillingButton extends StatelessWidget {
  const _FillingButton({required this.fill, required this.child});

  final Animation<double> fill;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AnimatedBuilder(
                animation: fill,
                builder:
                    (context, _) =>
                        fill.value == 0
                            ? const SizedBox.shrink()
                            : FractionallySizedBox(
                              key: const ValueKey('voice-analyze-fill'),
                              alignment: AlignmentDirectional.centerStart,
                              widthFactor: fill.value,
                              child: ColoredBox(
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                            ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.showSettings,
    required this.settingsLabel,
    required this.onSettings,
  });

  final String message;
  final bool showSettings;
  final String settingsLabel;
  final Future<bool> Function() onSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(WaznIcons.error, color: scheme.onErrorContainer, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (showSettings)
            TextButton(
              onPressed: onSettings,
              style: TextButton.styleFrom(
                foregroundColor: scheme.onErrorContainer,
              ),
              child: Text(settingsLabel),
            ),
        ],
      ),
    );
  }
}
