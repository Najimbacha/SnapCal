import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/services/premium_conversion_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/screens/paywall/paywall_screen.dart';

void main() {
  Widget buildSubject(
    PaywallEntryPoint entryPoint, {
    bool limitReached = false,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: PaywallScreen(entryPoint: entryPoint, limitReached: limitReached),
    );
  }

  testWidgets('scan limit entry point shows limit-specific copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(PaywallEntryPoint.scanLimit, limitReached: true),
    );
    await tester.pump();

    expect(
      find.textContaining('You used 3/3 free scans today'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Upgrade to unlock unlimited scanning'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 9));
  });

  testWidgets('AI coach entry point shows coaching copy', (tester) async {
    await tester.pumpWidget(buildSubject(PaywallEntryPoint.aiCoachLimit));
    await tester.pump();

    expect(find.textContaining('Unlock unlimited AI coaching'), findsOneWidget);
    expect(
      find.textContaining('24/7 personal nutrition guidance'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 9));
  });
}
