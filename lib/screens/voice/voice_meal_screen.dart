import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:permission_handler/permission_handler.dart';

import '../../core/resilience/app_failure.dart';
import '../../core/resilience/retry_policy.dart';
import '../../core/resilience/safe_async.dart';
import '../../core/resilience/timeout_policy.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
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
import '../../widgets/app_button.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/motion/count_up_text.dart';
import '../../widgets/motion/reveal.dart';
import '../../widgets/wazn_icons.dart';
import '../snap/widgets/result_modal.dart';

enum VoicePermission { granted, denied, blocked }

/// The microphone and the phone's speech recogniser, behind one small
/// interface so the screen can be driven in tests.
abstract class VoiceInput {
  Future<VoicePermission> ensurePermission();

  /// Starts listening. False when speech recognition is not available.
  Future<bool> start({
    required String languageCode,
    required void Function(String words, bool isFinal) onWords,
    required void Function(double level) onLevel,
    required VoidCallback onDone,
    required void Function(bool noSpeech) onError,
  });

  Future<void> stop();
  Future<void> cancel();
}

/// The phone's own recogniser. Wazn never records audio: the platform hands
/// back text, and only that text is sent on.
class DeviceVoiceInput implements VoiceInput {
  final SpeechRecognitionService _speech = SpeechRecognitionService();
  bool _ready = false;
  void Function(String status)? _status;
  void Function(String message)? _error;

  @override
  Future<VoicePermission> ensurePermission() async {
    var permission = await Permission.microphone.status;
    if (!permission.isGranted) {
      permission = await Permission.microphone.request();
    }
    if (permission.isGranted) return VoicePermission.granted;
    return permission.isPermanentlyDenied
        ? VoicePermission.blocked
        : VoicePermission.denied;
  }

  @override
  Future<bool> start({
    required String languageCode,
    required void Function(String words, bool isFinal) onWords,
    required void Function(double level) onLevel,
    required VoidCallback onDone,
    required void Function(bool noSpeech) onError,
  }) async {
    _status = (status) {
      if (status == 'done' || status == 'notListening') onDone();
    };
    _error = (message) {
      onError(message.contains('no_match') || message.contains('speech'));
    };
    if (!_ready) {
      _ready = await _speech.initialize(
        onStatus: (s) => _status?.call(s),
        onError: (message, _) => _error?.call(message),
      );
      if (!_ready) return false;
    }
    final localeId = await _speech.bestLocaleFor(languageCode);
    await _speech.listen(
      localeId: localeId,
      onWords: onWords,
      // Native recognisers use different ranges; a bounded relative value
      // is enough to move the orb.
      onSoundLevel: (level) => onLevel((level.abs() / 12).clamp(0.0, 1.0)),
    );
    return true;
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() => _speech.cancel();
}

enum _Stage { waking, listening, understanding, result, idle, typing }

enum _Problem {
  noSpeech,
  noAccess,
  blocked,
  unavailable,
  noFood,
  offline,
  busy,
  failed,
}

/// Voice logging in one screen: it opens listening, stops when you pause,
/// works the meal out by itself and lays the foods out underneath your own
/// words. Add to Log is the only tap it needs.
class VoiceMealScreen extends ConsumerStatefulWidget {
  const VoiceMealScreen({super.key, this.input, this.analyzeMeal});

  /// The microphone; the phone's own when null.
  final VoiceInput? input;

  /// Turns the words into foods; the Wazn server when null.
  final Future<List<NutritionResult>> Function(String text, String language)?
  analyzeMeal;

  /// Which words of [words] name each food in [foodNames], so the screen can
  /// mark them. A word counts when it and a word of the food's name share
  /// their first four letters ("eggs" and "Egg"); a number just before a
  /// marked word is marked with it ("2 eggs").
  @visibleForTesting
  static List<Set<int>> matchFoods(List<String> words, List<String> foodNames) {
    String norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
    String stem(String s) => s.length <= 4 ? s : s.substring(0, 4);
    final normed = words.map(norm).toList();
    final taken = <int>{};
    final out = <Set<int>>[];
    for (final name in foodNames) {
      final keys = <String>{
        for (final part in name.split(RegExp(r'[\s,/\-]+')))
          if (norm(part).length >= 3) stem(norm(part)),
      };
      final hits = <int>{};
      for (var i = 0; i < normed.length; i++) {
        final w = normed[i];
        if (w.length < 3 || taken.contains(i)) continue;
        final ws = stem(w);
        if (keys.any((k) => ws.startsWith(k) || k.startsWith(ws))) hits.add(i);
      }
      for (final i in hits.toList()) {
        if (i > 0 &&
            RegExp(r'^\d+$').hasMatch(normed[i - 1]) &&
            !taken.contains(i - 1)) {
          hits.add(i - 1);
        }
      }
      taken.addAll(hits);
      out.add(hits);
    }
    return out;
  }

