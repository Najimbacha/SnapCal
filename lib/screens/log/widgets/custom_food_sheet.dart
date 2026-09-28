import '../../../widgets/pinned_footer_sheet.dart';
import '../../../core/theme/app_button_theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/wazn_icons.dart';

/// What the user typed for a food of their own.
typedef CustomFoodEntry =
    ({
      String name,
      int calories,
      String portion,
      int protein,
      int carbs,
      int fat,
      String mealType,
    });

/// A short form for a food the search doesn't know: a name and the calories
/// are all it needs. The amount is optional, protein, carbs and fat are
/// tucked away until asked for, and the meal starts on [mealType].
Future<CustomFoodEntry?> showCustomFoodSheet(
  BuildContext context, {
  String initialName = '',
  required String mealType,
  bool showMealType = true,
  String? actionLabel,
}) {
  return showModalBottomSheet<CustomFoodEntry>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (_) => CustomFoodSheet(
          initialName: initialName,
          mealType: mealType,
          showMealType: showMealType,
          actionLabel: actionLabel,
        ),
  );
}

class CustomFoodSheet extends StatefulWidget {
  const CustomFoodSheet({
    super.key,
    this.initialName = '',
    required this.mealType,
    this.showMealType = true,
    this.actionLabel,
  });

  final String initialName;
  final String mealType;
  final bool showMealType;
  final String? actionLabel;

  @override
  State<CustomFoodSheet> createState() => _CustomFoodSheetState();
}

const _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

class _CustomFoodSheetState extends State<CustomFoodSheet> {
  late final _name = TextEditingController(text: widget.initialName);
  final _calories = TextEditingController();
  final _portion = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  late String _mealType =
      _mealTypes.contains(widget.mealType) ? widget.mealType : 'Snack';
  bool _showMacros = false;
  bool _added = false;

