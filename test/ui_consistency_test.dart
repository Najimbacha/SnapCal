import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/core/theme/app_button_theme.dart';
import 'package:snapcal/core/theme/app_theme.dart';
import 'package:snapcal/widgets/wazn_icons.dart';

void main() {
  test('light and dark themes use one complete typography system', () {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      final styles = <TextStyle?>[
        theme.textTheme.displayLarge,
        theme.textTheme.displayMedium,
        theme.textTheme.headlineLarge,
        theme.textTheme.headlineMedium,
        theme.textTheme.headlineSmall,
        theme.textTheme.titleLarge,
        theme.textTheme.titleMedium,
        theme.textTheme.titleSmall,
        theme.textTheme.bodyLarge,
        theme.textTheme.bodyMedium,
        theme.textTheme.bodySmall,
        theme.textTheme.labelLarge,
        theme.textTheme.labelMedium,
        theme.textTheme.labelSmall,
      ];

      expect(styles, everyElement(isNotNull));
      expect(styles.map((style) => style!.fontFamily).toSet(), hasLength(1));
      expect(styles.first!.fontFamily, contains('DM Sans'));
    }
  });

  testWidgets('all themed text and icon actions meet the 48dp touch target', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Row(
            children: [
              TextButton(onPressed: () {}, child: const Text('Skip')),
              IconButton(onPressed: () {}, icon: const Icon(WaznIcons.close)),
            ],
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(TextButton)).height, appMinimumTapTarget);
    expect(tester.getSize(find.byType(IconButton)), const Size.square(48));
    expect(tester.getSize(find.byIcon(WaznIcons.close)), const Size.square(20));
  });
}