  @override
  ConsumerState<VoiceMealScreen> createState() => _VoiceMealScreenState();
}

class _VoiceMealScreenState extends ConsumerState<VoiceMealScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final VoiceInput _input = widget.input ?? DeviceVoiceInput();
  final _ai = AIService();
  final _analytics = AnalyticsService();

  /// Keeps the orb moving; its value is only a clock.
  late final AnimationController _orb = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  /// The ring that fills once you stop talking. When it closes, listening
  /// ends and the meal is worked out.
  late final AnimationController _finish = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..addStatusListener((status) {
    if (status == AnimationStatus.completed) _complete(_session);
  });

  final _level = ValueNotifier<double>(0);
  final _typed = TextEditingController();
  final _typeFocus = FocusNode();

  _Stage _stage = _Stage.waking;
  _Problem? _problem;
  String _words = '';
  List<NutritionResult>? _items;
  List<Set<int>> _groups = const [];
  int _lit = 0;
  int _secondsLeft = 30;
  bool _saved = false;
  bool _saving = false;
  int _session = 0;
  Timer? _countdown;
  Timer? _silence;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _listen();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _stage == _Stage.listening) {
      _session++;
      _stopTimers();
      unawaited(_input.cancel());
      _toIdle(null);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session++;
    _stopTimers();
    unawaited(_input.cancel());
    _orb.dispose();
    _finish.dispose();
    _level.dispose();
    _typed.dispose();
    _typeFocus.dispose();
    super.dispose();
  }

  bool _live(int session) => mounted && session == _session;

  String get _language =>
      ref.read(settingsProvider).valueOrNull?.languageCode ??
      Localizations.localeOf(context).languageCode;

  void _stopTimers() {
    _countdown?.cancel();
    _silence?.cancel();
    _finish.stop();
    _finish.value = 0;
    _level.value = 0;
  }

  void _toIdle(_Problem? problem) {
    if (!mounted) return;
    _stopTimers();
    setState(() {
      _stage = _Stage.idle;
      _problem = problem;
    });
  }

  // ───────────────────────────── listening ─────────────────────────────

  Future<void> _listen() async {
    final session = ++_session;
    final language = Localizations.localeOf(context).languageCode;
    _stopTimers();
    _typeFocus.unfocus();
    setState(() {
      _stage = _Stage.waking;
      _problem = null;
      _words = '';
      _items = null;
      _groups = const [];
      _lit = 0;
      _saved = false;
      _secondsLeft = 30;
    });

    VoicePermission permission;
    try {
      permission = await _input.ensurePermission();
    } catch (e) {
      debugPrint('Microphone permission unavailable: $e');
      if (_live(session)) _toIdle(_Problem.unavailable);
      return;
    }
    if (!_live(session)) return;
    if (permission != VoicePermission.granted) {
      _toIdle(
        permission == VoicePermission.blocked
            ? _Problem.blocked
            : _Problem.noAccess,
      );
      return;
    }
    bool started;
    try {
      started = await _input.start(
        languageCode: language,
        onWords: (words, isFinal) => _onWords(session, words, isFinal),
        onLevel: (level) {
          if (_live(session) && _stage == _Stage.listening) {
            _level.value = level;
          }
        },
        onDone: () => _complete(session),
        onError: (noSpeech) => _onError(session, noSpeech),
      );
    } catch (e) {
      debugPrint('Speech recognition failed to start: $e');
      started = false;
    }
    if (!_live(session)) return;
    if (!started) {
      _toIdle(_Problem.unavailable);
      return;
    }
    setState(() => _stage = _Stage.listening);
    HapticFeedback.mediumImpact();
    _analytics.logEvent(
      'voice_log_started',
      parameters: {'language': language},
    );
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_live(session) || _stage != _Stage.listening) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        _complete(session);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _onWords(int session, String words, bool isFinal) {
    if (!_live(session) || _stage != _Stage.listening) return;
    final text = words.trim();
    if (text.isEmpty) return;
    setState(() => _words = text.characters.take(500).toString());
    _silence?.cancel();
    _finish.stop();
    _finish.value = 0;
    if (isFinal) {
      _complete(session);
      return;
    }
    // A short pause, then the ring: finishing is visible and can be
    // interrupted simply by talking again.
    _silence = Timer(const Duration(milliseconds: 900), () {
      if (_live(session) && _stage == _Stage.listening) {
        _finish.forward(from: 0);
      }
    });
  }

  void _onError(int session, bool noSpeech) {
    if (!_live(session) || _stage != _Stage.listening) return;
    if (_words.trim().isNotEmpty) {
      _complete(session);
    } else {
      _toIdle(noSpeech ? _Problem.noSpeech : _Problem.unavailable);
    }
  }

  /// Listening is over: by the ring, a tap on the orb, the recogniser, or
  /// the 30 seconds running out.
  void _complete(int session) {
    if (!_live(session) || _stage != _Stage.listening) return;
    _stopTimers();
    unawaited(_input.stop());
    if (_words.trim().length < 2) {
      _toIdle(_Problem.noSpeech);
      return;
    }
    unawaited(_analyze(_words));
  }

  // ───────────────────────────── understanding ─────────────────────────────

  Future<void> _analyze(String text) async {
    final words = text.trim();
    if (words.length < 2) return;
    final session = ++_session;
    _typeFocus.unfocus();
    setState(() {
      _stage = _Stage.understanding;
      _words = words.characters.take(500).toString();
      _problem = null;
      _items = null;
      _groups = const [];
      _lit = 0;
    });
    final language = _language;
    final result = await SafeAsync.run<List<NutritionResult>>(
      label: 'Voice meal analysis',
      operation:
          () =>
              widget.analyzeMeal?.call(_words, language) ??
              _ai.analyzeMealText(_words, language: language),
      timeout: TimeoutPolicy.aiScan,
      retryPolicy: RetryPolicy.scan,
      operationKey: 'voice-meal-analysis-$session',
      isActive: () => _live(session),
    );
    if (!_live(session)) return;

    if (result.isFailure) {
      final failure = result.failure!;
      _analytics.logEvent(
        'voice_log_failed',
        parameters: {'reason': failure.type.name},
      );
      if (failure.type == AppFailureType.cancelled) {
        _toIdle(null);
        return;
      }
      if (failure.type == AppFailureType.quotaExceeded &&
          failure.statusCode == 402) {
        _toIdle(null);
        if (!mounted) return;
        PremiumConversionService().openPaywall(
          context,
          PaywallEntryPoint.scanLimit,
          limitReached: true,
          featureName: 'voice_scan',
        );
        return;
      }
      // Said as what it is: offline and "too many at once" both read as
      // "Wazn couldn't analyze that meal", which sounds like the words.
      _toIdle(switch (failure.type) {
        AppFailureType.offline || AppFailureType.timeout => _Problem.offline,
        AppFailureType.quotaExceeded => _Problem.busy,
        _ => _Problem.failed,
      });
      return;
    }

    final items = result.requireData;
    if (items.isEmpty) {
      _toIdle(_Problem.noFood);
      return;
    }
    _analytics.logEvent(
      'voice_log_analyzed',
      parameters: {'item_count': items.length, 'language': language},
    );
    HapticFeedback.lightImpact();
    if (!mounted) return;
    final groups = VoiceMealScreen.matchFoods(_wordList, [
      for (final i in items) i.foodName,
    ]);
    final instant = AppMotion.reduceMotion(context);
    setState(() {
      _stage = _Stage.result;
      _items = items;
      _groups = groups;
      _lit = instant ? items.length : 0;
    });
    // Each food lights up in the words, then drops in as a row.
    for (var i = 0; i < items.length && !instant; i++) {
      await Future<void>.delayed(Duration(milliseconds: i == 0 ? 260 : 240));
      if (!_live(session)) return;
      setState(() => _lit = i + 1);
    }
  }

  List<String> get _wordList =>
      _words.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  // ───────────────────────────── saving ─────────────────────────────

  Future<void> _addToLog() async {
    final items = _items;
    if (items == null || _saving) return;
    setState(() => _saved = true);
    HapticFeedback.heavyImpact();
    if (!AppMotion.reduceMotion(context)) {
      await Future<void>.delayed(const Duration(milliseconds: 420));
      if (!mounted) return;
    }
    await _saveMeals(items);
  }

  Future<void> _saveMeals(List<NutritionResult> items) async {
    if (_saving) return;
    _saving = true;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final mealNotifier = ref.read(mealLogProvider.notifier);
    final dateString = app_date.DateUtils.getDateString(DateTime.now());

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
          mealDate: dateString,
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
      showAppToast(
        messenger,
        kind: ToastKind.error,
        title: l10n.meal_save_failed,
      );
    } finally {
      _saving = false;
    }
  }

  /// The full result screen, for changing portions or removing a food.
  void _review() {
    final items = _items;
    if (items == null) return;
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: true,
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
                onCancel: () {},
              ),
            ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  void _type() {
    _session++;
    _stopTimers();
    unawaited(_input.cancel());
    _typed.text = _words;
    _typed.selection = TextSelection.collapsed(offset: _typed.text.length);
    setState(() {
      _stage = _Stage.typing;
      _problem = null;
    });
    _typeFocus.requestFocus();
  }

  void _close() {
    _session++;
    unawaited(_input.cancel());
    context.pop();
  }

  // ───────────────────────────── building ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = _Palette(dark);
    final typing = _stage == _Stage.typing;
    // The orb only moves while it is on screen.
    final orbShown =
        _stage == _Stage.waking ||
        _stage == _Stage.listening ||
        _stage == _Stage.idle;
    if (orbShown && !_orb.isAnimating) {
      _orb.repeat();
    } else if (!orbShown && _orb.isAnimating) {
      _orb.stop();
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _session++;
          unawaited(_input.cancel());
        }
      },
      child: Scaffold(
        backgroundColor: c.background,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            if (!typing) _Glow(level: _level, color: c.glow),
            SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    palette: c,
                    onClose: _close,
                    listening: _stage == _Stage.listening,
                    secondsLeft: _secondsLeft,
                    label: l10n.voice_listening_short,
                  ),
                  Expanded(
                    child: typing ? _typingField(l10n, c) : _content(l10n, c),
                  ),
                  _bottom(l10n, c),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(AppLocalizations l10n, _Palette c) {
    final result = _stage == _Stage.result;
    final hasWords = _words.isNotEmpty;
    return SingleChildScrollView(
      key: const ValueKey('voice-scroll'),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!hasWords && _problem == null)
            _Hint(
              title: l10n.voice_say_what_you_ate,
              example: l10n.voice_example,
              palette: c,
            ),
          if (!hasWords && _problem != null)
            Text(
              _problemText(l10n, _problem!),
              key: const ValueKey('voice-problem'),
              style: TextStyle(
                color: c.ink,
                fontSize: 26,
                height: 1.22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
            ),
          if (hasWords)
            GestureDetector(
              key: const ValueKey('voice-words'),
              behavior: HitTestBehavior.opaque,
              onTap:
                  _stage == _Stage.result || _stage == _Stage.idle
                      ? _type
                      : null,
              child: Semantics(
                button: _stage == _Stage.result || _stage == _Stage.idle,
                label: l10n.voice_edit_words,
                child: _Words(
                  words: _wordList,
                  small: result,
                  marked: {for (var i = 0; i < _lit; i++) ..._groups[i]},
                  palette: c,
                  editable: _stage == _Stage.result || _stage == _Stage.idle,
                ),
              ),
            ),
          if (hasWords && _problem != null) ...[
            const SizedBox(height: 14),
            Text(
              _problemText(l10n, _problem!),
              key: const ValueKey('voice-problem'),
              style: TextStyle(color: c.muted, fontSize: 15, height: 1.4),
            ),
          ],
          if (_problem == _Problem.blocked) ...[
            const SizedBox(height: 18),
            AppButton.secondary(
              label: l10n.voice_open_settings,
              icon: WaznIcons.settings,
              expand: false,
              onPressed: openAppSettings,
            ),
          ],
          if (result && _items != null) ...[
            const SizedBox(height: 18),
            _Result(items: _items!, lit: _lit, palette: c, onTapItem: _review),
          ],
        ],
      ),
    );
  }

  Widget _typingField(AppLocalizations l10n, _Palette c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: TextField(
        key: const ValueKey('voice-type-field'),
        controller: _typed,
        focusNode: _typeFocus,
        maxLines: null,
        maxLength: 500,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: _analyze,
        onChanged: (_) => setState(() {}),
        cursorColor: AppColors.primary,
        style: TextStyle(
          color: c.ink,
          fontSize: 22,
          height: 1.3,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: l10n.voice_say_what_you_ate,
          hintStyle: TextStyle(color: c.faint),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _bottom(AppLocalizations l10n, _Palette c) {
    final Widget child;
    switch (_stage) {
      case _Stage.waking:
      case _Stage.listening:
      case _Stage.idle:
        final listening = _stage == _Stage.listening;
        child = Padding(
          key: const ValueKey('voice-orb-area'),
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 170,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _Orb(
                      clock: _orb,
                      level: _level,
                      finish: _finish,
                      listening: listening,
                      label:
                          listening
                              ? l10n.voice_tap_when_done
                              : l10n.voice_tap_to_speak,
                      onTap:
                          listening
                              ? () => _complete(_session)
                              : _stage == _Stage.idle
                              ? _listen
                              : null,
                    ),
                    PositionedDirectional(
                      end: 20,
                      bottom: 18,
                      child: _RoundButton(
                        key: const ValueKey('voice-type'),
                        icon: Icons.keyboard_alt_outlined,
                        tooltip: l10n.voice_type_instead,
                        palette: c,
                        onTap: _type,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _finish,
                builder:
                    (context, _) => Text(
                      _stage == _Stage.waking
                          ? ''
                          : listening && _finish.value > 0
                          ? l10n.voice_got_it
                          : listening
                          ? l10n.voice_tap_when_done
                          : l10n.voice_tap_to_speak,
                      style: TextStyle(
                        color: c.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.voice_privacy_note,
                style: TextStyle(color: c.muted, fontSize: 11.5),
              ),
            ],
          ),
        );
      case _Stage.understanding:
        child = Padding(
          key: const ValueKey('voice-thinking'),
          padding: const EdgeInsets.only(bottom: 110, top: 40),
          child: _Thinking(label: l10n.voice_working_out, palette: c),
        );
      case _Stage.result:
        child = Padding(
          key: const ValueKey('voice-actions'),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Reveal(
            delay: Duration(milliseconds: 200 + 240 * (_items?.length ?? 0)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  key: const ValueKey('voice-add'),
                  label: l10n.result_add_to_log,
                  icon: WaznIcons.plus,
                  done: _saved,
                  onPressed: _addToLog,
                ),
                const SizedBox(height: 4),
                AppButton.text(
                  key: const ValueKey('voice-again'),
                  label: l10n.voice_speak_again,
                  icon: WaznIcons.rotateCcw,
                  quiet: true,
                  expand: true,
                  onPressed: _saved ? null : _listen,
                ),
              ],
            ),
          ),
        );
      case _Stage.typing:
        child = _TypingBar(
          key: const ValueKey('voice-typing-bar'),
          palette: c,
          micTooltip: l10n.voice_tap_to_speak,
          doneLabel: l10n.common_done,
          canSubmit: _typed.text.trim().length >= 2,
          onMic: _listen,
          onDone: () => _analyze(_typed.text),
        );
    }
    return AnimatedSwitcher(
      duration: AppMotion.maybeZero(context, const Duration(milliseconds: 320)),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder:
          (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, .06),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
      child: child,
    );
  }

  String _problemText(AppLocalizations l10n, _Problem problem) =>
      switch (problem) {
        _Problem.noSpeech => l10n.voice_no_speech,
        _Problem.noAccess || _Problem.blocked => l10n.voice_permission_denied,
        _Problem.unavailable => l10n.voice_unavailable,
        _Problem.noFood => l10n.voice_no_food,
        _Problem.offline => l10n.scan_problem_slow_body,
        _Problem.busy => l10n.scan_problem_busy_body,
        _Problem.failed => l10n.voice_analysis_failed,
      };
}

// ───────────────────────────── pieces ─────────────────────────────

class _Palette {
  _Palette(this.dark);

  final bool dark;
  Color get background =>
      dark ? AppColors.darkBackground : AppColors.lightBackground;
  Color get card => dark ? AppColors.darkCard : AppColors.lightCard;
  Color get ink => dark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get muted =>
      dark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get faint => dark ? const Color(0xFF4C504B) : const Color(0xFFB9B9B1);
  Color get line =>
      dark ? Colors.white.withValues(alpha: 0.09) : AppColors.lightCardBorder;
  Color get mark => AppColors.primary.withValues(alpha: dark ? 0.26 : 0.18);
  Color get glow => AppColors.primary.withValues(alpha: dark ? 0.24 : 0.18);
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.palette,
    required this.onClose,
    required this.listening,
    required this.secondsLeft,
    required this.label,
  });

  final _Palette palette;
  final VoidCallback onClose;
  final bool listening;
  final int secondsLeft;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          _RoundButton(
            key: const ValueKey('voice-close'),
            icon: WaznIcons.close,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            palette: palette,
            onTap: onClose,
            size: 40,
          ),
          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: AppMotion.maybeZero(context, AppMotion.standard),
                child:
                    !listening
                        ? const SizedBox(height: 34)
                        : Semantics(
                          liveRegion: true,
                          child: Container(
                            key: const ValueKey('voice-status'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: palette.card,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: palette.line),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const _PulseDot(),
                                const SizedBox(width: 8),
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: palette.ink,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '0:${secondsLeft.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: palette.muted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder:
          (context, _) => Transform.scale(
            scale: 1 - _c.value * .4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 1 - _c.value * .5),
                shape: BoxShape.circle,
              ),
            ),
          ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.palette,
    required this.onTap,
    this.size = 44,
  });

  final IconData icon;
  final String tooltip;
  final _Palette palette;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: palette.card,
        shape: CircleBorder(side: BorderSide(color: palette.line)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: 19, color: palette.ink),
          ),
        ),
      ),
    );
  }
}

