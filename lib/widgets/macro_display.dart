import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/theme/app_colors.dart';
import '../data/models/meal.dart';
import '../l10n/generated/app_localizations.dart';

/// How a [MacroDisplay] renders. One widget replaces the five near-identical
/// macro implementations that had drifted apart across the home dashboard.
enum MacroDisplayVariant {
  /// Three tall cards: icon, label, grams, and a flush progress track.
  /// Used where macros are the section's subject.
  detailed,

  /// Three short tiles: label, grams, thin track. Used in dense rows.
  compact,

  /// A single stacked bar showing this meal-day's macro composition, plus a
  /// legend. Carries real information without revealing goal progress, so it
  /// works as the free-tier surface.
  composition,

  /// Three cards, each built around a circular progress ring that echoes the
  /// hero calorie gauge. Pro shows grams inside the ring; free shows the same
  /// rings drawn at the user's real progress with the number itself withheld
  /// (a silhouette), plus one upgrade affordance. Set via [showGrams].
  rings,
}

/// Renders protein / carb / fat figures in one of three shapes.
///
/// [showGrams] and [showGoals] are separate switches on purpose. Grams are
/// part of the answer the app exists to give; goal targets and progress are
/// the coaching layer sold with Pro. Gating them independently is what lets
/// the free tier stay useful without giving away the subscription.
class MacroDisplay extends StatelessWidget {
  final Macros macros;
  final int proteinGoal;
  final int carbGoal;
  final int fatGoal;
  final MacroDisplayVariant variant;

  /// When false, gram values are replaced by their composition percentage.
  /// Values are never blurred — a withheld number is stated, not obscured.
  final bool showGrams;

  /// When false, daily targets and goal progress are hidden.
  final bool showGoals;

  /// Optional upgrade affordance rendered as a single row beneath the figures.
  final VoidCallback? onUpgradeTap;
  final String? upgradeLabel;

  const MacroDisplay({
    super.key,
    required this.macros,
    required this.proteinGoal,
    required this.carbGoal,
    required this.fatGoal,
    this.variant = MacroDisplayVariant.detailed,
    this.showGrams = true,
    this.showGoals = true,
    this.onUpgradeTap,
    this.upgradeLabel,
  });

