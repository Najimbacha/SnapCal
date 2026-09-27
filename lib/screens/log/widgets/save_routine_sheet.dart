import '../../../core/theme/app_button_theme.dart';
import 'package:flutter/material.dart';
import '../../../widgets/app_text_field.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import 'package:snapcal/core/theme/app_colors.dart';
import 'package:snapcal/core/theme/app_motion.dart';
import 'package:snapcal/core/theme/app_typography.dart';
import 'package:snapcal/core/theme/theme_colors.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/models/meal_template.dart';
import 'package:snapcal/data/services/premium_conversion_service.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/providers/template_provider.dart';
import '../../../widgets/wazn_icons.dart';

/// Opens the save panel for one meal's foods and returns the routine saved,
/// or null if nothing was.
Future<MealTemplate?> showSaveRoutineSheet(
  BuildContext context, {
  required List<Meal> meals,
  required String mealType,
  required String mealLabel,
}) {
  return showModalBottomSheet<MealTemplate>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder:
        (_) => SaveRoutineSheet(
          meals: meals,
          mealType: mealType,
          mealLabel: mealLabel,
        ),
  );
}

/// Saves a meal's foods as a routine: an emoji picked from a row with a
/// sliding highlight, a name, and the foods to include, ticked by default.
/// Save draws a tick before the panel closes. A free account at its limit
/// sees a note about Pro instead.
class SaveRoutineSheet extends ConsumerStatefulWidget {
  final List<Meal> meals;
  final String mealType;
  final String mealLabel;

  const SaveRoutineSheet({
    super.key,
    required this.meals,
    required this.mealType,
    required this.mealLabel,
  });

  @override
  ConsumerState<SaveRoutineSheet> createState() => _SaveRoutineSheetState();
}

class _SaveRoutineSheetState extends ConsumerState<SaveRoutineSheet> {
  static const _emojis = [
    '🥣',
    '🍳',
    '🥗',
    '🥪',
    '☕',
    '🍎',
    '🍝',
    '🍗',
    '🥤',
    '🍽️',
  ];
  static const _cell = 42.0;
  static const _gap = 8.0;

