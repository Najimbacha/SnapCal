import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/services/gemini_service.dart';

/// Premium result modal with gradient macros and serving size selector
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

  // Serving size multiplier
  double _servingMultiplier = 1.0;
  int _baseCalories = 0;
  int _baseProtein = 0;
  int _baseCarbs = 0;
  int _baseFat = 0;

  @override
  void initState() {
    super.initState();

    _baseCalories = widget.result?.calories ?? 0;
    _baseProtein = widget.result?.protein ?? 0;
    _baseCarbs = widget.result?.carbs ?? 0;
    _baseFat = widget.result?.fat ?? 0;

    _nameController = TextEditingController(
      text: widget.result?.foodName ?? '',
    );
    _caloriesController = TextEditingController(text: _baseCalories.toString());
    _proteinController = TextEditingController(text: _baseProtein.toString());
    _carbsController = TextEditingController(text: _baseCarbs.toString());
    _fatController = TextEditingController(text: _baseFat.toString());

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

  void _updateServingSize(double multiplier) {
    setState(() {
      _servingMultiplier = multiplier;
      _caloriesController.text =
          (_baseCalories * multiplier).round().toString();
      _proteinController.text = (_baseProtein * multiplier).round().toString();
      _carbsController.text = (_baseCarbs * multiplier).round().toString();
      _fatController.text = (_baseFat * multiplier).round().toString();
    });
    HapticFeedback.selectionClick();
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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                margin: const EdgeInsets.only(bottom: 16, top: 8),
                decoration: BoxDecoration(
                  color: context.textMutedColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Food image with subtle frame
            if (widget.imageBytes != null) _buildImageSection(),

            const SizedBox(height: 16),

            // Food name — inline editable
            _buildFoodNameField()
                .animate()
                .fadeIn(delay: 150.ms)
                .slideY(begin: 0.08, end: 0),

            const SizedBox(height: 16),

            // Serving size selector
            _buildServingSizeSelector()
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.08, end: 0),

            const SizedBox(height: 16),

            // Calorie hero display
            _buildCalorieHero()
                .animate()
                .fadeIn(delay: 250.ms)
                .slideY(begin: 0.08, end: 0),

            const SizedBox(height: 14),

            // Gradient macro cards
            _buildMacroRow()
                .animate()
                .fadeIn(delay: 350.ms)
                .slideY(begin: 0.08, end: 0),

            const SizedBox(height: 24),

            // Action buttons
            _buildActionButtons()
                .animate()
                .fadeIn(delay: 450.ms)
                .slideY(begin: 0.08, end: 0),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Center(
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.memory(widget.imageBytes!, fit: BoxFit.cover),
        ),
      ),
    ).animate().scale(
      duration: 400.ms,
      curve: Curves.easeOutBack,
      begin: const Offset(0.95, 0.95),
      end: const Offset(1.0, 1.0),
    );
  }

  Widget _buildFoodNameField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            textAlign: TextAlign.center,
            style: AppTypography.heading3.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'Enter food name...',
              hintStyle: AppTypography.heading3.copyWith(
                color: context.textMutedColor.withOpacity(0.4),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ),
        Icon(LucideIcons.pencil, color: context.textMutedColor, size: 16),
      ],
    );
  }

  Widget _buildServingSizeSelector() {
    final sizes = [(0.5, '½'), (1.0, '1x'), (1.5, '1.5x'), (2.0, '2x')];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Serving',
          style: AppTypography.labelSmall.copyWith(
            color: context.textSecondaryColor,
          ),
        ),
        const SizedBox(width: 12),
        ...sizes.map((s) {
          final isSelected = _servingMultiplier == s.$1;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => _updateServingSize(s.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : context.surfaceLightColor,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      isSelected
                          ? null
                          : Border.all(color: context.glassBorderColor),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : null,
                ),
                child: Text(
                  s.$2,
                  style: AppTypography.labelMedium.copyWith(
                    color:
                        isSelected ? Colors.white : context.textSecondaryColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCalorieHero() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.error.withOpacity(0.08),
            AppColors.error.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          // Circular calorie icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.error.withOpacity(0.2),
                  AppColors.error.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              LucideIcons.flame,
              color: AppColors.error,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calories',
                  style: AppTypography.labelSmall.copyWith(
                    color: context.textSecondaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: _caloriesController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
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
                      style: AppTypography.bodySmall.copyWith(
                        color: context.textMutedColor,
                        fontWeight: FontWeight.w400,
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

  Widget _buildMacroRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMacroCard(
            controller: _proteinController,
            label: 'Protein',
            color: AppColors.protein,
            icon: LucideIcons.beef,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMacroCard(
            controller: _carbsController,
            label: 'Carbs',
            color: AppColors.carbs,
            icon: LucideIcons.wheat,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMacroCard(
            controller: _fatController,
            label: 'Fat',
            color: AppColors.fat,
            icon: LucideIcons.droplets,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroCard({
    required TextEditingController controller,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Icon in colored circle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SizedBox(
                width: 36,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimaryColor,
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
                style: TextStyle(
                  fontSize: 12,
                  color: context.textMutedColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Cancel button — bordered pill
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
              widget.onCancel();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.textMutedColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.x,
                      color: context.textSecondaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Cancel',
                      style: AppTypography.button.copyWith(
                        color: context.textSecondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Track Meal button — emerald gradient
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _handleSave,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.check, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Track Meal',
                    style: AppTypography.button.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
