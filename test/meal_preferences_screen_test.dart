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

    expect(find.text('Create your meal plan'), findsOneWidget);
    expect(find.text('Based on your goal'), findsOneWidget);
    expect(find.text('Meals per day'), findsOneWidget);
    expect(find.text('Diet style'), findsOneWidget);
    expect(find.text('Requirements'), findsOneWidget);
    expect(find.text('More preferences'), findsOneWidget);
    expect(find.text('Create my plan'), findsOneWidget);
  });
}

class _FakeSettings extends Settings {
  @override
  Future<UserSettings> build() async => UserSettings.defaults();
}
