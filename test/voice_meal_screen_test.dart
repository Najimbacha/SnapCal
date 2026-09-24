import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/screens/voice/voice_meal_screen.dart';

void main() {
  testWidgets('voice meal screen explains the flow without a forced tutorial', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: VoiceMealScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Describe what you ate'), findsOneWidget);
    expect(find.byKey(const ValueKey('voice-mic')), findsOneWidget);
    expect(find.byKey(const ValueKey('voice-transcript')), findsOneWidget);
    expect(find.byKey(const ValueKey('voice-analyze')), findsOneWidget);
    expect(find.text('Wazn does not save your audio.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('voice screen remains usable on a short Android viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: VoiceMealScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.byKey(const ValueKey('voice-analyze')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
