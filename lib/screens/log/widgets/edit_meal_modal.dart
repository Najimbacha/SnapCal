import 'package:flutter/material.dart';
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

  const EditMealModal({
    super.key,
    required this.meal,
    required this.onSave,
    required this.onDelete,
    this.onCancel,
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meal.foodName);
    _caloriesController = TextEditingController(
      text: widget.meal.calories.toString(),
    );
    _portionController = TextEditingController(text: widget.meal.portion ?? '');
    _proteinController = TextEditingController(
      text: widget.meal.macros.protein.toString(),
    );
    _carbsController = TextEditingController(
      text: widget.meal.macros.carbs.toString(),
    );
    _fatController = TextEditingController(
      text: widget.meal.macros.fat.toString(),
    );
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
      macros: widget.meal.macros.copyWith(
        protein: int.tryParse(_proteinController.text) ?? 0,
        carbs: int.tryParse(_carbsController.text) ?? 0,
        fat: int.tryParse(_fatController.text) ?? 0,
      ),
    );
    widget.onSave(updatedMeal);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? const Color(0xFF1C1B1E)
        : const Color(0xFFFCFCFA);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.log_edit_meal,
                  style: AppTypography.titleMedium.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  onPressed:
                      widget.onCancel ?? () => Navigator.pop(context),
                  icon: Icon(LucideIcons.x),
                  color: isDark ? Colors.white54 : const Color(0xFFA8A29E),
                  iconSize: 20,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Calorie field
            _compactInput(
              context: context,
              controller: _caloriesController,
              label: l10n.log_calories_kcal,
              suffix: l10n.settings_kcal_unit,
              center: true,
              large: true,
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            // Food name
            _compactInput(
              context: context,
              controller: _nameController,
              label: l10n.log_food_name,
              hint: l10n.log_food_hint,
              isDark: isDark,
            ),
            const SizedBox(height: 12),

            // Portion
            _compactInput(
              context: context,
              controller: _portionController,
              label: l10n.log_portion_desc,
              hint: l10n.log_portion_hint,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Macros
            Text(
              l10n.result_macronutrients,
              style: AppTypography.labelSmall.copyWith(
                color: isDark ? Colors.white38 : const Color(0xFFB4AFA8),
                fontWeight: FontWeight.w500,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _macroField(l10n.result_protein, _proteinController, const Color(0xFF7C9A6D), isDark, context),
                const SizedBox(width: 8),
                _macroField(l10n.result_carbs, _carbsController, const Color(0xFF4F8CC9), isDark, context),
                const SizedBox(width: 8),
                _macroField(l10n.result_fat, _fatController, const Color(0xFFD18B47), isDark, context),
              ],
            ),
            const SizedBox(height: 20),

            // Save
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.log_save_entry,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            // Delete
            if (widget.meal.id != 'temp' && widget.meal.id != 'new') ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => _showDeleteConfirmation(context),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.log_delete_entry,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
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
              borderRadius: BorderRadius.circular(20),
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

Widget _compactInput({
  required BuildContext context,
  required TextEditingController controller,
  required String label,
  String? hint,
  String? suffix,
  bool center = false,
  bool large = false,
  required bool isDark,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: isDark ? Colors.white38 : const Color(0xFFB4AFA8),
          fontWeight: FontWeight.w500,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: large ? TextInputType.number : null,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: AppTypography.bodyMedium.copyWith(
          color: context.textPrimaryColor,
          fontWeight: large ? FontWeight.w700 : FontWeight.w500,
          fontSize: large ? 28 : 15,
          height: 1.2,
        ),
        decoration: InputDecoration(
          hintText: hint,
          suffixText: suffix,
          suffixStyle: TextStyle(
            color: isDark ? Colors.white38 : const Color(0xFFB4AFA8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: center ? 16 : 14,
            vertical: large ? 10 : 12,
          ),
        ),
      ),
    ],
  );
}

Widget _macroField(String label, TextEditingController controller, Color color, bool isDark, BuildContext context) {
  return Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: AppTypography.titleSmall.copyWith(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 15,
            height: 1.0,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ),
          ),
        ),
      ],
    ),
  );
}

