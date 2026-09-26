import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/onboarding/body_steps.dart';
import 'package:snapcal/screens/onboarding/building_step.dart';
import 'package:snapcal/screens/onboarding/onboarding_draft.dart';
import 'package:snapcal/screens/onboarding/onboarding_kit.dart';
import 'package:snapcal/screens/onboarding/welcome_step.dart';
import 'package:snapcal/screens/paywall/paywall_screen.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => ProviderScope(
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder:
        (context, app) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: app!,
        ),
    home: Scaffold(body: child),
  ),
);

void main() {
  group('first-time setup', () {
    testWidgets('picking an answer pops its tick in', (tester) async {
      Widget option(bool selected) => _host(
        Center(
          child: SizedBox(
            width: 200,
            child: OnbOption(
              selected: selected,
              onTap: () {},
              child: const SizedBox(height: 60),
            ),
          ),
        ),
      );
      double tickScale() => tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.byType(OnbTick),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .entry(0, 0);

      await tester.pumpWidget(option(false));
      await tester.pumpWidget(option(true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      // On its way up from small.
      expect(tickScale(), lessThan(1));
      await tester.pumpAndSettle();
      expect(tickScale(), 1);
    });

    testWidgets('the BMI marker glides to a new weight', (tester) async {
      Widget weight(double kg) => _host(
        SizedBox(
          width: 390,
          height: 844,
          child: WeightStep(
            weightKg: kg,
            heightCm: 170,
            age: 30,
            system: MeasurementSystem.metric,
            onSystemChanged: (_) {},
            onChanged: (_) {},
          ),
        ),
      );
      double markerX() =>
          tester
              .getTopLeft(find.byKey(const ValueKey('onboarding-bmi-marker')))
              .dx;

      await tester.pumpWidget(weight(60));
      await tester.pumpAndSettle();
      final start = markerX();
      await tester.pumpWidget(weight(80));
      await tester.pump(const Duration(milliseconds: 90));
      final midway = markerX();
      await tester.pumpAndSettle();
      final end = markerX();
      expect(end, greaterThan(start));
      expect(midway, greaterThan(start));
      expect(midway, lessThan(end));
    });

    testWidgets('the building ring fills as the lines tick off', (
      tester,
    ) async {
      var done = 0;
      await tester.pumpWidget(_host(BuildingStep(onDone: () => done++)));
      double ring() =>
          tester
              .widget<CircularProgressIndicator>(
                find
                    .descendant(
                      of: find.byKey(
                        const ValueKey('onboarding-building-ring'),
                      ),
                      matching: find.byType(CircularProgressIndicator),
                    )
                    .first,
              )
              .value!;

      await tester.pump(const Duration(milliseconds: 300));
      final early = ring();
      expect(early, greaterThan(0));
      expect(early, lessThan(1 / 3));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(ring(), 1);
      expect(done, 1);
      await tester.pumpAndSettle();
    });

    testWidgets('the welcome scale rolls up to its weight', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 390,
            height: 844,
            child: WelcomeStep(onGetStarted: () {}),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1600));
      // Mid-roll it shows a lower weight, not the one it stops on.
      expect(find.text('72.4 kg', findRichText: true), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('72.4 kg', findRichText: true), findsOneWidget);
    });

    testWidgets('the welcome screen lands at once with reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 390,
            height: 844,
            child: WelcomeStep(onGetStarted: () {}),
          ),
          reduceMotion: true,
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('72.4 kg', findRichText: true), findsOneWidget);
    });
  });

  group('Pro', () {
    const annual = Package(
      'annual',
      PackageType.annual,
      StoreProduct(
        'annual',
        '',
        'Yearly',
        119.99,
        'SAR 119.99',
        'SAR',
        subscriptionPeriod: 'P1Y',
      ),
      PresentedOfferingContext('test', null, null),
    );
    const monthly = Package(
      'monthly',
      PackageType.monthly,
      StoreProduct(
        'monthly',
        '',
        'Monthly',
        19.99,
        'SAR 19.99',
        'SAR',
        subscriptionPeriod: 'P1M',
      ),
      PresentedOfferingContext('test', null, null),
    );
    const offering = Offering(
      'test',
      '',
      {},
      [annual, monthly],
      annual: annual,
      monthly: monthly,
    );

    testWidgets('the outline glides to the plan picked', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectiveIsProProvider.overrideWith((ref) => false),
            paywallOfferingsLoaderProvider.overrideWithValue(
              () async =>
                  const Offerings({'test': offering}, current: offering),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const PaywallScreen(),
          ),
        ),
      );
      await tester.pump();
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final ring = find.byKey(const ValueKey('paywall-plan-ring'));
      expect(ring, findsOneWidget);
      expect(find.text('Start Yearly — SAR 119.99'), findsOneWidget);

      // The plans sit side by side, so the outline glides sideways.
      final before = tester.getTopLeft(ring).dx;
      await tester.tap(find.text('Monthly'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      final midway = tester.getTopLeft(ring).dx;
      await tester.pump(const Duration(seconds: 1));
      final end = tester.getTopLeft(ring).dx;
      expect(end, greaterThan(before));
      expect(midway, greaterThan(before));
      expect(midway, lessThan(end + 12));
      expect(find.text('Start Monthly — SAR 19.99'), findsOneWidget);
      expect(find.text('Start Yearly — SAR 119.99'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
