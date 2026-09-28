import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/services/gemini_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/snap/widgets/result_modal.dart';

void main() {
  for (final singleCallback in [false, true]) {
    testWidgets(
      'awaits ${singleCallback ? "single" : "batch"} save and retains failed result for retry',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var pending = Completer<void>();
        var calls = 0;
        Future<void> save() {
          calls++;
          return pending.future;
        }

        await tester.pumpWidget(
          ProviderScope(
            overrides: [effectiveIsProProvider.overrideWith((ref) => true)],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder:
                    (context) => Scaffold(
                      body: TextButton(
                        onPressed:
                            () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder:
                                    (_) => ResultModal(
                                      result: NutritionResult(
                                        foodName: 'Rice',
                                        portion: '150g',
                                        calories: 160,
                                        protein: 4,
                                        carbs: 35,
                                        fat: 1,
                                      ),
                                      onSave: (_, _, _, _, _, _) => save(),
                                      onSaveAll:
                                          singleCallback ? null : (_) => save(),
                                      onCancel: () {},
                                    ),
                              ),
                            ),
                        child: const Text('Open'),
                      ),
                    ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('result-save-button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));
        expect(calls, 1);
        expect(find.byType(ResultModal), findsOneWidget);
        expect(find.text('Saving...'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(find.byType(ResultModal), findsOneWidget);

        pending.completeError(StateError('disk full'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(ResultModal), findsOneWidget);
        expect(find.text('Rice'), findsAtLeastNWidgets(1));
        pending = Completer<void>();
        await tester.tap(find.byKey(const ValueKey('result-save-button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(calls, 2);
        pending.complete();
        await tester.pumpAndSettle();
        expect(find.byType(ResultModal), findsNothing);
      },
    );
  }
}
