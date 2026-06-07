import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/core/theme/app_colors.dart';
import 'package:snapcal/screens/home/home_screen.dart';

void main() {
  testWidgets('home premium feature cards do not overflow at narrow width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.homePremiumBackground,
          body: Center(
            child: SizedBox(
              width: 320,
              child: Row(
                children: [
                  Expanded(
                    child: PremiumFeatureCard(
                      icon: Icons.calendar_month_rounded,
                      iconColor: AppColors.homePlannerAccent,
                      title: 'Meal Planner',
                      subtitle: 'Build meals around your target',
                      isPro: false,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PremiumFeatureCard(
                      icon: Icons.auto_awesome_rounded,
                      iconColor: AppColors.homeCoachAccent,
                      title: 'AI Coach',
                      subtitle: 'Personal guidance for today',
                      isPro: false,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
