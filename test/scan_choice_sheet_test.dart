import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/widgets/scan_choice_sheet.dart';

void main() {
  testWidgets('ScanChoiceSheet renders all enabled meal logging choices', (
    tester,
  ) async {
    await _pumpHost(tester, onVoiceLog: () {});
    await _openSheet(tester);

    expect(find.text('Log a meal'), findsOneWidget);
    expect(find.text('Photo scan'), findsOneWidget);
    expect(find.text('Scan barcode'), findsOneWidget);
    expect(find.text('Voice log'), findsOneWidget);
  });

  testWidgets('voice choice stays hidden while the rollout flag is off', (
    tester,
  ) async {
    await _pumpHost(tester);
    await _openSheet(tester);

    expect(find.byKey(const ValueKey('scan-choice-voice')), findsNothing);
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

  testWidgets('voice choice calls voice callback once', (tester) async {
    var foodCalls = 0;
    var barcodeCalls = 0;
    var voiceCalls = 0;

    await _pumpHost(
      tester,
      onFoodScan: () => foodCalls++,
      onBarcodeScan: () => barcodeCalls++,
      onVoiceLog: () => voiceCalls++,
    );
    await _openSheet(tester);

    await tester.tap(find.byKey(const ValueKey('scan-choice-voice')));
    await tester.pumpAndSettle();

    expect(foodCalls, 0);
    expect(barcodeCalls, 0);
    expect(voiceCalls, 1);
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

    expect(find.text('Log a meal'), findsNothing);
    expect(foodCalls, 0);
    expect(barcodeCalls, 0);
  });

  testWidgets(
    'all choices remain reachable on a short Arabic large-text phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpHost(
        tester,
        onVoiceLog: () {},
        locale: const Locale('ar'),
        textScaler: const TextScaler.linear(1.8),
      );
      await _openSheet(tester);

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('scan-choice-voice')),
        120,
        scrollable: find.byType(Scrollable),
      );
      expect(find.byKey(const ValueKey('scan-choice-voice')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpHost(
  WidgetTester tester, {
  VoidCallback? onFoodScan,
  VoidCallback? onBarcodeScan,
  VoidCallback? onVoiceLog,
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child!,
          ),
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
                        onVoiceLog: onVoiceLog,
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
