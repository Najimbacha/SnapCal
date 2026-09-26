import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/paywall/paywall_screen.dart';

Package _annual({IntroductoryPrice? intro}) => Package(
  'annual',
  PackageType.annual,
  StoreProduct(
    'annual',
    '',
    'Yearly',
    149.99,
    'SAR 149.99',
    'SAR',
    subscriptionPeriod: 'P1Y',
    introductoryPrice: intro,
  ),
  const PresentedOfferingContext('test', null, null),
);

const _monthly = Package(
  'monthly',
  PackageType.monthly,
  StoreProduct(
    'monthly',
    '',
    'Monthly',
    24.99,
    'SAR 24.99',
    'SAR',
    subscriptionPeriod: 'P1M',
  ),
  PresentedOfferingContext('test', null, null),
);

Future<void> _open(WidgetTester tester, Package annual) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final offering = Offering(
    'test',
    '',
    const {},
    [annual, _monthly],
    annual: annual,
    monthly: _monthly,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        effectiveIsProProvider.overrideWith((ref) => false),
        paywallOfferingsLoaderProvider.overrideWithValue(
          () async => Offerings({'test': offering}, current: offering),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PaywallScreen(),
      ),
    ),
  );
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a free week on Yearly is named, with the day it ends', (
    tester,
  ) async {
    await _open(
      tester,
      _annual(
        intro: const IntroductoryPrice(0, 'Free', 'P1W', 1, PeriodUnit.week, 1),
      ),
    );
    expect(find.text('Start 7-day free trial'), findsOneWidget);
    expect(find.text('7 days free'), findsOneWidget);
    final ends = DateFormat.MMMd(
      'en',
    ).format(DateTime.now().add(const Duration(days: 7)));
    expect(
      find.text(
        'Free until $ends, then SAR 149.99 per year. '
        'Cancel before then and you pay nothing.',
      ),
      findsOneWidget,
    );
    // Twelve months at 24.99 against 149.99 a year.
    expect(find.text('SAVE 50%'), findsOneWidget);

    // Monthly has no trial, so the button names the plan and its price.
    await tester.tap(find.text('Monthly'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Start Monthly — SAR 24.99'), findsOneWidget);
    expect(find.text('Start 7-day free trial'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a first-year discount shows what is paid first', (tester) async {
    await _open(
      tester,
      _annual(
        intro: const IntroductoryPrice(
          85.99,
          'SAR 85.99',
          'P1Y',
          1,
          PeriodUnit.year,
          1,
        ),
      ),
    );
    expect(find.text('SAR 85.99'), findsOneWidget);
    expect(find.text('then SAR 149.99'), findsOneWidget);
    expect(find.text('Start Yearly — SAR 85.99'), findsOneWidget);
    expect(find.textContaining('free trial'), findsNothing);
  });

  testWidgets('Free and Pro can be flipped by hand', (tester) async {
    await _open(tester, _annual());
    // It has moved to Pro by itself.
    expect(find.text('Full week'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('paywall-switch-free')));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('1 day'), findsOneWidget);
    expect(find.text('1 question a day'), findsOneWidget);
    expect(find.text('Full week'), findsNothing);

    await tester.tap(find.text('See everything in Pro'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Everything in Pro'), findsOneWidget);
    expect(find.text('Weekly meal plans'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
