import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/meal.dart';
import '../../../data/services/gemini_service.dart';
import '../../../data/services/premium_conversion_service.dart';
import '../../../providers/settings_provider.dart';
import 'package:provider/provider.dart';
import '../../../widgets/premium_prompt_card.dart';

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
  Future<String>? _mealInsightFuture;

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
          _nameController.text.isEmpty ? 'Unknown Meal' : _nameController.text,
      calories: int.tryParse(_caloriesController.text) ?? 0,
      portion: _portionController.text,
      macros: widget.meal.macros.copyWith(
        protein: int.tryParse(_proteinController.text) ?? 0,
        carbs: int.tryParse(_carbsController.text) ?? 0,
        fat: int.tryParse(_fatController.text) ?? 0,
      ),
    );
    widget.onSave(updatedMeal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();

    if (settings.isPro && _mealInsightFuture == null) {
      _mealInsightFuture = AIService().generateMealInsight(
        meal: widget.meal,
        settings: settings.settings,
        languageCode: settings.languageCode,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceContainerColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.textMutedColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(context).padding.bottom +
                    120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.log_edit_meal,
                        style: AppTypography.heading3.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      IconButton(
                        onPressed:
                            widget.onCancel ?? () => Navigator.pop(context),
                        icon: const Icon(LucideIcons.x),
                        color: context.textSecondaryColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // CALORIES INPUT SECTION
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: context.dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.log_calories_kcal.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: context.textMutedColor,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        IntrinsicWidth(
                          child: TextField(
                            controller: _caloriesController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: AppTypography.displayMedium.copyWith(
                              color: context.primaryColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 48,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              suffixText: ' kcal',
                              suffixStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // MAIN DETAILS
                  _MinimalistInput(
                    controller: _nameController,
                    label: l10n.log_food_name,
                    icon: LucideIcons.utensils,
                    hint: l10n.log_food_hint,
                  ),
                  const SizedBox(height: 16),
                  _MinimalistInput(
                    controller: _portionController,
                    label: l10n.log_portion_desc,
                    icon: LucideIcons.scale,
                    hint: l10n.log_portion_hint,
                  ),

                  const SizedBox(height: 32),

                  // MACRO GRID
                  Text(
                    l10n.result_macronutrients,
                    style: AppTypography.titleSmall.copyWith(
                      color: context.textSecondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MinimalistMacroInput(
                          label: l10n.result_protein,
                          controller: _proteinController,
                          unit: 'g',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MinimalistMacroInput(
                          label: l10n.result_carbs,
                          controller: _carbsController,
                          unit: 'g',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MinimalistMacroInput(
                          label: l10n.result_fat,
                          controller: _fatController,
                          unit: 'g',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  if (settings.isPro && _mealInsightFuture != null) ...[
                    _EditMealInsightCard(insight: _mealInsightFuture!),
                    const SizedBox(height: 24),
                  ] else if (!settings.isPro) ...[
                    PremiumPromptCard(
                      title: l10n.premium_analysis_title,
                      subtitle: l10n.premium_analysis_body,
                      buttonText: l10n.report_prompt_btn,
                      icon: LucideIcons.wand2,
                      onTap:
                          () => PremiumConversionService().openPaywall(
                            context,
                            PaywallEntryPoint.mealInsight,
                            featureName: 'meal_edit',
                          ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ACTIONS
                  ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.log_save_entry,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  if (widget.meal.id != 'temp' && widget.meal.id != 'new') ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _showDeleteConfirmation(context),
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(
                        l10n.log_delete_entry,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: context.surfaceContainerColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              l10n.log_delete_meal_title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(l10n.log_delete_meal_body),
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
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

class _EditMealInsightCard extends StatelessWidget {
  final Future<String> insight;

  const _EditMealInsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return FutureBuilder<String>(
      future: insight,
      builder: (context, snapshot) {
        final body =
            snapshot.connectionState == ConnectionState.done
                ? snapshot.data ?? l10n.result_ai_meal_body
                : l10n.feature_insights_generating;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.sparkles, color: colorScheme.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.result_ai_meal_insight,
                      style: AppTypography.labelLarge.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      body,
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MinimalistInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;

  const _MinimalistInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: context.textMutedColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: AppTypography.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _MinimalistMacroInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String unit;

  const _MinimalistMacroInput({
    required this.label,
    required this.controller,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: context.textMutedColor,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            suffixText: unit,
            suffixStyle: TextStyle(color: context.textMutedColor, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
