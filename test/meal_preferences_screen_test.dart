import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/planner/meal_preferences_screen.dart';

void main() {
  testWidgets('meal preferences render compact setup without old sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(() => _FakeSettings()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MealPreferencesScreen(onGenerate: () async => true),
        ),
      ),
    );

    // Compact bento layout: one heading, three choice sections, one CTA.
    expect(find.text('Meal Preferences'), findsOneWidget);
    expect(find.text('Quick setup before your plan'), findsOneWidget);
    expect(find.text('PLAN STYLE'), findsOneWidget);
    expect(find.text('MEALS PER DAY'), findsOneWidget);
    expect(find.text('DIETARY RESTRICTION'), findsOneWidget);
    expect(find.text('CUISINE STYLE'), findsOneWidget);
    expect(find.text('Generate My Plan'), findsOneWidget);
  });
}

class _FakeSettings extends Settings {
  @override
  Future<UserSettings> build() async => UserSettings.defaults();
}
