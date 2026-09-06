import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/meal.dart';

class EditMealModal extends StatefulWidget {
  final Meal meal;
  final Function(Meal) onSave;
  final VoidCallback onDelete;
  final VoidCallback? onCancel;
  final bool isNew;

  const EditMealModal({
    super.key,
    required this.meal,
    required this.onSave,
    required this.onDelete,
    this.onCancel,
    this.isNew = false,
  });

  @override
  State<EditMealModal> createState() => _EditMealModalState();
}

class _EditMealModalState extends State<EditMealModal> {
  late TextEditingController _nameController;
  late TextEditingController _caloriesController;
  late TextEditingController _portionController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late String _mealType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meal.foodName);
    _caloriesController = TextEditingController(
      text: _initialNumber(widget.meal.calories),
    );
    _portionController = TextEditingController(text: widget.meal.portion ?? '');
    _proteinController = TextEditingController(
      text: _initialNumber(widget.meal.macros.protein),
    );
    _carbsController = TextEditingController(
      text: _initialNumber(widget.meal.macros.carbs),
    );
    _fatController = TextEditingController(
      text: _initialNumber(widget.meal.macros.fat),
    );
    const mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
    final initialType = widget.meal.mealType?.toLowerCase();
    _mealType = mealTypes.firstWhere(
      (type) => type.toLowerCase() == initialType,
      orElse: () => 'Snack',
    );
  }

  String _initialNumber(int value) {
    return widget.isNew && value == 0 ? '' : value.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _portionController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final updatedMeal = widget.meal.copyWith(
      foodName:
          _nameController.text.isEmpty
              ? AppLocalizations.of(context)!.log_unknown_food
              : _nameController.text,
      calories: int.tryParse(_caloriesController.text) ?? 0,
      portion: _portionController.text,
      mealType: _mealType,
      macros: widget.meal.macros.copyWith(
        protein: int.tryParse(_proteinController.text) ?? 0,
        carbs: int.tryParse(_carbsController.text) ?? 0,
        fat: int.tryParse(_fatController.text) ?? 0,
      ),
    );
    widget.onSave(updatedMeal);
  }

  bool get _canSave {
    if (!widget.isNew) return true;
    return _nameController.text.trim().isNotEmpty &&
        (int.tryParse(_caloriesController.text) ?? 0) > 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final surfaceColor =
        isDark ? const Color(0xFF1C1B1E) : const Color(0xFFFCFCFA);
    final availableHeight =
        media.size.height - media.padding.top - media.viewInsets.bottom - 12;
    final sheetHeight = math.min(media.size.height * 0.88, availableHeight);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                width: 34,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 14, 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.isNew ? LucideIcons.plus : LucideIcons.pencil,
                      size: 19,
                      color: context.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isNew ? l10n.log_log_new_meal : l10n.log_edit_meal,
                      style: AppTypography.titleMedium.copyWith(
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: widget.onCancel ?? () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                    color: context.textSecondaryColor,
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.dividerColor),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MealTypeSelector(
                      selectedType: _mealType,
                      onSelected: (type) => setState(() => _mealType = type),
                    ),
                    const SizedBox(height: 20),
                    _MealTextField(
                      controller: _nameController,
                      label: l10n.log_food_name,
                      hint: l10n.log_food_hint,
                      icon: LucideIcons.utensils,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    _MealTextField(
                      controller: _portionController,
                      label: l10n.log_portion_desc,
                      hint: l10n.log_portion_hint,
                      icon: LucideIcons.scale,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.activity,
                          size: 17,
                          color: context.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.result_macronutrients,
                          style: AppTypography.titleSmall.copyWith(
                            color: context.textPrimaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _NutritionPanel(
                      caloriesController: _caloriesController,
                      proteinController: _proteinController,
                      carbsController: _carbsController,
                      fatController: _fatController,
                      onCaloriesChanged: (_) => setState(() {}),
                    ),
                    if (!widget.isNew &&
                        widget.meal.id != 'temp' &&
                        widget.meal.id != 'new') ...[
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => _showDeleteConfirmation(context),
                        icon: const Icon(LucideIcons.trash2, size: 17),
                        label: Text(l10n.log_delete_entry),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                math.max(12, media.padding.bottom),
              ),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(top: BorderSide(color: context.dividerColor)),
              ),
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _canSave ? _handleSave : null,
                  icon: const Icon(LucideIcons.check, size: 19),
                  label: Text(l10n.log_save_entry),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    disabledBackgroundColor: context.primaryColor.withValues(
                      alpha: 0.28,
                    ),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white.withValues(
                      alpha: 0.8,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
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

  void _showDeleteConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: context.surfaceContainerColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              l10n.log_delete_meal_title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
            ),
            content: Text(
              l10n.log_delete_meal_body,
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.common_keep_it),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDelete();
                },
                child: Text(
                  l10n.common_delete,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

class _MealTypeSelector extends StatelessWidget {
  const _MealTypeSelector({
    required this.selectedType,
    required this.onSelected,
  });

  final String selectedType;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      ('Breakfast', l10n.result_meal_breakfast, LucideIcons.coffee),
      ('Lunch', l10n.result_meal_lunch, LucideIcons.sun),
      ('Dinner', l10n.result_meal_dinner, LucideIcons.moon),
      ('Snack', l10n.result_meal_snack, LucideIcons.apple),
    ];

    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color:
            context.isDarkMode
                ? Colors.white.withValues(alpha: 0.04)
                : const Color(0xFFF1F2EF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: Semantics(
                selected: selectedType == option.$1,
                button: true,
                child: InkWell(
                  onTap: () => onSelected(option.$1),
                  borderRadius: BorderRadius.circular(6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    decoration: BoxDecoration(
                      color:
                          selectedType == option.$1
                              ? context.surfaceContainerColor
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow:
                          selectedType == option.$1
                              ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 5,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                              : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          option.$3,
                          size: 15,
                          color:
                              selectedType == option.$1
                                  ? context.primaryColor
                                  : context.textMutedColor,
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            option.$2,
                            style: AppTypography.labelSmall.copyWith(
                              color:
                                  selectedType == option.$1
                                      ? context.textPrimaryColor
                                      : context.textSecondaryColor,
                              fontWeight:
                                  selectedType == option.$1
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MealTextField extends StatelessWidget {
  const _MealTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.textInputAction,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: context.textSecondaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          textInputAction: textInputAction,
          onChanged: onChanged,
          style: AppTypography.bodyMedium.copyWith(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: context.textMutedColor),
            filled: true,
            fillColor:
                context.isDarkMode
                    ? Colors.white.withValues(alpha: 0.035)
                    : Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.cardBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.primaryColor, width: 1.4),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _NutritionPanel extends StatelessWidget {
  const _NutritionPanel({
    required this.caloriesController,
    required this.proteinController,
    required this.carbsController,
    required this.fatController,
    required this.onCaloriesChanged,
  });

  final TextEditingController caloriesController;
  final TextEditingController proteinController;
  final TextEditingController carbsController;
  final TextEditingController fatController;
  final ValueChanged<String> onCaloriesChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            context.isDarkMode
                ? Colors.white.withValues(alpha: 0.03)
                : const Color(0xFFF7F8F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.flame,
                  size: 18,
                  color: context.primaryColor,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  l10n.log_calories_kcal,
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              SizedBox(
                width: 112,
                child: _NumberField(
                  controller: caloriesController,
                  suffix: l10n.settings_kcal_unit,
                  onChanged: onCaloriesChanged,
                  emphasized: true,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Divider(height: 1, color: context.dividerColor),
          ),
          Row(
            children: [
              Expanded(
                child: _MacroNumberField(
                  label: l10n.result_protein,
                  controller: proteinController,
                  color: AppColors.protein,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MacroNumberField(
                  label: l10n.result_carbs,
                  controller: carbsController,
                  color: AppColors.carbs,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MacroNumberField(
                  label: l10n.result_fat,
                  controller: fatController,
                  color: AppColors.fat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroNumberField extends StatelessWidget {
  const _MacroNumberField({
    required this.label,
    required this.controller,
    required this.color,
  });

  final String label;
  final TextEditingController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(
                  color: context.textSecondaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _NumberField(controller: controller, suffix: 'g'),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.suffix,
    this.onChanged,
    this.emphasized = false,
  });

  final TextEditingController controller;
  final String suffix;
  final ValueChanged<String>? onChanged;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      textAlign: TextAlign.center,
      style: AppTypography.titleSmall.copyWith(
        color: context.textPrimaryColor,
        fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
        fontSize: emphasized ? 16 : 14,
      ),
      decoration: InputDecoration(
        hintText: '0',
        suffixText: suffix,
        suffixStyle: AppTypography.labelSmall.copyWith(
          color: context.textMutedColor,
          fontSize: 10,
        ),
        filled: true,
        fillColor:
            context.isDarkMode
                ? Colors.black.withValues(alpha: 0.12)
                : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.cardBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.primaryColor, width: 1.4),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
    );
  }
}