/// The empty screen: what to do, and an example of how.
class _Hint extends StatelessWidget {
  const _Hint({
    required this.title,
    required this.example,
    required this.palette,
  });

  final String title;
  final String example;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Reveal(
      offset: const Offset(0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            key: const ValueKey('voice-hint'),
            style: TextStyle(
              color: palette.faint,
              fontSize: 27,
              height: 1.22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            example,
            style: TextStyle(color: palette.muted, fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// What was said, word by word. Large while listening; small above the
/// foods once they are found, with each food's words marked.
class _Words extends StatelessWidget {
  const _Words({
    required this.words,
    required this.small,
    required this.marked,
    required this.palette,
    required this.editable,
  });

  final List<String> words;
  final bool small;
  final Set<int> marked;
  final _Palette palette;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceMotion(context);
    // On top of the app's text style, so the words keep its font.
    final style = (Theme.of(context).textTheme.bodyLarge ?? const TextStyle())
        .copyWith(
          color: small ? palette.muted : palette.ink,
          fontSize: small ? 15 : 28,
          height: small ? 1.45 : 1.24,
          fontWeight: small ? FontWeight.w500 : FontWeight.w600,
          letterSpacing: small ? 0 : -0.4,
        );
    return AnimatedDefaultTextStyle(
      duration: reduce ? Duration.zero : const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      style: style,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var i = 0; i < words.length; i++)
            _Word(
              key: ValueKey('w$i'),
              text: words[i],
              marked: marked.contains(i),
              markedNext: marked.contains(i) && marked.contains(i + 1),
              mark: palette.mark,
              animate: !reduce,
            ),
          if (editable)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 2),
              child: Icon(WaznIcons.edit, size: 14, color: palette.muted),
            ),
        ],
      ),
    );
  }
}

