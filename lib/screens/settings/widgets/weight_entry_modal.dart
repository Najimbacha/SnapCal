import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../providers/metrics_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/app_typography.dart';

class WeightEntryModal extends StatefulWidget {
  const WeightEntryModal({super.key});

  @override
  State<WeightEntryModal> createState() => _WeightEntryModalState();
}

class _WeightEntryModalState extends State<WeightEntryModal> {
  late TextEditingController _weightController;
  late TextEditingController _fatController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<MetricsProvider>();
    _weightController = TextEditingController(
      text: provider.currentWeight?.toString() ?? '',
    );
    // Get last logged body fat if available
    final lastMetric = provider.metrics.isEmpty ? null : provider.metrics.first;
    _fatController = TextEditingController(
      text: lastMetric?.bodyFat?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _save() {
    final weight = double.tryParse(_weightController.text);
    if (weight == null) return;

    final bodyFat = double.tryParse(_fatController.text);

    context.read<MetricsProvider>().logWeight(weight, bodyFat: bodyFat);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: context.glassBorderColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Log Weight', style: AppTypography.heading3),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(LucideIcons.x, color: context.textPrimaryColor),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInput(
            context,
            controller: _weightController,
            label: 'Weight (kg)',
            icon: LucideIcons.scale,
            autoFocus: true,
          ),
          const SizedBox(height: 16),
          _buildInput(
            context,
            controller: _fatController,
            label: 'Body Fat % (Optional)',
            icon: LucideIcons.percent,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Save Progress',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool autoFocus = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.surfaceLightColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.glassBorderColor),
      ),
      child: TextField(
        controller: controller,
        autofocus: autoFocus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: context.textPrimaryColor,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: context.textSecondaryColor),
          prefixIcon: Icon(icon, color: context.textSecondaryColor, size: 20),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
