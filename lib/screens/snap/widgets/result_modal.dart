import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/services/gemini_service.dart';
import '../../../widgets/ui_blocks.dart';

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
  late final TextEditingController _nameController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.result?.foodName ?? '',
    );
    _caloriesController = TextEditingController(
      text: '${widget.result?.calories ?? 0}',
    );
    _proteinController = TextEditingController(
      text: '${widget.result?.protein ?? 0}',
    );
    _carbsController = TextEditingController(
      text: '${widget.result?.carbs ?? 0}',
    );
    _fatController = TextEditingController(text: '${widget.result?.fat ?? 0}');
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

  void _save() {
    widget.onSave(
      _nameController.text.trim(),
      int.tryParse(_caloriesController.text) ?? 0,
      int.tryParse(_proteinController.text) ?? 0,
      int.tryParse(_carbsController.text) ?? 0,
      int.tryParse(_fatController.text) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            if (widget.imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.memory(
                  widget.imageBytes!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
                  if (widget.imageBytes != null) const SizedBox(height: 16),
            AppSectionCard(
              color: colorScheme.surfaceContainerLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    style: AppTypography.headlineSmall.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Recognized food...',
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _HeroMetricField(
                    label: 'TOTAL CALORIES',
                    unit: 'kcal',
                    controller: _caloriesController,
                    accent: colorScheme.primary,
                    icon: LucideIcons.flame,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MacroField(
                          label: 'Protein',
                          unit: 'g',
                          controller: _proteinController,
                          color: AppColors.protein,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MacroField(
                          label: 'Carbs',
                          unit: 'g',
                          controller: _carbsController,
                          color: AppColors.carbs,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MacroField(
                          label: 'Fat',
                          unit: 'g',
                          controller: _fatController,
                          color: AppColors.fat,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              24, 
              16, 
              24, 
              100 + MediaQuery.of(context).padding.bottom
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onCancel();
                    },
                    child: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(LucideIcons.check, size: 20),
                    label: const Text('Save to Log'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetricField extends StatelessWidget {
  final String label;
  final String unit;
  final TextEditingController controller;
  final Color accent;
  final IconData icon;

  const _HeroMetricField({
    required this.label,
    required this.unit,
    required this.controller,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        style: AppTypography.displaySmall.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit, 
                      style: AppTypography.titleMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
}

class _MacroField extends StatelessWidget {
  final String label;
  final String unit;
  final TextEditingController controller;
  final Color color;

  const _MacroField({
    required this.label,
    required this.unit,
    required this.controller,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            label, 
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: AppTypography.titleLarge.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: '0',
              suffixText: unit,
              suffixStyle: AppTypography.labelSmall.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