  @override
  void dispose() {
    for (final c in [_name, _calories, _portion, _protein, _carbs, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  /// A name and a calorie figure. Zero counts: black coffee is a real entry.
  bool get _canAdd =>
      _name.text.trim().isNotEmpty &&
      int.tryParse(_calories.text.trim()) != null;

  Future<void> _add() async {
    if (!_canAdd || _added) return;
    HapticFeedback.lightImpact();
    final name = _name.text.trim();
    final entry = (
      name: name[0].toUpperCase() + name.substring(1),
      calories: int.parse(_calories.text.trim()),
      portion: _portion.text.trim(),
      protein: int.tryParse(_protein.text.trim()) ?? 0,
      carbs: int.tryParse(_carbs.text.trim()) ?? 0,
      fat: int.tryParse(_fat.text.trim()) ?? 0,
      mealType: _mealType,
    );
    // A tick on the button first, then the sheet goes.
    if (!AppMotion.reduceMotion(context)) {
      setState(() => _added = true);
      await Future<void>.delayed(const Duration(milliseconds: 420));
    }
    if (mounted) Navigator.pop(context, entry);
  }

  String _mealLabel(AppLocalizations l10n, String type) => switch (type) {
    'Breakfast' => l10n.result_meal_breakfast,
    'Lunch' => l10n.result_meal_lunch,
    'Dinner' => l10n.result_meal_dinner,
    _ => l10n.result_meal_snack,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    final hasName = widget.initialName.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        // While typing, the fields scroll and Add stays right above the
        // keyboard.
        child: PinnedFooterSheet(
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: context.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.custom_food_title,
                      style: AppTypography.titleLarge.copyWith(
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(WaznIcons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _Field(
                fieldKey: const ValueKey('custom-food-name'),
                label: l10n.custom_food_name,
                hint: l10n.log_food_hint,
                controller: _name,
                autofocus: !hasName,
                capitalize: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Field(
                      fieldKey: const ValueKey('custom-food-kcal'),
                      label: l10n.result_calories,
                      hint: '0',
                      suffix: l10n.settings_kcal_unit,
                      controller: _calories,
                      autofocus: hasName,
                      number: true,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                      fieldKey: const ValueKey('custom-food-portion'),
                      label: l10n.custom_food_amount,
                      hint: l10n.custom_food_amount_hint,
                      controller: _portion,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Protein, carbs and fat unfold only when asked for.
              AnimatedSize(
                duration: AppMotion.maybeZero(context, AppMotion.standard),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child:
                    _showMacros
                        ? Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              for (final (i, (label, c))
                                  in [
                                    (l10n.result_protein, _protein),
                                    (l10n.result_carbs, _carbs),
                                    (l10n.result_fat, _fat),
                                  ].indexed) ...[
                                if (i > 0) const SizedBox(width: 10),
                                Expanded(
                                  child: _Field(
                                    label: label,
                                    hint: '0',
                                    suffix: 'g',
                                    controller: c,
                                    number: true,
                                    autofocus: i == 0,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                        : Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            key: const ValueKey('custom-food-macros'),
                            onPressed: () => setState(() => _showMacros = true),
                            icon: const Icon(WaznIcons.plus, size: 16),
                            label: Text(l10n.custom_food_macros),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                            ),
                          ),
                        ),
              ),
              const SizedBox(height: 12),
              if (widget.showMealType)
                Row(
                  children: [
                    for (final (i, type) in _mealTypes.indexed) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: _MealChoice(
                          label: _mealLabel(l10n, type),
                          selected: type == _mealType,
                          onTap: () => setState(() => _mealType = type),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
          footer: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: appButtonHeight,
                child: FilledButton(
                  key: const ValueKey('custom-food-add'),
                  onPressed: _canAdd ? _add : null,
                  child: AnimatedSwitcher(
                    duration: AppMotion.standard,
                    transitionBuilder:
                        (child, animation) => ScaleTransition(
                          scale: CurvedAnimation(
                            parent: animation,
                            curve: AppMotion.springCurve,
                          ),
                          child: child,
                        ),
                    child:
                        _added
                            ? const Icon(
                              WaznIcons.check,
                              key: ValueKey('custom-food-added'),
                              size: 24,
                            )
                            : Text(
                              widget.actionLabel ??
                                  l10n.custom_food_add_to(
                                    _mealLabel(l10n, _mealType),
                                  ),
                              key: ValueKey(_mealType),
                            ),
                  ),
                ),
              ),
              if (!PinnedFooterSheet.keyboardOpen(context)) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.custom_food_note,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.textMutedColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    this.fieldKey,
    required this.label,
    required this.hint,
    required this.controller,
    this.suffix,
    this.number = false,
    this.autofocus = false,
    this.capitalize = false,
    this.onChanged,
  });

  final Key? fieldKey;
  final String label;
  final String hint;
  final String? suffix;
  final TextEditingController controller;
  final bool number;
  final bool autofocus;
  final bool capitalize;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => AppTextField(
    fieldKey: fieldKey,
    label: label,
    hint: hint,
    unit: suffix,
    controller: controller,
    autofocus: autofocus,
    onChanged: onChanged,
    keyboardType: number ? TextInputType.number : TextInputType.text,
    inputFormatters: number ? [FilteringTextInputFormatter.digitsOnly] : null,
    textCapitalization:
        capitalize ? TextCapitalization.sentences : TextCapitalization.none,
    textInputAction: TextInputAction.next,
  );
}

class _MealChoice extends StatelessWidget {
  const _MealChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = context.primaryColor;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.maybeZero(context, AppMotion.standard),
          curve: Curves.easeOutCubic,
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? primary : context.cardColor,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color:
                  selected
                      ? primary
                      : context.dividerColor.withValues(alpha: .6),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: AppTypography.labelLarge.copyWith(
                color:
                    selected
                        ? context.onPrimaryColor
                        : context.textSecondaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
