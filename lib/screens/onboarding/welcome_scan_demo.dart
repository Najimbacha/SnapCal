import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/food_scan_hero_card.dart';

/// Onboarding-specific welcome scan demo.
/// Uses a dedicated generated bowl image so the scan result matches the food.
class WelcomeScanDemo extends StatelessWidget {
  final VoidCallback onScanComplete;

  const WelcomeScanDemo({super.key, required this.onScanComplete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FoodScanHeroCard(
      imagePath: 'assets/images/paywall/onboarding_grilled_chicken_bowl.png',
      mealTitle: l10n.onboarding_scan_meal_title,
      calories: 590,
      proteinGrams: 40,
      carbGrams: 58,
      fatGrams: 22,
      onScanComplete: onScanComplete,
      imageHeight: 184,
    );
  }
}
