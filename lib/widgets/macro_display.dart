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