  List<_MacroDatum> _data(AppLocalizations l10n) => [
    _MacroDatum(
      l10n.result_protein,
      macros.protein,
      proteinGoal,
      AppColors.protein,
      LucideIcons.dumbbell,
      4,
    ),
    _MacroDatum(
      l10n.result_carbs,
      macros.carbs,
      carbGoal,
      AppColors.carbs,
      LucideIcons.wheat,
      4,
    ),
    _MacroDatum(
      l10n.result_fat,
      macros.fat,
      fatGoal,
      AppColors.fat,
      LucideIcons.droplet,
      9,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = _data(l10n);

    switch (variant) {
      case MacroDisplayVariant.detailed:
        return _buildRow(context, data, tall: true);
      case MacroDisplayVariant.compact:
        return _buildRow(context, data, tall: false);
      case MacroDisplayVariant.composition:
        return _buildComposition(context, l10n, data);
      case MacroDisplayVariant.rings:
        return _RingsRow(
          data: data,
          locked: !showGrams,
          onUpgradeTap: onUpgradeTap,
        );
    }
  }

  // ── Shared row of three tiles ─────────────────────────────────────────────

  Widget _buildRow(
    BuildContext context,
    List<_MacroDatum> data, {
    required bool tall,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var i = 0; i < data.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _tile(context, data[i], tall: tall)),
            ],
          ],
        ),
        if (onUpgradeTap != null) ...[
          const SizedBox(height: 12),
          _upgradeRow(context),
        ],
      ],
    );
  }

  Widget _tile(BuildContext context, _MacroDatum m, {required bool tall}) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (m.value / math.max(m.goal, 1)).clamp(0.0, 1.0);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            m.color.withValues(alpha: isDark ? 0.10 : 0.07),
            scheme.surface.withValues(alpha: isDark ? 0.16 : 0.30),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: m.color.withValues(alpha: isDark ? 0.14 : 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(10, tall ? 9 : 8, 10, tall ? 8 : 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (tall) ...[
                      Icon(m.icon, size: 13, color: m.color),
                      const SizedBox(width: 5),
                    ] else ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: m.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Expanded(
                      child: Text(
                        m.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        // 11px floor: below this fails both iOS HIG and Material.
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: tall ? 8 : 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        showGrams ? '${m.value}' : '${_pctOf(m)}',
                        style: TextStyle(
                          fontSize: tall ? 19 : 17,
                          fontWeight: FontWeight.w800,
                          color: m.color,
                          height: 1,
                          letterSpacing: -0.3,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        showGrams ? (showGoals ? ' / ${m.goal}g' : 'g') : '%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Track fills the tile rather than sitting at a fixed 36px.
          if (showGoals)
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0, end: progress),
              builder:
                  (context, value, _) => SizedBox(
                    height: 3,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FractionallySizedBox(
                        widthFactor: value.clamp(0.0, 1.0),
                        child: Container(color: m.color),
                      ),
                    ),
                  ),
            )
          else
            const SizedBox(height: 3),
        ],
      ),
    );
  }

  // ── Composition ──────────────────────────────────────────────────────────

  int _pctOf(_MacroDatum m) {
    final total = (macros.protein * 4) + (macros.carbs * 4) + (macros.fat * 9);
    if (total <= 0) return 0;
    return ((m.value * m.kcalPerGram) / total * 100).round().clamp(0, 100);
  }

  Widget _buildComposition(
    BuildContext context,
    AppLocalizations l10n,
    List<_MacroDatum> data,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = (macros.protein * 4) + (macros.carbs * 4) + (macros.fat * 9);
    final hasData = total > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: SizedBox(
            height: 30,
            child:
                hasData
                    ? Row(
                      children: [
                        for (var i = 0; i < data.length; i++)
                          if (_pctOf(data[i]) > 0) ...[
                            if (i > 0) const SizedBox(width: 2),
                            Expanded(
                              flex: math.max(_pctOf(data[i]), 1),
                              child: Container(
                                color: data[i].color,
                                alignment: Alignment.center,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    child: Text(
                                      '${_pctOf(data[i])}%',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                      ],
                    )
                    : Container(
                      color: scheme.onSurface.withValues(
                        alpha: isDark ? 0.08 : 0.06,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.macro_no_meals_yet,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < data.length; i++) ...[
              if (i > 0) const SizedBox(width: 14),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: data[i].color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        showGrams
                            ? '${data[i].label} ${data[i].value}g'
                            : data[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        if (onUpgradeTap != null) ...[
          const SizedBox(height: 12),
          _upgradeRow(context),
        ],
      ],
    );
  }

  /// A single upgrade affordance. One per card — the old preview stacked a
  /// badge, three padlocks, three placeholders and a CTA for one locked thing.
  Widget _upgradeRow(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onUpgradeTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                upgradeLabel ?? l10n.macro_targets_cta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.macro_pro_label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 15, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

class _MacroDatum {
  final String label;
  final int value;
  final int goal;
  final Color color;
  final IconData icon;
  final int kcalPerGram;

  const _MacroDatum(
    this.label,
    this.value,
    this.goal,
    this.color,
    this.icon,
    this.kcalPerGram,
  );
}

// ── Rings ──────────────────────────────────────────────────────────────────

/// The macro section's premium surface: three cards, each built around a
/// progress ring that echoes the hero calorie gauge above it.
///
/// Locked cards are deliberately NOT greyed out. They keep the macro's own
/// color as a soft bloom, draw the user's *real* arc, and withhold only the
/// number — a gap the user can see but cannot close without Pro. Grey reads as
/// broken; color reads as "yours, not yet". A slow sheen sweeps the row a few
/// times after it appears, then settles, so the block looks live without
/// animating for the life of the screen.
class _RingsRow extends StatefulWidget {
  final List<_MacroDatum> data;
  final bool locked;
  final VoidCallback? onUpgradeTap;

  const _RingsRow({
    required this.data,
    required this.locked,
    this.onUpgradeTap,
  });

  @override
  State<_RingsRow> createState() => _RingsRowState();
}

class _RingsRowState extends State<_RingsRow> with TickerProviderStateMixin {
  /// Sweeps to run before the row goes quiet. Enough to catch the eye on
  /// arrival; not enough to burn frames while the user reads the screen.
  static const int _sheenCycles = 3;

  /// Fraction of one sheen cycle spent actually sweeping. The remainder is the
  /// rest beat between passes.
  static const double _sweepFraction = 0.55;

  late final AnimationController _grow;
  late final AnimationController _sheen;
  int _cyclesRun = 0;

  @override
  void initState() {
    super.initState();
    _grow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    )..forward();
    _sheen = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4600),
    );
    if (widget.locked) {
      _sheen.addStatusListener(_onSheenStatus);
      _sheen.forward();
    }
  }

  void _onSheenStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _cyclesRun++;
    if (_cyclesRun < _sheenCycles) {
      _sheen.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _sheen.removeStatusListener(_onSheenStatus);
    _grow.dispose();
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_grow, _sheen]),
          builder:
              (context, _) => Row(
                // Never stretch here: the Row sits in an unbounded-height
                // Column, so stretch hands the cards an infinite height.
                // Every card has the same internal structure, so they end up
                // the same height on their own.
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < widget.data.length; i++) ...[
                    if (i > 0) const SizedBox(width: 9),
                    Expanded(child: _card(context, widget.data[i], i)),
                  ],
                ],
              ),
        ),
        if (widget.locked && widget.onUpgradeTap != null) ...[
          const SizedBox(height: 11),
          _cta(context, l10n),
        ] else if (!widget.locked)
          _metSummary(context, l10n),
      ],
    );
  }

  /// This macro's share of the day's calories, using the same formula as the
  /// composition bar on the Log screen so both surfaces always agree.
  String _shareLabel(_MacroDatum m) {
    final total = widget.data.fold<int>(
      0,
      (sum, d) => sum + (d.value * d.kcalPerGram),
    );
    if (total <= 0) return '–';
    final pct = ((m.value * m.kcalPerGram) / total * 100).round().clamp(0, 100);
    return '$pct%';
  }

  // ── One card ─────────────────────────────────────────────────────────────

  Widget _card(BuildContext context, _MacroDatum m, int index) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locked = widget.locked;

    final target = (m.value / math.max(m.goal, 1)).clamp(0.0, 1.0);
    final progress = target * Curves.easeOutCubic.transform(_grow.value);
    // Hitting a target changes the card, not just the number.
    final met = !locked && m.goal > 0 && m.value >= m.goal;
    final remaining = m.goal - m.value;

    // Sheen sweeps left to right, staggered card to card.
    final raw = _sheen.value - index * 0.09;
    final sweep = raw <= 0 ? 0.0 : (raw / _sweepFraction).clamp(0.0, 1.0);
    final sweeping = locked && sweep > 0 && sweep < 1;


    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            m.color.withValues(
              alpha: locked ? (isDark ? 0.085 : 0.065) : (isDark ? 0.10 : 0.075),
            ),
            (isDark ? Colors.white : Colors.black).withValues(
              alpha: isDark ? 0.02 : 0.012,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: m.color.withValues(
            alpha:
                met
                    ? (isDark ? 0.55 : 0.45)
                    : locked
                    ? (isDark ? 0.16 : 0.13)
                    : (isDark ? 0.20 : 0.16),
          ),
        ),
      ),
      child: Stack(
        children: [
          // Color bloom behind a locked ring — the card stays alive.
          if (locked)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          m.color.withValues(alpha: isDark ? 0.26 : 0.18),
                          m.color.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (sweeping)
            Positioned.fill(
              child: IgnorePointer(
                child: FractionalTranslation(
                  translation: Offset(-1.2 + 2.4 * sweep, 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: isDark ? 0.09 : 0.55),
                          Colors.white.withValues(alpha: 0),
                        ],
                        stops: const [0.34, 0.5, 0.66],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 9, 9, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name row. The lock lives once, on the CTA below: a padlock
                // per card plus a PRO caption plus the CTA was four markers
                // for one locked thing.
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: m.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        m.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (met)
                      Icon(
                        LucideIcons.check,
                        size: 12,
                        color: m.color,
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                // The ring holds the value and nothing else. A caption inside
                // it is wider than the circle at that height, so it cuts
                // across the stroke and the track starts reading as a second
                // zero behind the digit.
                Center(
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: progress,
                        color:
                            locked
                                ? m.color.withValues(alpha: isDark ? 0.62 : 0.55)
                                : m.color,
                        track: scheme.onSurface.withValues(
                          alpha: isDark ? 0.20 : 0.13,
                        ),
                        stroke: 5,
                        glow: !locked,
                        ghostTail: locked,
                        capDot: !locked,
                      ),
                      child: Center(
                        child:
                            locked
                                // The composition percentage stands in for the
                                // grams: a real number, the same one the Log
                                // screen's bar shows, so the two screens never
                                // contradict each other. Grams stay withheld.
                                ? Text(
                                  _shareLabel(m),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                    letterSpacing: -0.4,
                                    color: m.color.withValues(
                                      alpha: isDark ? 0.92 : 0.85,
                                    ),
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                )
                                : Text.rich(
                                  TextSpan(
                                    text: '${m.value}',
                                    children: const [
                                      TextSpan(
                                        text: 'g',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                    letterSpacing: -0.6,
                                    // An untouched day should not shout three
                                    // white zeroes at the user.
                                    color:
                                        m.value > 0
                                            ? scheme.onSurface
                                            : scheme.onSurfaceVariant
                                                .withValues(alpha: 0.55),
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  locked
                      ? AppLocalizations.of(context)!.macro_pro_label
                      : met
                      ? AppLocalizations.of(context)!.macro_target_met
                      : m.goal > 0
                      ? AppLocalizations.of(
                        context,
                      )!.macro_grams_to_go('$remaining')
                      : 'of ${m.goal}g',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        (locked || met) ? FontWeight.w700 : FontWeight.w600,
                    height: 1,
                    letterSpacing: locked ? 0.2 : 0,
                    color:
                        locked
                            ? m.color.withValues(alpha: isDark ? 0.75 : 0.70)
                            : met
                            ? m.color
                            : scheme.onSurfaceVariant.withValues(alpha: 0.75),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Closes the Pro section with the thing a paying user actually wants to
  /// know. Costs nothing: it counts the macros already passed in. Silent when
  /// no targets are set, and when the day has not started.
  Widget _metSummary(BuildContext context, AppLocalizations l10n) {
    final withGoals = widget.data.where((m) => m.goal > 0).toList();
    if (withGoals.isEmpty || widget.data.every((m) => m.value <= 0)) {
      return const SizedBox.shrink();
    }
    final met = withGoals.where((m) => m.value >= m.goal).length;
    final scheme = Theme.of(context).colorScheme;
    final done = met == withGoals.length;

    return Padding(
      padding: const EdgeInsets.only(top: 11),
      child: Row(
        children: [
          Icon(
            done ? LucideIcons.checkCircle2 : LucideIcons.check,
            size: 14,
            color: scheme.primary.withValues(alpha: done ? 1 : 0.55),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              l10n.macro_targets_met_count('$met', '${withGoals.length}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Upgrade affordance ───────────────────────────────────────────────────

  /// The subtitle is drawn from the user's own day when there is something
  /// true to say. A personal line converts better than a feature list, and it
  /// proves the numbers behind the lock are real.
  String _ctaBody(AppLocalizations l10n) {
    _MacroDatum? best;
    var bestRatio = 0.0;
    for (final m in widget.data) {
      final ratio = m.value / math.max(m.goal, 1);
      if (ratio > bestRatio) {
        bestRatio = ratio;
        best = m;
      }
    }
    if (best != null && bestRatio >= 0.6 && bestRatio <= 1.1) {
      return l10n.macro_ring_on_track(best.label);
    }
    return l10n.macro_ring_unlock_body;
  }

  Widget _cta(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: '${l10n.macro_ring_unlock_title}. ${_ctaBody(l10n)}',
      child: GestureDetector(
        onTap: widget.onUpgradeTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          decoration: BoxDecoration(
            // Emerald into the header's premium gold, so the two upgrade
            // affordances on this screen read as one offer.
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.46, 1.0],
              colors: [
                AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.15),
                AppColors.primary.withValues(alpha: isDark ? 0.07 : 0.04),
                AppColors.premiumGold.withValues(alpha: isDark ? 0.10 : 0.09),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: isDark ? 0.30 : 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: isDark ? 0.10 : 0.07,
                ),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF10B981), Color(0xFF0E9C87)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.34),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.lock,
                  size: 14,
                  color: Color(0xFF032A20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.macro_ring_unlock_title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.15,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2.5),
                    Text(
                      _ctaBody(l10n),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(8, 5, 7, 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF10B981), Color(0xFF0FA57C)],
                  ),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.macro_pro_label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Color(0xFF04231A),
                      ),
                    ),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 12,
                      color: Color(0xFF04231A),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Track plus a rounded progress arc, opening at twelve o'clock.
///
/// The Pro arc is a sweep gradient from the macro's own color into a lighter
/// tint of itself, over a soft glow of the same hue. Flat strokes read as a
/// progress bar bent into a circle; the gradient plus bloom is what makes it
/// look like an instrument.
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;
  final double stroke;
  final bool glow;

  /// Dots the arc that has not been drawn, in the same hue. On a locked card
  /// it reads as "there is more of this you cannot see yet" — a withheld
  /// value stated in the shape rather than announced with a padlock.
  final bool ghostTail;

  /// A dot at the head of the arc. Turns a static ratio into a position.
  final bool capDot;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    this.stroke = 5,
    this.glow = false,
    this.ghostTail = false,
    this.capDot = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: centre, radius: radius);

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );

    final swept = progress.clamp(0.0, 1.0);
    if (swept <= 0) return;

    const from = -math.pi / 2;
    final sweep = 2 * math.pi * swept;
    final light = Color.lerp(color, Colors.white, 0.34)!;

    if (glow) {
      canvas.drawArc(
        rect,
        from,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    canvas.drawArc(
      rect,
      from,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [color, light, color],
          stops: const [0.0, 0.55, 1.0],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );

    if (ghostTail && swept < 1) {
      // Dotted, drawn as short segments so it never competes with the arc.
      final dotPaint =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke * 0.62
            ..strokeCap = StrokeCap.round
            ..color = color.withValues(alpha: 0.26);
      final tailStart = from + sweep;
      final tailSweep = 2 * math.pi - sweep;
      // One dot every ~11 degrees, with the first cleared of the arc's cap.
      const step = 0.19;
      for (var a = tailStart + 0.16; a < tailStart + tailSweep - 0.06; a += step) {
        canvas.drawArc(rect, a, 0.012, false, dotPaint);
      }
    }

    if (capDot && swept > 0 && swept < 1) {
      final angle = from + sweep;
      canvas.drawCircle(
        centre + Offset(math.cos(angle) * radius, math.sin(angle) * radius),
        stroke * 0.52,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.track != track ||
      old.glow != glow ||
      old.ghostTail != ghostTail ||
      old.capDot != capDot;
}
