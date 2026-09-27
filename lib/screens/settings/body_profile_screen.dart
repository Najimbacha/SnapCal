import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/wazn_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_state_provider.dart';
import '../../core/nutrition/plan_math.dart';
import '../../providers/settings_provider.dart';
import '../../providers/metrics_provider.dart';
import '../../data/models/user_settings.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/motion/celebration.dart';
import '../../widgets/motion/reveal.dart';
import '../../widgets/motion/visible_gate.dart';
import 'widgets/weight_entry_modal.dart';

import 'widgets/settings_kit.dart';

class BodyProfileScreen extends ConsumerWidget {
  const BodyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return AppPageScaffold(
      title: l10n.settings_body_profile_title,
      subtitle: l10n.settings_body_profile_desc,
      scrollable: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      backgroundColor: settingsBg(context),
      child: Column(
        children: [
          const Reveal(child: _WeightProgressBar()),
          const SizedBox(height: 24),
          Reveal(
            delay: const Duration(milliseconds: 70),
            child: SettingsSection(
              title: l10n.settings_group_about_you,
              children: [
                SettingsRow(
                  icon: WaznIcons.profile,
                  title: l10n.settings_display_name_label,
                  value:
                      ref.watch(authStateProvider).valueOrNull?.displayName ??
                      l10n.settings_set_name,
                  onTap:
                      () => showSettingsNameDialog(
                        context,
                        ref,
                        ref.watch(authStateProvider).valueOrNull?.displayName ??
                            '',
                      ),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final settings = ref.watch(settingsProvider).valueOrNull;
                    return Column(
                      children: [
                        SettingsRow(
                          icon: WaznIcons.calendar,
                          title: l10n.settings_age,
                          value: settings?.age?.toString() ?? '--',
                          onTap:
                              () => showSettingsNumberDialog(
                                context,
                                title: l10n.settings_age,
                                currentValue: settings?.age ?? 25,
                                unit: 'yrs',
                                min: PlanLimits.minAge,
                                max: PlanLimits.maxAge,
                                onSave: (value) async {
                                  final notifier = ref.read(
                                    settingsProvider.notifier,
                                  );
                                  final weight =
                                      ref
                                          .read(bodyMetricsProvider.notifier)
                                          .currentWeight;
                                  await notifier.updateBodyProfile(
                                    age: value,
                                    currentWeightKg: weight,
                                  );
                                },
                              ),
                        ),
                        SettingsRow(
                          icon: WaznIcons.profile,
                          title: l10n.settings_sex,
                          subtitle: l10n.settings_sex_hint,
                          value:
                              settings?.gender != null
                                  ? localizeGender(context, settings!.gender!)
                                  : '--',
                          onTap:
                              () => showGenderSelector(
                                context,
                                ref,
                                settings ?? UserSettings.defaults(),
                              ),
                        ),
                      ],
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final settings = ref.watch(settingsProvider).valueOrNull;
                    final height = settings?.height;
                    // Imperial heights are edited in inches. The units picker
                    // used to save "ft", which this screen then read as
                    // centimetres: "170 FT", and edits were saved as cm.
                    final imperial = isImperialHeight(settings?.heightUnit);
                    final inches =
                        height == null ? null : (height / 2.54).round();
                    final String shown;
                    if (height == null) {
                      shown = l10n.settings_set_height;
                    } else if (inches != null && imperial) {
                      shown = '${inches ~/ 12}′ ${inches % 12}″';
                    } else {
                      shown =
                          '${height.round()} ${localizeUnit(context, 'cm')}';
                    }
                    return SettingsRow(
                      icon: WaznIcons.ruler,
                      title: l10n.settings_height,
                      value: shown,
                      onTap:
                          () => showSettingsNumberDialog(
                            context,
                            title: l10n.settings_height,
                            currentValue:
                                (imperial ? inches : height?.round()) ??
                                (imperial ? 67 : 170),
                            unit: imperial ? 'in' : 'cm',
                            min:
                                imperial
                                    ? (PlanLimits.minHeightCm / 2.54).round()
                                    : PlanLimits.minHeightCm.round(),
                            max:
                                imperial
                                    ? (PlanLimits.maxHeightCm / 2.54).round()
                                    : PlanLimits.maxHeightCm.round(),
                            onSave: (value) async {
                              final cm =
                                  imperial ? value * 2.54 : value.toDouble();
                              final notifier = ref.read(
                                settingsProvider.notifier,
                              );
                              final weight =
                                  ref
                                      .read(bodyMetricsProvider.notifier)
                                      .currentWeight;
                              await notifier.updateBodyProfile(
                                height: cm,
                                currentWeightKg: weight,
                              );
                            },
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Reveal(
            delay: const Duration(milliseconds: 140),
            child: SettingsSection(
              title: l10n.settings_group_weight,
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final weightUnit =
                        ref.watch(settingsProvider).valueOrNull?.weightUnit ??
                        'kg';
                    final metrics =
                        ref.watch(bodyMetricsProvider).valueOrNull ?? [];
                    final currentWeight =
                        metrics.isEmpty ? null : metrics.first.weight;
                    double? displayWeight = currentWeight;
                    if (displayWeight != null && weightUnit == 'lb') {
                      displayWeight = displayWeight * 2.20462;
                    }
                    return SettingsRow(
                      icon: WaznIcons.weight,
                      title: l10n.settings_current_weight,
                      value:
                          displayWeight != null
                              ? '${displayWeight.toStringAsFixed(1)} ${localizeUnit(context, weightUnit)}'
                              : l10n.settings_set_weight,
                      onTap:
                          () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const WeightEntryModal(),
                          ),
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final targetWeight =
                        ref.watch(settingsProvider).valueOrNull?.targetWeight;
                    final weightUnit =
                        ref.watch(settingsProvider).valueOrNull?.weightUnit ??
                        'kg';
                    double? displayTarget = targetWeight;
                    if (displayTarget != null && weightUnit == 'lb') {
                      displayTarget = displayTarget * 2.20462;
                    }
                    return SettingsRow(
                      icon: WaznIcons.goal,
                      title: l10n.settings_target_weight,
                      value:
                          displayTarget != null
                              ? '${displayTarget.toStringAsFixed(1)} ${localizeUnit(context, weightUnit)}'
                              : l10n.settings_set_target,
                      onTap:
                          () => showSettingsDecimalDialog(
                            context,
                            title: l10n.settings_target_weight,
                            currentValue:
                                displayTarget ??
                                (weightUnit == 'lb' ? 154 : 70),
                            unit: weightUnit,
                            min:
                                weightUnit == 'lb'
                                    ? PlanLimits.minWeightKg * 2.20462
                                    : PlanLimits.minWeightKg,
                            max:
                                weightUnit == 'lb'
                                    ? PlanLimits.maxWeightKg * 2.20462
                                    : PlanLimits.maxWeightKg,
                            onSave: (value) async {
                              double kg = value;
                              if (weightUnit == 'lb') kg = value / 2.20462;
                              final notifier = ref.read(
                                settingsProvider.notifier,
                              );
                              final weight =
                                  ref
                                      .read(bodyMetricsProvider.notifier)
                                      .currentWeight;
                              await notifier.updateBodyProfile(
                                targetWeight: kg,
                                currentWeightKg: weight,
                              );
                            },
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Reveal(
            delay: const Duration(milliseconds: 210),
            child: SettingsSection(
              title: l10n.settings_units, // "Units"
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final settings = ref.watch(settingsProvider).valueOrNull;
                    return SettingsRow(
                      icon: WaznIcons.settings,
                      title: l10n.settings_units,
                      value:
                          '${localizeUnit(context, settings?.weightUnit ?? 'kg').toUpperCase()} / ${localizeUnit(context, settings?.heightUnit ?? 'cm').toUpperCase()}',
                      onTap:
                          () => showUnitSelector(
                            context,
                            settings ?? UserSettings.defaults(),
                            ref,
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightProgressBar extends StatelessWidget {
  const _WeightProgressBar();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer(
      builder: (context, ref, child) {
        final settings = ref.watch(settingsProvider).valueOrNull;
        final unit = settings?.weightUnit ?? 'kg';
        final startWeightKg = settings?.startingWeight;
        // Watched, so a new weigh-in moves the bar. Read alone, it waited
        // for the next settings change.
        ref.watch(bodyMetricsProvider);
        final currentWeightKg =
            ref.read(bodyMetricsProvider.notifier).currentWeight ??
            startWeightKg;
        final targetWeightKg = settings?.targetWeight;

        if (startWeightKg == null ||
            targetWeightKg == null ||
            currentWeightKg == null) {
          return const SizedBox.shrink();
        }

        // Convert weights for display
        final double startWeight =
            unit == 'lb' ? startWeightKg * 2.20462 : startWeightKg;
        final double currentWeight =
            unit == 'lb' ? currentWeightKg * 2.20462 : currentWeightKg;
        final double targetWeight =
            unit == 'lb' ? targetWeightKg * 2.20462 : targetWeightKg;

        // Calculate progress percentage
        double progress = 0.0;
        final diffTotal = (startWeight - targetWeight).abs();
        if (diffTotal > 0.01) {
          if (targetWeight < startWeight) {
            // Weight loss goal
            progress =
                (startWeight - currentWeight) / (startWeight - targetWeight);
          } else {
            // Weight gain goal
            progress =
                (currentWeight - startWeight) / (targetWeight - startWeight);
          }
          progress = progress.clamp(0.0, 1.0);
        }

        final isLoss = targetWeight < startWeight;
        final leftToGoal = weightLeftToGoal(
          start: startWeight,
          current: currentWeight,
          target: targetWeight,
        );

        return _ProgressCard(
          progress: progress,
          start: startWeight,
          current: currentWeight,
          target: targetWeight,
          unit: localizeUnit(context, unit),
          isLoss: isLoss,
          hasGoal: diffTotal > 0.01,
          leftToGoal: leftToGoal,
          isDark: isDark,
        );
      },
    );
  }
}

/// The weight progress card. The bar fills from the start the first time it
/// shows, with the percentage counting and a marker settling where you are.
/// A new weigh-in glides the marker and rolls the numbers; the one that
/// reaches the target pops the marker, sweeps a light and bursts confetti.
class _ProgressCard extends StatefulWidget {
  const _ProgressCard({
    required this.progress,
    required this.start,
    required this.current,
    required this.target,
    required this.unit,
    required this.isLoss,
    required this.hasGoal,
    required this.leftToGoal,
    required this.isDark,
  });

  final double progress;
  final double start;
  final double current;
  final double target;
  final String unit;
  final bool isLoss;
  final bool hasGoal;
  final double leftToGoal;
  final bool isDark;

  @override
  State<_ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends State<_ProgressCard>
    with TickerProviderStateMixin, VisibleGate {
  static const _firstFill = Duration(milliseconds: 1200);
  static const _glide = Duration(milliseconds: 900);

  late final AnimationController _move;
  late final AnimationController _pop;
  late final AnimationController _glint;
  final _marker = GlobalKey();

  double _fromProgress = 0;
  late double _fromWeight;

  bool get _reached => widget.hasGoal && widget.leftToGoal <= 0.1;

  @override
  void initState() {
    super.initState();
    _fromWeight = widget.current;
    _move = AnimationController(vsync: this, duration: _firstFill);
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _glint = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    runWhenVisible(() {
      if (AppMotion.reduceMotion(context)) {
        _move.value = 1;
        return;
      }
      _move.forward().whenComplete(() {
        if (mounted) _pop.forward(from: 0);
      });
    });
  }

  @override
  void didUpdateWidget(_ProgressCard old) {
    super.didUpdateWidget(old);
    if (old.progress == widget.progress && old.current == widget.current) {
      return;
    }
    _fromProgress = _progressNow(old);
    _fromWeight = _weightNow(old);
    final wasReached = old.hasGoal && old.leftToGoal <= 0.1;
    if (AppMotion.reduceMotion(context)) {
      _move.value = 1;
      return;
    }
    _move.duration = _glide;
    _move.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      _pop.forward(from: 0);
      if (_reached && !wasReached) _celebrate();
    });
  }

  void _celebrate() {
    HapticFeedback.mediumImpact();
    _glint.forward(from: 0);
    final box = _marker.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    burstConfetti(context, box.localToGlobal(box.size.center(Offset.zero)));
  }

  double get _t => Curves.easeOutCubic.transform(_move.value);

  double _progressNow(_ProgressCard w) =>
      _fromProgress + (w.progress - _fromProgress) * _t;

  double _weightNow(_ProgressCard w) =>
      _fromWeight + (w.current - _fromWeight) * _t;

  @override
  void dispose() {
    _move.dispose();
    _pop.dispose();
    _glint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = widget.isDark;
    final unit = widget.unit;
    final left =
        _reached
            ? l10n.settings_goal_reached
            : l10n.settings_left_to_reach_target(
              widget.leftToGoal.toStringAsFixed(1),
              unit,
            );

    return SettingsSurface(
      child: AnimatedBuilder(
        animation: Listenable.merge([_move, _pop, _glint]),
        builder: (context, _) {
          final progress = _progressNow(widget).clamp(0.0, 1.0);
          final pop = 1 + 0.35 * math.sin(math.pi * _pop.value);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      widget.isLoss
                          ? l10n.settings_weight_loss_progress
                          : l10n.settings_weight_gain_progress,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: settingsText(context),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    key: const ValueKey('weight-progress-percent'),
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: kSettingsGreenText,
                      fontSize: 14,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // The bar, with a marker riding its end.
              SizedBox(
                height: 18,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 10,
                        child: Stack(
                          children: [
                            Container(
                              color:
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : kSettingsLine,
                            ),
                            FractionallySizedBox(
                              key: const ValueKey('weight-progress-fill'),
                              alignment: AlignmentDirectional.centerStart,
                              widthFactor: progress,
                              child: ClipRect(
                                child: CustomPaint(
                                  foregroundPainter: _GlintPainter(
                                    _glint.value,
                                  ),
                                  child: Container(color: kSettingsGreenText),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.hasGoal)
                      Align(
                        alignment: AlignmentDirectional(-1 + 2 * progress, 0),
                        child: Transform.scale(
                          scale: pop,
                          child: Container(
                            key: _marker,
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? const Color(0xFF1F1E1A)
                                      : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: kSettingsGreenText,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Values legend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Reveal(
                      delay: const Duration(milliseconds: 300),
                      offset: const Offset(0, 10),
                      child: _WeightLabel(
                        label: l10n.settings_weight_start,
                        value: '${widget.start.toStringAsFixed(1)} $unit',
                        alignment: CrossAxisAlignment.start,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Reveal(
                      delay: const Duration(milliseconds: 390),
                      offset: const Offset(0, 10),
                      child: Transform.scale(
                        scale: 1 + 0.08 * math.sin(math.pi * _pop.value),
                        child: _WeightLabel(
                          key: const ValueKey('weight-progress-current'),
                          label: l10n.settings_weight_current,
                          value:
                              '${_weightNow(widget).toStringAsFixed(1)} $unit',
                          isHighlight: true,
                          alignment: CrossAxisAlignment.center,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Reveal(
                      delay: const Duration(milliseconds: 480),
                      offset: const Offset(0, 10),
                      child: _WeightLabel(
                        label: l10n.settings_weight_target,
                        value: '${widget.target.toStringAsFixed(1)} $unit',
                        alignment: CrossAxisAlignment.end,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.hasGoal) ...[
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : kSettingsLine,
                ),
                const SizedBox(height: 10),
                Center(
                  child: AnimatedSwitcher(
                    duration: AppMotion.maybeZero(
                      context,
                      const Duration(milliseconds: 380),
                    ),
                    transitionBuilder: _slideUp,
                    child: Text(
                      left,
                      key: ValueKey(left),
                      textAlign: TextAlign.center,
                      style: AppTypography.labelSmall.copyWith(
                        color: settingsSubtext(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static Widget _slideUp(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.6), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }
}

/// A band of light crossing the filled bar at [t] (0 to 1); nothing at rest.
class _GlintPainter extends CustomPainter {
  const _GlintPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final band = size.width * 0.4;
    final x = -band + (size.width + band) * t;
    final rect = Rect.fromLTWH(x, 0, band, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.6),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlintPainter old) => old.t != t;
}

class _WeightLabel extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final CrossAxisAlignment alignment;

  const _WeightLabel({
    super.key,
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.alignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: isHighlight ? kSettingsGreenText : settingsSubtext(context),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 2),
        // Shrinks rather than overflowing on a narrow phone with large text.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
              color:
                  isHighlight
                      ? settingsText(context)
                      : settingsSubtext(context),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
