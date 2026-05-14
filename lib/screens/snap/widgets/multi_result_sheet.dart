import 'package:flutter/material.dart';

import '../../../data/services/gemini_service.dart';
import 'result_modal.dart';

/// Compatibility wrapper for callers that still use the old multi-result API.
class MultiResultSheet extends StatelessWidget {
  final List<NutritionResult> results;
  final Function(List<NutritionResult> selected) onSaveAll;
  final VoidCallback onCancel;

  const MultiResultSheet({
    super.key,
    required this.results,
    required this.onSaveAll,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return ResultModal(
      results: results,
      onSave: (name, calories, protein, carbs, fat, portion) {
        onSaveAll([
          NutritionResult(
            foodName: name,
            portion: portion ?? '100.0g',
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
          ),
        ]);
      },
      onSaveAll: onSaveAll,
      onCancel: onCancel,
    );
  }
}
