import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/meal.dart';

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
      foodName: _nameController.text.isEmpty
          ? 'Unknown Food'
          : _nameController.text,
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              'Edit Meal',
              style: AppTypography.heading2,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Food name
            TextField(
              controller: _nameController,
              style: AppTypography.bodyLarge,
              decoration: const InputDecoration(
                labelText: 'Food Name',
                prefixIcon: Icon(Icons.restaurant),
              ),
            ),

            const SizedBox(height: 16),

            // Calories
            TextField(
              controller: _caloriesController,
              style: AppTypography.bodyLarge,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Calories',
                prefixIcon: Icon(
                  Icons.local_fire_department,
                  color: AppColors.primary,
                ),
                suffix: Text('kcal', style: AppTypography.bodySmall),
              ),
            ),

            const SizedBox(height: 16),

            // Macros row
            Row(
              children: [
                Expanded(
                  child: _buildMacroField(
                    controller: _proteinController,
                    label: 'Protein',
                    color: AppColors.protein,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMacroField(
                    controller: _carbsController,
                    label: 'Carbs',
                    color: AppColors.carbs,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMacroField(
                    controller: _fatController,
                    label: 'Fat',
                    color: AppColors.fat,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                // Delete button
                IconButton(
                  onPressed: () {
                    _showDeleteConfirmation(context);
                  },
                  icon: Icon(Icons.delete_outline, color: AppColors.error),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.error.withAlpha(30),
                  ),
                ),
                const SizedBox(width: 12),
                // Cancel button
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                // Save button
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.1, duration: 300.ms).fadeIn(duration: 300.ms);
  }

  Widget _buildMacroField({
    required TextEditingController controller,
    required String label,
    required Color color,
  }) {
    return TextField(
      controller: controller,
      style: AppTypography.bodyLarge,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffix: Text('g', style: AppTypography.bodySmall),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 32),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete Meal?', style: AppTypography.heading3),
        content: Text(
          'This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              widget.onDelete();
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
