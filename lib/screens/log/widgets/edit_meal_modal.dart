import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/meal.dart';
import '../../../widgets/glass_container.dart';

/// Modal for editing meal details
class EditMealModal extends StatefulWidget {
  final Meal meal;
  final Function(Meal) onSave;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const EditMealModal({
    super.key,
    required this.meal,
    required this.onSave,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  State<EditMealModal> createState() => _EditMealModalState();
}

class _EditMealModalState extends State<EditMealModal> {
  late TextEditingController _nameController;
  late TextEditingController _caloriesController;
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
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final updatedMeal = widget.meal.copyWith(
      foodName:
          _nameController.text.isEmpty ? 'Unknown Food' : _nameController.text,
      calories: int.tryParse(_caloriesController.text) ?? 0,
      macros: Macros(
        protein: int.tryParse(_proteinController.text) ?? 0,
        carbs: int.tryParse(_carbsController.text) ?? 0,
        fat: int.tryParse(_fatController.text) ?? 0,
      ),
    );
    widget.onSave(updatedMeal);
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
          padding: const EdgeInsets.all(24),
          borderRadius: 32,
          backgroundColor: context.surfaceColor.withOpacity(0.9),
          borderColor: context.glassBorderColor.withOpacity(0.5),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: context.textMutedColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  widget.meal.id == 'temp' ? 'Log New Meal' : 'Edit Meal Entry',
                  style: AppTypography.heading2.copyWith(
                    letterSpacing: -0.5,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Food name
                _buildPremiumInput(
                  controller: _nameController,
                  label: 'Food Name',
                  icon: LucideIcons.utensils,
                ),

                const SizedBox(height: 16),

                // Calories
                _buildPremiumInput(
                  controller: _caloriesController,
                  label: 'Calories (kcal)',
                  icon: LucideIcons.flame,
                  keyboardType: TextInputType.number,
                  iconColor: AppColors.primary,
                ),

                const SizedBox(height: 24),

                // Macros Section
                Text(
                  'MACRONUTRIENTS',
                  style: AppTypography.labelSmall.copyWith(
                    color: context.textMutedColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMacroField(
                        controller: _proteinController,
                        label: 'Protein',
                        color: AppColors.protein,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMacroField(
                        controller: _carbsController,
                        label: 'Carbs',
                        color: AppColors.carbs,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMacroField(
                        controller: _fatController,
                        label: 'Fat',
                        color: AppColors.fat,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    if (widget.meal.id != 'temp') ...[
                      IconButton(
                        onPressed: () => _showDeleteConfirmation(context),
                        icon: const Icon(
                          LucideIcons.trash2,
                          color: AppColors.error,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.error.withOpacity(0.1),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: GestureDetector(
                        onTap: _handleSave,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFF6B4DFF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Save Entry',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16 + 16), // Extra bottom padding
              ],
            ),
          ),
        )
        .animate()
        .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 400.ms);
  }

  Widget _buildPremiumInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    Color? iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.glassBorderColor),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTypography.bodySmall.copyWith(
            color: context.textMutedColor,
          ),
          prefixIcon: Icon(
            icon,
            color: iconColor ?? context.textSecondaryColor,
            size: 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMacroField({
    required TextEditingController controller,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: AppTypography.bodyLarge.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          floatingLabelAlignment: FloatingLabelAlignment.center,
          labelStyle: AppTypography.labelSmall.copyWith(
            color: color.withOpacity(0.7),
            fontSize: 9,
          ),
          contentPadding: EdgeInsets.zero,
          suffixText: 'g',
          suffixStyle: AppTypography.bodySmall.copyWith(
            color: color,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: context.surfaceLightColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text('Delete Meal Entry?', style: AppTypography.heading3),
            content: Text(
              'Are you sure you want to remove this meal from your log? This cannot be undone.',
              style: AppTypography.bodyMedium.copyWith(
                color: context.textSecondaryColor,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Keep it',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  widget.onDelete();
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