class _Word extends StatelessWidget {
  const _Word({
    super.key,
    required this.text,
    required this.marked,
    required this.markedNext,
    required this.mark,
    required this.animate,
  });

  final String text;
  final bool marked;

  /// The next word is marked too, so the marker runs on through the space.
  final bool markedNext;
  final Color mark;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final word = AnimatedContainer(
      duration: animate ? const Duration(milliseconds: 420) : Duration.zero,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: marked ? mark : mark.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: EdgeInsetsDirectional.only(start: 2, end: markedNext ? 6 : 2),
      margin: EdgeInsetsDirectional.only(end: markedNext ? 0 : 4),
      child: Text(text),
    );
    if (!animate) return word;
    // Each word rises in as it is heard.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder:
          (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 10),
              child: child,
            ),
          ),
      child: word,
    );
  }
}

/// The foods found, their total and when the meal is being logged.
class _Result extends StatelessWidget {
  const _Result({
    required this.items,
    required this.lit,
    required this.palette,
    required this.onTapItem,
  });

  final List<NutritionResult> items;
  final int lit;
  final _Palette palette;
  final VoidCallback onTapItem;

  static const _dots = [
    Color(0xFF7D9A6E),
    Color(0xFF5B93D6),
    Color(0xFFD9894A),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final total = items.fold<int>(0, (s, i) => s + i.calories);
    final protein = items.fold<int>(0, (s, i) => s + i.protein);
    final carbs = items.fold<int>(0, (s, i) => s + i.carbs);
    final fat = items.fold<int>(0, (s, i) => s + i.fat);
    final now = DateTime.now();
    final mealType = switch (app_date.DateUtils.suggestedMealType(now)) {
      'Breakfast' => l10n.result_meal_breakfast,
      'Lunch' => l10n.result_meal_lunch,
      'Dinner' => l10n.result_meal_dinner,
      _ => l10n.result_meal_snack,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            CountUpText(
              key: const ValueKey('voice-total'),
              value: total,
              from: 0,
              delay: const Duration(milliseconds: 200),
              style: TextStyle(
                color: palette.ink,
                fontSize: 46,
                height: 1.05,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 7),
            Text('kcal', style: TextStyle(color: palette.muted, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 10),
        Reveal(
          delay: const Duration(milliseconds: 150),
          offset: const Offset(0, 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                palette: palette,
                icon: WaznIcons.clock,
                strong: mealType,
                rest: ' · ${DateFormat.jm(locale).format(now)}',
              ),
              _Chip(
                palette: palette,
                strong: '',
                rest:
                    '${l10n.result_protein} $protein g · '
                    '${l10n.result_carbs} $carbs g · ${l10n.result_fat} $fat g',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < items.length && i < lit; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Reveal(
              key: ValueKey('voice-item-$i'),
              offset: const Offset(0, -14),
              scale: .96,
              curve: AppMotion.springCurve,
              duration: const Duration(milliseconds: 520),
              child: _ItemRow(
                item: items[i],
                dot: _dots[i % _dots.length],
                palette: palette,
                onTap: onTapItem,
              ),
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.palette,
    required this.strong,
    required this.rest,
    this.icon,
  });

  final _Palette palette;
  final String strong;
  final String rest;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: palette.muted),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: strong,
                    style: TextStyle(
                      color: palette.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: rest),
                ],
              ),
              style: TextStyle(
                color: palette.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.dot,
    required this.palette,
    required this.onTap,
  });

  final NutritionResult item;
  final Color dot;
  final _Palette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.foodName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.portion.trim().isNotEmpty)
                      Text(
                        item.portion,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: palette.muted, fontSize: 12.5),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${item.calories}',
                      style: TextStyle(
                        color: palette.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    TextSpan(
                      text: ' kcal',
                      style: TextStyle(color: palette.muted, fontSize: 12),
                    ),
                  ],
                ),
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three dots and a line, while the meal is worked out.
class _Thinking extends StatefulWidget {
  const _Thinking({required this.label, required this.palette});

