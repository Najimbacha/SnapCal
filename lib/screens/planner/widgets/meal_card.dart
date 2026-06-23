import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/meal.dart';

Color _mealColor(String? type) {
  switch (type?.toLowerCase()) {
    case 'breakfast': return const Color(0xFFF59E0B);
    case 'lunch': return const Color(0xFF10B981);
    case 'dinner': return const Color(0xFF6366F1);
    case 'snack': return const Color(0xFFEC4899);
    default: return const Color(0xFF6366F1);
  }
}

String _mealLabel(BuildContext context, String? type) {
  final l = AppLocalizations.of(context)!;
  switch (type?.toLowerCase()) {
    case 'breakfast': return l.result_meal_breakfast;
    case 'lunch': return l.result_meal_lunch;
    case 'dinner': return l.result_meal_dinner;
    case 'snack': return l.result_meal_snack;
    default: return type ?? l.planner_meal;
  }
}

class MealCard extends StatefulWidget {
  final Meal meal;
  final bool isLocked;
  final bool isLogged;
  final VoidCallback? onLogMeal;
  final VoidCallback? onSwapMeal;

  const MealCard({super.key, required this.meal, this.isLocked = false, this.isLogged = false, this.onLogMeal, this.onSwapMeal});

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  bool _expanded = false;

  bool get _hasDetails {
    final m = widget.meal;
    return m.macros.protein > 0 || m.macros.carbs > 0 || m.macros.fat > 0 || (m.ingredients?.isNotEmpty == true) || (m.aiRationale?.trim().isNotEmpty == true);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLocked) return _locked(context);
    final m = widget.meal;
    final color = _mealColor(m.mealType);
    final label = _mealLabel(context, m.mealType);
    var meta = label;
    if (m.prepTimeMins != null && m.prepTimeMins! > 0) meta += ' \u00b7 ${m.prepTimeMins}min';
    if (widget.isLogged) meta += ' \u00b7 ${AppLocalizations.of(context)!.planner_logged.toLowerCase()}';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: context.cardSoftColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _hasDetails ? () => setState(() => _expanded = !_expanded) : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 12, 0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                  child: Row(
                    children: [
                      Container(width: 3, height: 36, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: context.textMutedColor)),
                            const SizedBox(height: 2),
                            Text(m.foodName, maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimaryColor, height: 1.2)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${m.calories}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
                      const SizedBox(width: 2),
                      Text('kcal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: context.textMutedColor)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: widget.isLogged ? null : widget.onLogMeal,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: widget.isLogged ? AppColors.success.withValues(alpha: 0.1) : context.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(widget.isLogged ? LucideIcons.check : Icons.add_rounded, size: 16, color: widget.isLogged ? AppColors.success : context.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_expanded && _hasDetails) ...[
                  Divider(height: 1, color: context.cardBorderColor, indent: 12, endIndent: 12),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 0, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _macro('P', m.macros.protein, const Color(0xFF3B82F6)),
                            const SizedBox(width: 8),
                            _macro('C', m.macros.carbs, const Color(0xFFF59E0B)),
                            const SizedBox(width: 8),
                            _macro('F', m.macros.fat, const Color(0xFFEC4899)),
                            const Spacer(),
                            if (widget.onSwapMeal != null)
                              GestureDetector(
                                onTap: widget.onSwapMeal,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: context.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.refreshCw, size: 12, color: context.primaryColor),
                                      const SizedBox(width: 4),
                                      Text('Swap', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.primaryColor)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (m.ingredients?.isNotEmpty == true) ...[
                          const SizedBox(height: 10),
                          Text(m.ingredients!.join(', '), style: TextStyle(fontSize: 12, color: context.textSecondaryColor, fontWeight: FontWeight.w500)),
                        ],
                        if (m.aiRationale?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          Text(m.aiRationale!.trim(), style: TextStyle(fontSize: 12, color: context.textSecondaryColor, fontStyle: FontStyle.italic, fontWeight: FontWeight.w400)),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _macro(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 3),
          Text('${value}g', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        ],
      ),
    );
  }

  Widget _locked(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(color: context.cardSoftColor, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(LucideIcons.lock, size: 14, color: context.textMutedColor),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.meal.foodName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: context.textSecondaryColor, fontWeight: FontWeight.w500))),
          Text('${widget.meal.calories}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textMutedColor)),
          const SizedBox(width: 2),
          Text('kcal', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: context.textMutedColor)),
        ],
      ),
    );
  }
}


