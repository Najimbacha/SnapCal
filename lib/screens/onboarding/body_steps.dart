import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/theme_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/motion/reveal.dart';
import 'onboarding_body.dart';
import 'onboarding_conversions.dart';
import 'onboarding_draft.dart';
import 'onboarding_kit.dart';
import 'onboarding_units.dart';
import 'onboarding_validation.dart';
import 'widgets/ruler_picker.dart';

/// Age on a wheel, 13 to 100.
class AgeStep extends StatefulWidget {
  const AgeStep({super.key, required this.age, required this.onChanged});

  final int age;
  final ValueChanged<int> onChanged;

  @override
  State<AgeStep> createState() => _AgeStepState();
}

class _AgeStepState extends State<AgeStep> {
  static const _itemExtent = 60.0;
  late int _age = widget.age.clamp(kMinimumAge, kMaximumAge);
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: _age - kMinimumAge);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(int age) {
    if (age == _age) return;
    HapticFeedback.selectionClick();
    setState(() => _age = age);
    widget.onChanged(age);
  }

  void _jump(int by) {
    final target = (_age + by).clamp(kMinimumAge, kMaximumAge);
    _controller.animateToItem(
      target - kMinimumAge,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wheel = ListWheelScrollView.useDelegate(
      key: const ValueKey('onboarding-age-wheel'),
      controller: _controller,
      itemExtent: _itemExtent,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 2.4,
      onSelectedItemChanged: (index) => _select(kMinimumAge + index),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: kMaximumAge - kMinimumAge + 1,
        builder: (context, index) {
          final age = kMinimumAge + index;
          final distance = (age - _age).abs();
          return Center(
            child: Text(
              '$age',
              style: TextStyle(
                color:
                    distance == 0
                        ? context.textPrimaryColor
                        : (distance == 1
                            ? context.textSecondaryColor
                            : context.textMutedColor),
                fontSize: distance == 0 ? 40 : (distance == 1 ? 28 : 24),
                fontWeight: distance == 0 ? FontWeight.w800 : FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          );
        },
      ),
    );

    return OnbPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnbQuestion(l10n.onb_q_age),
          const SizedBox(height: 22),
          Semantics(
            slider: true,
            label: l10n.onb_q_age,
            value: '$_age ${l10n.onb_age_years}',
            increasedValue: '${(_age + 1).clamp(kMinimumAge, kMaximumAge)}',
            decreasedValue: '${(_age - 1).clamp(kMinimumAge, kMaximumAge)}',
            onIncrease: () => _jump(1),
            onDecrease: () => _jump(-1),
            child: Focus(
              onKeyEvent: (_, event) {
                if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                  return KeyEventResult.ignored;
                }
                final by = switch (event.logicalKey) {
                  LogicalKeyboardKey.arrowDown => 1,
                  LogicalKeyboardKey.arrowUp => -1,
                  LogicalKeyboardKey.pageDown => 10,
                  LogicalKeyboardKey.pageUp => -10,
                  _ => 0,
                };
                if (by == 0) return KeyEventResult.ignored;
                _jump(by);
                return KeyEventResult.handled;
              },
              child: SizedBox(
                height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: _itemExtent,
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: context.cardBorderColor),
                      ),
                    ),
                    ExcludeSemantics(
                      child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback:
                            (bounds) => const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x00000000),
                                Color(0xFF000000),
                                Color(0xFF000000),
                                Color(0x00000000),
                              ],
                              stops: [0, 0.3, 0.7, 1],
                            ).createShader(bounds),
                        child: wheel,
                      ),
                    ),
                    IgnorePointer(
                      child: Align(
                        alignment: const AlignmentDirectional(0.52, 0),
                        child: Text(
                          l10n.onb_age_years,
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Height on an upright ruler, with the reading sitting on the pointer.
class HeightStep extends StatelessWidget {
  const HeightStep({
    super.key,
    required this.heightCm,
    required this.system,
    required this.onSystemChanged,
    required this.onChanged,
  });

  final double heightCm;
  final MeasurementSystem system;
  final ValueChanged<MeasurementSystem> onSystemChanged;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final imperial = system == MeasurementSystem.imperial;
    final range = heightRulerRange(system);
    final shown = heightOnRuler(heightCm, system);
    String spoken(double v) =>
        imperial
            ? formatFeetInches(v.round())
            : '${v.round()} ${l10n.settings_unit_cm}';

    return OnbPage(
      scroll: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnbQuestion(l10n.onb_q_height),
          const SizedBox(height: 18),
          OnbUnitSwitch(
            key: const ValueKey('onboarding-height-unit'),
            value: system,
            onChanged: onSystemChanged,
            imperialLabel: l10n.onb_unit_ft,
            metricLabel: l10n.settings_unit_cm,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: RulerPicker(
                        key: ValueKey('onboarding-height-ruler-${system.name}'),
                        axis: Axis.vertical,
                        value: shown,
                        min: range.min,
                        max: range.max,
                        step: 1,
                        majorEvery: imperial ? 12 : 10,
                        midEvery: imperial ? 6 : 5,
                        pixelsPerStep: imperial ? 15 : 9,
                        labelFor:
                            (v) =>
                                imperial
                                    ? '${v.round() ~/ 12}′'
                                    : '${v.round()}',
                        onChanged:
                            (v) => onChanged(
                              imperial ? OnboardingConversions.inchToCm(v) : v,
                            ),
                        semanticLabel: l10n.onb_q_height,
                        semanticValueFor: spoken,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: constraints.maxHeight / 2 + 8,
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          child: OnbReadout(
                            value:
                                imperial
                                    ? formatFeetInches(shown.round())
                                    : '${shown.round()}',
                            unit: imperial ? null : l10n.settings_unit_cm,
                            size: 56,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Current weight on a sliding ruler, with BMI for the height just given.
class WeightStep extends StatelessWidget {
  const WeightStep({
    super.key,
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.system,
    required this.onSystemChanged,
    required this.onChanged,
  });

  final double weightKg;
  final double heightCm;
  final int age;
  final MeasurementSystem system;
  final ValueChanged<MeasurementSystem> onSystemChanged;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shown = weightOnRuler(weightKg, system);
    return OnbPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnbQuestion(l10n.onb_q_weight),
          const SizedBox(height: 18),
          OnbUnitSwitch(
            key: const ValueKey('onboarding-weight-unit'),
            value: system,
            onChanged: onSystemChanged,
            imperialLabel: l10n.settings_unit_lb,
            metricLabel: l10n.settings_unit_kg,
          ),
          const SizedBox(height: 20),
          OnbReadout(
            value: shown.toStringAsFixed(1),
            unit: weightUnitLabel(l10n, system),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: WeightRuler(
              key: ValueKey('onboarding-weight-ruler-${system.name}'),
              valueKg: weightKg,
              system: system,
              semanticLabel: l10n.onb_q_weight,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: 20),
          BmiCard(
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
            system: system,
          ),
        ],
      ),
    );
  }
}

/// The horizontal weight scale, in kg or lb, 0.1 at a time. Shared by the
/// current and target weight screens.
class WeightRuler extends StatelessWidget {
  const WeightRuler({
    super.key,
    required this.valueKg,
    required this.system,
    required this.semanticLabel,
    required this.onChanged,
  });

  final double valueKg;
  final MeasurementSystem system;
  final String semanticLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final range = weightRulerRange(system);
    return RulerPicker(
      value: weightOnRuler(valueKg, system),
      min: range.min,
      max: range.max,
      step: 0.1,
      majorEvery: 10,
      midEvery: 5,
      pixelsPerStep: 8,
      labelFor: (v) => v.toStringAsFixed(0),
      onChanged: (v) => onChanged(displayToKg(v, system)),
      semanticLabel: semanticLabel,
      semanticValueFor:
          (v) => '${v.toStringAsFixed(1)} ${weightUnitLabel(l10n, system)}',
    );
  }
}

/// BMI and the healthy range for this height. Under 18 the number is shown
/// without an adult verdict, which would mislabel a growing teenager.
class BmiCard extends StatelessWidget {
  const BmiCard({
    super.key,
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.system,
  });

  final double weightKg;
  final double heightCm;
  final int age;
  final MeasurementSystem system;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bmi = bmiOf(weightKg: weightKg, heightCm: heightCm);
    final minor = isMinorAge(age);
    final band = bmiBandOf(bmi);
    final healthy = band == BmiBand.healthy;
    final range = healthyWeightRangeKg(heightCm);
    final unit = weightUnitLabel(l10n, system);
    // Rounded inward, so both ends shown are inside the range.
    final rangeText =
        '${kgToDisplay(range.low, system).ceil()}–'
        '${kgToDisplay(range.high, system).floor()} $unit';

    final label = switch ((minor, band)) {
      (true, _) => l10n.onb_bmi_under_18,
      (_, BmiBand.below) => l10n.onb_bmi_below,
      (_, BmiBand.healthy) => l10n.onb_bmi_healthy,
      (_, BmiBand.above) => l10n.onb_bmi_above,
      (_, BmiBand.wellAbove) => l10n.onb_bmi_well_above,
    };
    final dark = context.isDarkMode;
    final pillGood = minor || healthy;
    final pillFg =
        pillGood
            ? (dark ? AppColors.emeraldLight : AppColors.primaryDark)
            : (dark ? const Color(0xFFF5C451) : const Color(0xFF9A5B07));
    final pillBg =
        pillGood
            ? context.primaryColor.withValues(alpha: dark ? 0.18 : 0.12)
            : AppColors.warningAmber.withValues(alpha: dark ? 0.18 : 0.14);

    return OnbCard(
      key: const ValueKey('onboarding-bmi-card'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${l10n.onb_bmi} ${bmi.toStringAsFixed(1)}',
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              // Crossing into another range tints the pill anew and
              // brings the new words up into it.
              AnimatedContainer(
                duration: AppMotion.maybeZero(context, AppMotion.expansion),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: AnimatedSize(
                  duration: AppMotion.maybeZero(context, AppMotion.standard),
                  curve: Curves.easeOutCubic,
                  child: Reveal(
                    key: ValueKey(label),
                    offset: const Offset(0, 8),
                    duration: const Duration(milliseconds: 360),
                    curve: AppMotion.springCurve,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: pillFg,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!minor) ...[
            const SizedBox(height: 14),
            _BmiScale(bmi: bmi, band: band),
          ],
          const SizedBox(height: 10),
          Text(
            minor ? l10n.onb_bmi_teen : l10n.onb_bmi_range(rangeText),
            style: TextStyle(color: context.textSecondaryColor, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// The four bands from 15 to 40, in proportion, with a marker at [bmi].
class _BmiScale extends StatelessWidget {
  const _BmiScale({required this.bmi, required this.band});

  final double bmi;
  final BmiBand band;

  static const _min = 15.0;
  static const _max = 40.0;

  @override
  Widget build(BuildContext context) {
    final bands = [
      (BmiBand.below, 18.5 - _min),
      (BmiBand.healthy, 25 - 18.5),
      (BmiBand.above, 30 - 25.0),
      (BmiBand.wellAbove, _max - 30),
    ];
    final at = ((bmi - _min) / (_max - _min)).clamp(0.0, 1.0);
    final muted = TextStyle(
      color: context.textMutedColor,
      fontSize: 11.5,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return ExcludeSemantics(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  height: 18,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      Row(
                        children: [
                          for (var i = 0; i < bands.length; i++) ...[
                            if (i > 0) const SizedBox(width: 3),
                            Expanded(
                              flex: (bands[i].$2 * 10).round(),
                              child: AnimatedContainer(
                                duration: AppMotion.maybeZero(
                                  context,
                                  AppMotion.expansion,
                                ),
                                height: 8,
                                decoration: BoxDecoration(
                                  color:
                                      bands[i].$1 == band
                                          ? (band == BmiBand.healthy
                                              ? context.primaryColor
                                              : AppColors.warningAmber)
                                          : context.onbFill,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      // The marker trails the ruler a moment, so it glides
                      // rather than jitters.
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: at),
                        duration: AppMotion.maybeZero(
                          context,
                          const Duration(milliseconds: 260),
                        ),
                        curve: Curves.easeOutCubic,
                        builder:
                            (context, at, child) => Positioned(
                              left: (constraints.maxWidth * at - 2).clamp(
                                0.0,
                                constraints.maxWidth - 4,
                              ),
                              child: child!,
                            ),
                        child: Container(
                          key: const ValueKey('onboarding-bmi-marker'),
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: context.textPrimaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            // Each label sits on the boundary it names; the ends hug the
            // edges so they don't hang off the card.
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return SizedBox(
                  height: 16,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final t in const [15.0, 18.5, 25.0, 30.0, 40.0])
                        Positioned(
                          left: width * (t - _min) / (_max - _min),
                          child: FractionalTranslation(
                            translation: Offset(
                              t == _min ? 0 : (t == _max ? -1 : -0.5),
                              0,
                            ),
                            child: Text(
                              t == t.roundToDouble()
                                  ? t.toStringAsFixed(0)
                                  : t.toString(),
                              style: muted,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
