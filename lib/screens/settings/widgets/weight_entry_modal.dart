import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/metrics_provider.dart';
import '../../../widgets/ui_blocks.dart';

class WeightEntryModal extends StatefulWidget {
  const WeightEntryModal({super.key});

  @override
  State<WeightEntryModal> createState() => _WeightEntryModalState();
}

class _WeightEntryModalState extends State<WeightEntryModal> {
  late final TextEditingController _weightController;
  late final TextEditingController _bodyFatController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<MetricsProvider>();
    final lastMetric = provider.metrics.isEmpty ? null : provider.metrics.first;
    _weightController = TextEditingController(
      text: provider.currentWeight?.toStringAsFixed(1) ?? '',
    );
    _bodyFatController = TextEditingController(
      text: lastMetric?.bodyFat?.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  void _save() {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) return;
    final bodyFat = double.tryParse(_bodyFatController.text);
    context.read<MetricsProvider>().logWeight(weight, bodyFat: bodyFat);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom > 0
            ? 20 + MediaQuery.of(context).viewInsets.bottom
            : 90 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 20),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.scale, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text('Log weight', style: AppTypography.heading3),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Weight',
                    suffixText: 'kg',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyFatController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Body fat (optional)',
                    suffixText: '%',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
            child: const Text('Save progress'),
          ),
        ],
      ),
    );
  }
}