  late final TextEditingController _name;
  late final Set<int> _included = {
    for (var i = 0; i < widget.meals.length; i++) i,
  };
  int _emoji = 0;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _emoji = switch (widget.mealType) {
      'Breakfast' => 0,
      'Lunch' => 2,
      'Dinner' => 7,
      _ => 5,
    };
    _name = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_name.text.isEmpty) {
      _name.text = AppLocalizations.of(
        context,
      )!.routine_name_default(widget.mealLabel.toLowerCase());
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _included.isEmpty || _saving) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    final template = await ref
        .read(templatesProvider.notifier)
        .saveTemplate(
          name: name,
          emoji: _emojis[_emoji],
          meals: [
            for (var i = 0; i < widget.meals.length; i++)
              if (_included.contains(i)) widget.meals[i],
          ],
          mealType: widget.mealType,
        );
    if (!mounted) return;
    setState(() => _saved = true);
    // Let the tick be seen before the panel goes.
    if (!AppMotion.reduceMotion(context)) {
      await Future<void>.delayed(const Duration(milliseconds: 650));
    }
    if (mounted) Navigator.pop(context, template);
  }

  void _openPro() {
    Navigator.pop(context);
    PremiumConversionService().openPaywall(
      context,
      PaywallEntryPoint.settings,
      featureName: 'routines',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final isPro = ref.watch(effectiveIsProProvider);
    final used = ref.watch(templatesProvider).valueOrNull?.length ?? 0;
    final canAdd = ref.read(templatesProvider.notifier).canAddTemplate(isPro);
    final line = context.dividerColor.withValues(alpha: 0.35);
    final deep = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857);

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        20 +
            MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1B1F) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: context.textMutedColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              l10n.routine_save_as,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.routine_save_body(_included.length),
              style: AppTypography.bodySmall.copyWith(
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 14),
            if (!canAdd) ...[
              _LimitNote(
                used: used,
                onPro: _openPro,
                key: const ValueKey('routine-limit'),
              ),
              const SizedBox(height: 12),
            ],
            Opacity(
              opacity: canAdd ? 1 : .45,
              child: IgnorePointer(
                ignoring: !canAdd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emojis, with a highlight that springs to the pick.
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: _emojis.length * (_cell + _gap) - _gap,
                        height: _cell,
                        child: Stack(
                          children: [
                            AnimatedPositionedDirectional(
                              duration: AppMotion.maybeZero(
                                context,
                                const Duration(milliseconds: 420),
                              ),
                              curve: AppMotion.springCurve,
                              start: _emoji * (_cell + _gap),
                              top: 0,
                              width: _cell,
                              height: _cell,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: .14,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: deep, width: 2),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                for (var i = 0; i < _emojis.length; i++) ...[
                                  if (i > 0) const SizedBox(width: _gap),
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _emoji = i);
                                    },
                                    child: Container(
                                      width: _cell,
                                      height: _cell,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color:
                                              i == _emoji
                                                  ? Colors.transparent
                                                  : line,
                                        ),
                                      ),
                                      child: Text(
                                        _emojis[i],
                                        style: const TextStyle(fontSize: 21),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      fieldKey: const ValueKey('routine-name'),
                      controller: _name,
                      maxLength: 40,
                      textCapitalization: TextCapitalization.sentences,
                      label: l10n.custom_food_name,
                      hint: l10n.feature_templates_name_hint,
                    ),
                    const SizedBox(height: 12),
                    // The foods, each of which can be left out.
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: line),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < widget.meals.length; i++) ...[
                            if (i > 0) Divider(height: 1, color: line),
                            InkWell(
                              onTap:
                                  () => setState(
                                    () =>
                                        _included.contains(i)
                                            ? _included.remove(i)
                                            : _included.add(i),
                                  ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color:
                                            _included.contains(i)
                                                ? AppColors.primary
                                                : Colors.transparent,
                                        borderRadius: BorderRadius.circular(7),
                                        border: Border.all(
                                          color:
                                              _included.contains(i)
                                                  ? AppColors.primary
                                                  : context.textMutedColor,
                                        ),
                                      ),
                                      child:
                                          _included.contains(i)
                                              ? const Icon(
                                                WaznIcons.check,
                                                size: 14,
                                                color: Colors.white,
                                              )
                                              : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        widget.meals[i].foodName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: context.textPrimaryColor,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      '${widget.meals[i].calories}',
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: context.textPrimaryColor,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Save; it shrinks to a round tick once saved.
            Center(
              child: LayoutBuilder(
                builder:
                    (context, constraints) => AnimatedContainer(
                      key: const ValueKey('routine-save'),
                      duration: AppMotion.maybeZero(
                        context,
                        const Duration(milliseconds: 340),
                      ),
                      curve: Curves.easeOutCubic,
                      width: _saved ? appButtonHeight : constraints.maxWidth,
                      height: appButtonHeight,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: context.primaryColor,
                        borderRadius: BorderRadius.circular(
                          _saved ? appButtonHeight / 2 : appButtonRadius,
                        ),
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          onTap: canAdd ? _save : _openPro,
                          child: Center(
                            child:
                                _saved
                                    ? Icon(
                                      WaznIcons.check,
                                      color: context.onPrimaryColor,
                                      size: 24,
                                    )
                                    : FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        canAdd
                                            ? l10n.feature_templates_save_btn
                                            : l10n.routine_get_pro,
                                        style: AppTypography.titleSmall
                                            .copyWith(
                                              color: context.onPrimaryColor,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                      ),
                                    ),
                          ),
                        ),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The free plan's routines are all used: a friendly note, not an error.
class _LimitNote extends StatelessWidget {
  const _LimitNote({super.key, required this.used, required this.onPro});

  final int used;
  final VoidCallback onPro;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const amber = Color(0xFFB45309);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.maybeZero(context, const Duration(milliseconds: 480)),
      curve: AppMotion.springCurve,
      builder:
          (context, t, child) => Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(scale: .92 + .08 * t, child: child),
          ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(WaznIcons.lock, color: amber, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.routine_limit_title('$used', '${Templates.freeLimit}'),
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  Text(
                    l10n.routine_limit_body,
                    style: AppTypography.bodySmall.copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onPro,
              style: FilledButton.styleFrom(
                backgroundColor: context.textPrimaryColor,
                foregroundColor: context.surfaceColor,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(l10n.routine_get_pro),
            ),
          ],
        ),
      ),
    );
  }
}
