import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/services/premium_conversion_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/screens/paywall/paywall_screen.dart';

void main() {
  Widget buildSubject(
    PaywallEntryPoint entryPoint, {
    bool limitReached = false,
  }) {
    // PaywallScreen listens on effectiveIsProProvider to close itself when a
    // pending purchase finally verifies, so it needs a scope to read from.
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: PaywallScreen(entryPoint: entryPoint, limitReached: limitReached),
      ),
    );
  }

  testWidgets('scan limit entry point shows limit-specific copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(PaywallEntryPoint.scanLimit, limitReached: true),
    );
    await tester.pump();

    // The allowance is monthly and the server owns the number, so the copy is
    // parameterised. ScanGateService is uninitialised in a widget test and
    // falls back to its safe defaults, so assert the shape rather than a
    // figure -- and assert the old hardcoded "3/3 today" is gone, because
    // that was wrong from the moment the limit stopped being 3 a day.
    expect(find.textContaining('free scans this month'), findsOneWidget);
    expect(find.textContaining('3/3 free scans today'), findsNothing);

    // The headline is now the product name and the entry point's message is
    // the line under it. The second subtitle ("Upgrade to unlock unlimited
    // scanning" beneath "You used 15/15 free scans this month") is gone --
    // it repeated the line above it.
    expect(find.text('SnapCal Pro'), findsOneWidget);
    expect(
      find.textContaining('Upgrade to unlock unlimited scanning'),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 9));
  });

  testWidgets('AI coach entry point shows coaching copy', (tester) async {
    await tester.pumpWidget(buildSubject(PaywallEntryPoint.aiCoachLimit));
    await tester.pump();

    expect(find.textContaining('Unlock unlimited AI coaching'), findsOneWidget);
    expect(find.text('SnapCal Pro'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 9));
  });
}
