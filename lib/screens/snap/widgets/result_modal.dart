import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/services/gemini_service.dart';
import '../../../widgets/glass_container.dart';

/// Modal for displaying and editing AI analysis results (Premium Glass Design)
class ResultModal extends StatefulWidget {
  final Uint8List? imageBytes;
  final NutritionResult? result;
  final Function(String name, int calories, int protein, int carbs, int fat)
  onSave;
  final VoidCallback onCancel;

  const ResultModal({
    super.key,
    this.imageBytes,
    this.result,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<ResultModal> createState() => _ResultModalState();
}

class _ResultModalState extends State<ResultModal> {
  late TextEditingController _nameController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  final FocusNode _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.result?.foodName ?? '',
    );
    _caloriesController = TextEditingController(
      text: widget.result?.calories.toString() ?? '0',
    );
    _proteinController = TextEditingController(
      text: widget.result?.protein.toString() ?? '0',
    );
    _carbsController = TextEditingController(
      text: widget.result?.carbs.toString() ?? '0',
    );
    _fatController = TextEditingController(
      text: widget.result?.fat.toString() ?? '0',
    );

    // Auto-focus if unknown
    if (widget.result?.foodName == 'Unknown Food') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _nameFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _handleSave() {
    widget.onSave(
      _nameController.text,
      int.tryParse(_caloriesController.text) ?? 0,
      int.tryParse(_proteinController.text) ?? 0,
      int.tryParse(_carbsController.text) ?? 0,
      int.tryParse(_fatController.text) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: context.glassBorderColor, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
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
                margin: const EdgeInsets.only(bottom: 16, top: 4),
                decoration: BoxDecoration(
                  color: context.textSecondaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Image preview with Premium Glow
            if (widget.imageBytes != null)
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ambient Glow
                    Container(
                      width: 280,
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 160, // Reduced from 220
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.memory(
                          widget.imageBytes!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 20),

            // Food Name Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Food Name',
                    style: AppTypography.labelSmall.copyWith(
                      color: context.textSecondaryColor,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                _buildTextField(
                  controller: _nameController,
                  icon: LucideIcons.utensils,
                  focusNode: _nameFocusNode,
                  isHeader: true,
                  hint: 'Enter food name...',
                ),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 16),

            // Featured Calorie Card
            _buildCalorieCard()
                .animate()
                .fadeIn(delay: 300.ms)
                .slideY(begin: 0.1, end: 0),

            const SizedBox(height: 16),

            // Macros Grid with Staggered Animation
            Row(
              children: [
                Expanded(
                  child: _buildMacroCard(
                    controller: _proteinController,
                    label: 'Protein',
                    color: AppColors.protein,
                    icon: LucideIcons.binary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMacroCard(
                    controller: _carbsController,
                    label: 'Carbs',
                    color: AppColors.carbs,
                    icon: LucideIcons.wheat,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMacroCard(
                    controller: _fatController,
                    label: 'Fat',
                    color: AppColors.fat,
                    icon: LucideIcons.droplets,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: widget.onCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      foregroundColor: context.textSecondaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTypography.button.copyWith(
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Track Meal',
                        style: AppTypography.button.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? label,
    required IconData icon,
    FocusNode? focusNode,
    bool isHeader = false,
    String? hint,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      borderRadius: 12,
      backgroundColor: context.surfaceLightColor.withOpacity(0.3),
      borderColor: context.glassBorderColor.withOpacity(0.3),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: isHeader ? TextAlign.center : TextAlign.start,
        style:
            isHeader
                ? AppTypography.heading3.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                )
                : AppTypography.bodyMedium.copyWith(
                  color: context.textPrimaryColor,
                ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: context.textMutedColor.withOpacity(0.5),
          ),
          labelStyle: AppTypography.labelSmall.copyWith(
            color: context.textSecondaryColor,
          ),
          prefixIcon:
              isHeader
                  ? null
                  : Icon(icon, color: context.textSecondaryColor, size: 18),
          border: InputBorder.none,
          filled: false,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: isHeader ? 14 : 12),
        ),
      ),
    );
  }

  Widget _buildCalorieCard() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      borderRadius: 20,
      backgroundColor: context.surfaceLightColor.withOpacity(0.6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.flame,
              color: AppColors.error,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Calories',
                  style: AppTypography.labelMedium.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _caloriesController,
                        keyboardType: TextInputType.number,
                        style: AppTypography.displayMedium.copyWith(
                          color: context.textPrimaryColor,
                          fontSize: 32,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Text(
                      'kcal',
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.textMutedColor,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard({
    required TextEditingController controller,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      borderRadius: 20,
      backgroundColor: color.withOpacity(0.05),
      borderColor: color.withOpacity(0.2),
      child: Column(
        children: [
          Icon(icon, color: color.withOpacity(0.8), size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SizedBox(
                width: 32,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: AppTypography.bodyLarge.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Text(
                'g',
                style: AppTypography.labelSmall.copyWith(
                  color: context.textMutedColor,
                  fontSize: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Small proportion indicator
          Container(
            width: 24,
            height: 3,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.6, // Mock proportion
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
