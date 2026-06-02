import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/widgets/scan_choice_sheet.dart';

void main() {
  testWidgets('ScanChoiceSheet renders both choices', (tester) async {
    await _pumpHost(tester);
    await _openSheet(tester);

    expect(find.text('Choose scan type'), findsOneWidget);
    expect(find.text('Scan food'), findsOneWidget);
    expect(find.text('Scan barcode'), findsOneWidget);
  });

  testWidgets('food choice calls food callback once', (tester) async {
    var foodCalls = 0;
    var barcodeCalls = 0;

    await _pumpHost(
      tester,
      onFoodScan: () => foodCalls++,
      onBarcodeScan: () => barcodeCalls++,
    );
    await _openSheet(tester);

    await tester.tap(find.byKey(const ValueKey('scan-choice-food')));
    await tester.tap(
      find.byKey(const ValueKey('scan-choice-food')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(foodCalls, 1);
    expect(barcodeCalls, 0);
  });

  testWidgets('barcode choice calls barcode callback once', (tester) async {
    var foodCalls = 0;
    var barcodeCalls = 0;

    await _pumpHost(
      tester,
      onFoodScan: () => foodCalls++,
      onBarcodeScan: () => barcodeCalls++,
    );
    await _openSheet(tester);

    await tester.tap(find.byKey(const ValueKey('scan-choice-barcode')));
    await tester.tap(
      find.byKey(const ValueKey('scan-choice-barcode')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(foodCalls, 0);
    expect(barcodeCalls, 1);
  });

  testWidgets('close button dismisses sheet', (tester) async {
    var foodCalls = 0;
    var barcodeCalls = 0;

    await _pumpHost(
      tester,
      onFoodScan: () => foodCalls++,
      onBarcodeScan: () => barcodeCalls++,
    );
    await _openSheet(tester);

    await tester.tap(find.byKey(const ValueKey('scan-choice-close')));
    await tester.pumpAndSettle();

    expect(find.text('Choose scan type'), findsNothing);
    expect(foodCalls, 0);
    expect(barcodeCalls, 0);
  });
}

Future<void> _pumpHost(
  WidgetTester tester, {
  VoidCallback? onFoodScan,
  VoidCallback? onBarcodeScan,
}) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder:
            (context) => Scaffold(
              body: Center(
                child: TextButton(
                  key: const ValueKey('open-scan-choice'),
                  onPressed:
                      () => showScanChoiceSheet(
                        context: context,
                        onFoodScan: onFoodScan ?? () {},
                        onBarcodeScan: onBarcodeScan ?? () {},
                      ),
                  child: const Text('Open'),
                ),
              ),
            ),
      ),
    ),
  );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('open-scan-choice')));
  await tester.pumpAndSettle();
}