  final String label;
  final _Palette palette;

  @override
  State<_Thinking> createState() => _ThinkingState();
}

class _ThinkingState extends State<_Thinking>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: widget.label,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 3; i++)
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = (_c.value - i * .15) % 1;
                final lift = math.sin(t * math.pi).clamp(0.0, 1.0);
                return Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  transform: Matrix4.translationValues(0, -5 * lift, 0),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 1 - lift * .5),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
          const SizedBox(width: 10),
          Text(
            widget.label,
            style: TextStyle(
              color: widget.palette.muted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A soft green light from the bottom of the screen that swells with the
/// voice.
class _Glow extends StatelessWidget {
  const _Glow({required this.level, required this.color});

  final ValueListenable<double> level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: -80,
      right: -80,
      bottom: -220,
      height: 560,
      child: IgnorePointer(
        child: ValueListenableBuilder<double>(
          valueListenable: level,
          builder:
              (context, v, _) => AnimatedScale(
                scale: 1 + v * .3,
                duration: const Duration(milliseconds: 180),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [color, color.withValues(alpha: 0)],
                      stops: const [0, .72],
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}

/// The orb: three soft shapes that breathe while listening and swell with
/// the voice, around a button that finishes (or starts) listening.
class _Orb extends StatefulWidget {
  const _Orb({
    required this.clock,
    required this.level,
    required this.finish,
    required this.listening,
    required this.label,
    required this.onTap,
  });

  final Animation<double> clock;
  final ValueListenable<double> level;
  final Animation<double> finish;
  final bool listening;
  final String label;
  final VoidCallback? onTap;

  @override
  State<_Orb> createState() => _OrbState();
}

class _OrbState extends State<_Orb> {
  double _smooth = 0;

  /// A clock that never wraps, so the shapes never jump.
  final _watch = Stopwatch()..start();

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceMotion(context);
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        key: const ValueKey('voice-orb'),
        onTap: widget.onTap,
        child: SizedBox(
          width: 170,
          height: 170,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              widget.clock,
              widget.level,
              widget.finish,
            ]),
            builder: (context, _) {
              final target = widget.listening ? widget.level.value : 0.0;
              _smooth += (target - _smooth) * .18;
              final seconds = reduce ? 0.0 : _watch.elapsedMilliseconds / 1000;
              return CustomPaint(
                painter: _OrbPainter(
                  time: seconds,
                  level: _smooth,
                  calm: !widget.listening,
                  finish: widget.finish.value,
                ),
                child: Center(
                  child: Transform.scale(
                    scale: 1 + _smooth * .08,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: .35),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: AppMotion.maybeZero(
                          context,
                          const Duration(milliseconds: 260),
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
                            widget.listening
                                ? Container(
                                  key: const ValueKey('stop'),
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                )
                                : const Icon(
                                  WaznIcons.voice,
                                  key: ValueKey('mic'),
                                  color: Colors.white,
                                  size: 26,
                                ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.time,
    required this.level,
    required this.calm,
    required this.finish,
  });

  final double time;
  final double level;
  final bool calm;
  final double finish;

  static const _layers = [
    (Color(0xFF10B981), .22, 50.0, 1.0, .9),
    (Color(0xFF14B8A6), .20, 43.0, 1.3, 1.3),
    (Color(0xFFB8E23C), .16, 38.0, 1.7, 1.8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final energy = calm ? .15 : 1.0;
    for (var li = 0; li < _layers.length; li++) {
      final (color, alpha, radius, k, speed) = _layers[li];
      final base =
          radius * (calm ? .92 : 1) +
          level * 24 * k +
          math.sin(time * 1.4 + li) * 2 * energy;
      final path = Path();
      for (var i = 0; i <= 64; i++) {
        final a = i / 64 * 2 * math.pi;
        final wobble =
            (math.sin(a * 3 + time * speed * 2 + li) * (3 + level * 9) +
                math.sin(a * 5 - time * speed * 1.6) * (2 + level * 6)) *
            energy;
        final r = base + wobble;
        final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()..color = color.withValues(alpha: alpha + level * .12),
      );
    }
    if (finish > 0) {
      final rect = Rect.fromCircle(center: center, radius: 38);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * finish,
        false,
        Paint()
          ..color = AppColors.primaryDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.time != time ||
      old.level != level ||
      old.calm != calm ||
      old.finish != finish;
}

/// Above the keyboard while typing: back to the microphone, or Done.
class _TypingBar extends StatelessWidget {
  const _TypingBar({
    super.key,
    required this.palette,
    required this.micTooltip,
    required this.doneLabel,
    required this.canSubmit,
    required this.onMic,
    required this.onDone,
  });

  final _Palette palette;
  final String micTooltip;
  final String doneLabel;
  final bool canSubmit;
  final VoidCallback onMic;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.background,
        border: Border(top: BorderSide(color: palette.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            _RoundButton(
              key: const ValueKey('voice-back-to-mic'),
              icon: WaznIcons.voice,
              tooltip: micTooltip,
              palette: palette,
              onTap: onMic,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                key: const ValueKey('voice-type-done'),
                label: doneLabel,
                onPressed: canSubmit ? onDone : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
