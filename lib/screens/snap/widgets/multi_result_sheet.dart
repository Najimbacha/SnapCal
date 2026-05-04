import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/gemini_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import '../../../../widgets/ad_banner.dart';

/// Bottom sheet showing multiple detected food items with selection toggles.
class MultiResultSheet extends StatefulWidget {
  final List<NutritionResult> results;
  final Function(List<NutritionResult> selected) onSaveAll;
  final VoidCallback onCancel;

  const MultiResultSheet({
    super.key,
    required this.results,
    required this.onSaveAll,
    required this.onCancel,
  });

  @override
  State<MultiResultSheet> createState() => _MultiResultSheetState();
}

class _MultiResultSheetState extends State<MultiResultSheet> {
  List<bool> _selected = [];
  List<double> _multipliers = [];

  @override
  void initState() {
    super.initState();
    _selected = List.filled(widget.results.length, true);
    _multipliers = List.filled(widget.results.length, 1.0);
  }

  int get _selectedCount => _selected.where((s) => s).length;

  int get _totalCalories {
    double total = 0;
    // Safety check for Hot Reload
    if (_selected.length != widget.results.length || _multipliers.length != widget.results.length) {
      return 0;
    }
    for (int i = 0; i < widget.results.length; i++) {
      if (_selected[i]) {
        total += widget.results[i].calories * _multipliers[i];
      }
    }
    return total.round();
  }

  @override
  Widget build(BuildContext context) {
    // Safety check for Hot Reload: Ensure state lists match current results length
    if (_selected.length != widget.results.length) {
      _selected = List.filled(widget.results.length, true);
    }
    if (_multipliers.length != widget.results.length) {
      _multipliers = List.filled(widget.results.length, 1.0);
    }

    return Container(
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36, height: 5,
              decoration: BoxDecoration(
                color: context.textMutedColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Premium Header ──
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.scanLine, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.snap_bento_plate,
                      style: AppTypography.heading3.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      AppLocalizations.of(context)!.snap_items_detected(widget.results.length),
                      style: AppTypography.bodySmall.copyWith(color: context.textSecondaryColor),
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),

          const SizedBox(height: 24),

          // ── Items List (The Tray) ──
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.results.length, (i) {
                  final r = widget.results[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FoodItemCard(
                      result: r,
                      isSelected: _selected[i],
                      multiplier: _multipliers[i],
                      onToggle: () => setState(() => _selected[i] = !_selected[i]),
                      onMultiplierChanged: (val) => setState(() => _multipliers[i] = val),
                    ),
                  ).animate().fadeIn(delay: (i * 100).ms, duration: 400.ms).slideX(begin: 0.05);
                }),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const AdBanner().animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 12),

          // ── Total Summary ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.textMutedColor.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.snap_total_meal,
                      style: AppTypography.labelSmall.copyWith(
                        color: context.textSecondaryColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.snap_items_selected(_selectedCount),
                      style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  '$_totalCalories kcal',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

          const SizedBox(height: 24),

          // ── Action Buttons ──
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onCancel();
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.common_cancel,
                    style: AppTypography.bodyLarge.copyWith(
                      color: context.textSecondaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: FilledButton(
                    onPressed: _selectedCount > 0
                        ? () {
                            final selectedResults = <NutritionResult>[];
                            for (int i = 0; i < widget.results.length; i++) {
                              if (_selected[i]) {
                                final m = _multipliers[i];
                                final base = widget.results[i];
                                selectedResults.add(NutritionResult(
                                  foodName: base.foodName,
                                  portion: base.portion,
                                  calories: (base.calories * m).round(),
                                  protein: (base.protein * m).round(),
                                  carbs: (base.carbs * m).round(),
                                  fat: (base.fat * m).round(),
                                ));
                              }
                            }
                            Navigator.pop(context);
                            widget.onSaveAll(selectedResults);
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.snap_log_meal,
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }
}

class _FoodItemCard extends StatelessWidget {
  final NutritionResult result;
  final bool isSelected;
  final double multiplier;
  final VoidCallback onToggle;
  final ValueChanged<double> onMultiplierChanged;

  const _FoodItemCard({
    required this.result,
    required this.isSelected,
    required this.multiplier,
    required this.onToggle,
    required this.onMultiplierChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withValues(alpha: 0.05) 
              : context.cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary.withValues(alpha: 0.3) 
                : context.textMutedColor.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          children: [
            // ── Selection Indicator ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : context.textMutedColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: isSelected 
                  ? const Icon(Icons.check, size: 18, color: Colors.white) 
                  : null,
            ),
            const SizedBox(width: 16),

            // ── Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.foodName,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? context.textPrimaryColor : context.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    children: [
                      _MacroDot(value: (result.protein * multiplier).round(), color: AppColors.protein),
                      _MacroDot(value: (result.carbs * multiplier).round(), color: AppColors.carbs),
                      _MacroDot(value: (result.fat * multiplier).round(), color: AppColors.fat),
                    ],
                  ),
                ],
              ),
            ),

            // ── Multiplier & Cal ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(result.calories * multiplier).round()}',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isSelected ? AppColors.primary : context.textSecondaryColor,
                  ),
                ),
                Text(
                  'kcal',
                  style: AppTypography.labelSmall.copyWith(color: context.textSecondaryColor),
                ),
                if (isSelected) ...[
                  const SizedBox(height: 8),
                  _QuantityControls(
                    value: multiplier,
                    onChanged: onMultiplierChanged,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityControls extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _QuantityControls({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qBtn(LucideIcons.minus, () {
            HapticFeedback.lightImpact();
            if (value > 0.5) onChanged(value - 0.5);
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${value.toStringAsFixed(1)}x',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                fontSize: 10,
              ),
            ),
          ),
          _qBtn(LucideIcons.plus, () {
            HapticFeedback.lightImpact();
            if (value < 5.0) onChanged(value + 0.5);
          }),
        ],
      ),
    );
  }

  Widget _qBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Icon(icon, size: 12, color: AppColors.primary),
      ),
    );
  }
}

class _MacroDot extends StatelessWidget {
  final int value;
  final Color color;
  const _MacroDot({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5, height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '${value}g',
          style: AppTypography.labelSmall.copyWith(
            color: context.textSecondaryColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
