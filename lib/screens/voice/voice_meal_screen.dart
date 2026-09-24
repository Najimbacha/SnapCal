import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/resilience/app_failure.dart';
import '../../core/resilience/retry_policy.dart';
import '../../core/resilience/safe_async.dart';
import '../../core/resilience/timeout_policy.dart';
import '../../core/theme/app_colors.dart';
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

enum _VoicePhase { ready, listening, analyzing }

class VoiceMealScreen extends ConsumerStatefulWidget {
  const VoiceMealScreen({super.key});

  @override
  ConsumerState<VoiceMealScreen> createState() => _VoiceMealScreenState();
}

class _VoiceMealScreenState extends ConsumerState<VoiceMealScreen>
    with WidgetsBindingObserver {
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
    });

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
    setState(() => _phase = _VoicePhase.ready);
    if (items.isEmpty) {
      setState(() => _error = l10n.voice_no_food);
      return;
    }

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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final surface = dark ? const Color(0xFF101412) : const Color(0xFFFAFCFB);
    final textColor = dark ? Colors.white : const Color(0xFF17201B);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _isListening) unawaited(_speech.cancel());
      },
      child: Scaffold(
        backgroundColor: surface,
        appBar: AppBar(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            key: const ValueKey('voice-close'),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => context.pop(),
            icon: const Icon(LucideIcons.x, size: 22),
          ),
          title: Text(
            l10n.voice_log_title,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder:
                (context, constraints) => SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
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
                          textAlign: TextAlign.center,
                          style: AppTypography.headlineSmall.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.voice_subtitle,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: textColor.withValues(alpha: 0.60),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _MicControl(
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
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                          decoration: BoxDecoration(
                            color:
                                dark
                                    ? Colors.white.withValues(alpha: 0.055)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: (dark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.08),
                            ),
                          ),
                          child: TextField(
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
                              labelText: l10n.voice_transcript_label,
                              hintText: l10n.voice_transcript_hint,
                              helperText: l10n.voice_example,
                              helperMaxLines: 2,
                              border: InputBorder.none,
                              counterText: '',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.shieldCheck,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                l10n.voice_privacy_note,
                                textAlign: TextAlign.center,
                                style: AppTypography.labelSmall.copyWith(
                                  color: textColor.withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          _ErrorBanner(
                            message: _error!,
                            showSettings: _permanentlyDenied,
                            settingsLabel: l10n.voice_open_settings,
                            onSettings: openAppSettings,
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          key: const ValueKey('voice-analyze'),
                          onPressed: _canAnalyze ? _analyze : null,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            backgroundColor: AppColors.emeraldDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon:
                              _isAnalyzing
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(LucideIcons.sparkles, size: 19),
                          label: Text(
                            _isAnalyzing
                                ? l10n.voice_analyzing
                                : l10n.voice_analyze,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (_transcriptController.text.trim().isNotEmpty &&
                            !_isAnalyzing) ...[
                          const SizedBox(height: 4),
                          TextButton.icon(
                            key: const ValueKey('voice-speak-again'),
                            onPressed:
                                _speechUnavailable
                                    ? null
                                    : () => _startListening(clearFirst: true),
                            icon: const Icon(LucideIcons.rotateCcw, size: 17),
                            label: Text(l10n.voice_speak_again),
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

class _MicControl extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final label = listening ? '$listeningLabel · ${secondsLeft}s' : readyLabel;

    return Column(
      children: [
        Semantics(
          button: true,
          label: label,
          child: InkResponse(
            key: const ValueKey('voice-mic'),
            onTap: onTap,
            radius: 66,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: listening ? 0.34 : 0.20,
                    ),
                    blurRadius: listening ? 28 : 18,
                    spreadRadius: listening ? 5 : 1,
                  ),
                ],
              ),
              child: Icon(
                listening ? LucideIcons.square : LucideIcons.mic,
                size: listening ? 31 : 38,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 26,
          child:
              listening
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(7, (index) {
                      final distance = (index - 3).abs();
                      final factor = 1 - distance * 0.12;
                      final height = 7 + (19 * soundLevel * factor);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: 4,
                        height: height,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  )
                  : Icon(
                    analyzing ? LucideIcons.loader : LucideIcons.activity,
                    size: 21,
                    color: (dark ? Colors.white : Colors.black).withValues(
                      alpha: 0.30,
                    ),
                  ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            color:
                listening
                    ? AppColors.primary
                    : (dark ? Colors.white : Colors.black).withValues(
                      alpha: 0.62,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCDC7)),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.alertCircle,
            color: Color(0xFFB42318),
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF7A271A), fontSize: 13),
            ),
          ),
          if (showSettings)
            TextButton(onPressed: onSettings, child: Text(settingsLabel)),
        ],
      ),
    );
  }
}
