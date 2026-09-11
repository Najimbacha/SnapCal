import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/widgets/pro_offer_sheet.dart';

/// The upgrade sheet, in every offer shape the store can produce.
///
/// `SNAPCAL_CAPTURE_PREVIEWS=1 flutter test test/pro_offer_sheet_test.dart`
/// writes PNGs to `build/pro-offer-previews/`. Without the flag it is a smoke
/// test: each variant builds without throwing or overflowing, on a small
/// phone and in Arabic.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final capture = Platform.environment['SNAPCAL_CAPTURE_PREVIEWS'] == '1';

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    if (!capture) return;
    await (FontLoader('Preview')..addFont(
      Future.value(
        ByteData.sublistView(
          File('C:/Windows/Fonts/segoeui.ttf').readAsBytesSync(),
        ),
      ),
    )).load();
    await (FontLoader('packages/lucide_icons/Lucide')..addFont(
      rootBundle.load('packages/lucide_icons/assets/lucide.ttf'),
    )).load();
  });

  // The prices SnapCal charges on Google Play today: SAR 149.99 a year with a
  // first-year offer of SAR 85.99, against SAR 29.99 a month.
  const introOffer = ProOfferSummary(
    price: 'SAR 149.99',
    percentOff: 76,
    introPrice: 'SAR 85.99',
    perMonth: 'SAR 7.17',
    perDay: 'SAR 0.24',
    yearAtMonthlyRate: 'SAR 359.88',
    savings: 'SAR 273.89',
    shareOfMonthly: 85.99 / 359.88,
  );
  final campaign = ProOfferSummary(
    price: 'SAR 149.99',
    percentOff: 76,
    campaignLabel: 'Launch week',
    endsAt: DateTime(2026, 9, 20),
    introPrice: 'SAR 85.99',
    perMonth: 'SAR 7.17',
    perDay: 'SAR 0.24',
    yearAtMonthlyRate: 'SAR 359.88',
    savings: 'SAR 273.89',
    shareOfMonthly: 85.99 / 359.88,
  );

  Future<void> pumpSheet(
    WidgetTester tester, {
    required String name,
    required ProOfferSummary? offer,
    Size size = const Size(390, 844),
    String locale = 'en',
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(fontFamily: capture ? 'Preview' : null),
        builder: (context, child) => RepaintBoundary(key: key, child: child!),
        home: Scaffold(
          backgroundColor: const Color(0xFFF7F7F4),
          body: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.7)),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: ProOfferSheet(
                  offer: offer,
                  scansUsed: 12,
                  scanLimit: 15,
                  onUpgrade: () {},
                  onDismiss: () {},
                  now: DateTime(2026, 9, 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // Step through the entrance animations: they start on timers, so one long
    // pump would fire the timers but never advance the animations they start.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    if (capture) {
      await tester.runAsync(() async {
        final image = await (key.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/pro-offer-previews/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    } else {
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  }

  for (final scenario in <(String, ProOfferSummary?, Size, String)>[
    ('1-offer', introOffer, const Size(390, 844), 'en'),
    ('2-full-sheet', introOffer, const Size(390, 1260), 'en'),
    ('3-campaign', campaign, const Size(390, 844), 'en'),
    ('4-arabic', introOffer, const Size(390, 844), 'ar'),
    ('5-small-phone', introOffer, const Size(320, 640), 'en'),
    ('6-no-price-yet', null, const Size(390, 844), 'en'),
  ]) {
    testWidgets('upgrade sheet ${scenario.$1}', (tester) async {
      await pumpSheet(
        tester,
        name: scenario.$1,
        offer: scenario.$2,
        size: scenario.$3,
        locale: scenario.$4,
      );
    });
  }

  testWidgets('the buttons close the sheet, and only upgrade opens the paywall', (
    tester,
  ) async {
    var upgraded = 0;
    var dismissed = 0;
    Future<void> open() async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: TextButton(
                    onPressed:
                        () => ProOfferSheet.show(
                          context,
                          offer: introOffer,
                          onUpgrade: () => upgraded++,
                          onDismiss: () => dismissed++,
                        ),
                    child: const Text('open'),
                  ),
                ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await open();
    await tester.tap(find.text('Claim 76% off'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect((upgraded, dismissed), (1, 0));
    expect(find.text('Claim 76% off'), findsNothing);

    await open();
    await tester.tap(find.text('Not now'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect((upgraded, dismissed), (1, 1));
    expect(find.text('Not now'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });

  group('what the sheet promises', () {
    late AppLocalizations l10n;
    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('the first-year offer is claimed as its saving', () {
      expect(introOffer.cta(l10n), 'Claim 76% off');
      expect(
        introOffer.ctaDetail(l10n),
        'SAR 85.99 for the first year, then SAR 149.99/year',
      );
    });

    test('a free trial, if one is ever added in the store, is offered as one', () {
      const trial = ProOfferSummary(price: 'SAR 149.99', trialDays: 7);
      expect(trial.cta(l10n), l10n.premium_start_trial);
      expect(trial.ctaDetail(l10n), '7 days free · Then SAR 149.99/year');
    });

    test('with no offer it still invites, without inventing a price', () {
      const plain = ProOfferSummary(price: 'SAR 149.99');
      expect(plain.cta(l10n), 'Get SnapCal Pro');
      expect(plain.ctaDetail(l10n), 'SAR 149.99/year');
    });
  });

  group('amounts are written the way the store writes its prices', () {
    test('symbol, spacing and decimals follow the store', () {
      expect(ProOfferSummary.formatLike('SAR 149.99', 273.89), 'SAR 273.89');
      expect(ProOfferSummary.formatLike('SAR 149.99', 0.2356), 'SAR 0.24');
      expect(ProOfferSummary.formatLike('149,99 €', 7.166), '7,17 €');
      expect(ProOfferSummary.formatLike('\$59.99', 4.99), '\$4.99');
    });

    test('thousands keep their separator', () {
      expect(ProOfferSummary.formatLike('Rs 3,599.00', 12345.6), 'Rs 12,345.60');
      expect(ProOfferSummary.formatLike('1.234,56 €', 9876.5), '9.876,50 €');
      expect(ProOfferSummary.formatLike('¥1,200', 100), '¥100');
    });

    test('Arabic digits stay Arabic', () {
      expect(ProOfferSummary.formatLike('٨٥٫٩٩ ر.س.', 7.17), '٧٫١٧ ر.س.');
    });
  });

  group('reading the store offering', () {
    const context = PresentedOfferingContext('default', null, null);
    final yearUnit = PeriodUnit.values.firstWhere(
      (u) => u.name.toLowerCase().startsWith('year'),
    );
    Package package(
      PackageType type,
      double price, {
      IntroductoryPrice? intro,
    }) => Package(
      type.name,
      type,
      StoreProduct(
        'snapcal_${type.name}',
        '',
        '',
        price,
        'SAR ${price.toStringAsFixed(2)}',
        'SAR',
        introductoryPrice: intro,
      ),
      context,
    );

    test('works out the saving from the real store prices', () {
      final annual = package(
        PackageType.annual,
        149.99,
        intro: IntroductoryPrice(85.99, 'SAR 85.99', 'P1Y', 1, yearUnit, 1),
      );
      final monthly = package(PackageType.monthly, 29.99);
      final offer =
          ProOfferSummary.fromOffering(
            Offering('default', '', const {}, [annual, monthly]),
          )!;

      expect(offer.introPrice, 'SAR 85.99');
      expect(offer.price, 'SAR 149.99');
      expect(offer.percentOff, 76);
      expect(offer.yearAtMonthlyRate, 'SAR 359.88');
      expect(offer.savings, 'SAR 273.89');
      expect(offer.perDay, 'SAR 0.24');
      expect(offer.shareOfMonthly, closeTo(0.239, 0.001));
    });

    test('without a first-year discount, the yearly plan is the saving', () {
      final offer =
          ProOfferSummary.fromOffering(
            Offering('default', '', const {}, [
              package(PackageType.annual, 149.99),
              package(PackageType.monthly, 29.99),
            ]),
          )!;
      expect(offer.introPrice, isNull);
      expect(offer.percentOff, 58);
      expect(offer.savings, 'SAR 209.89');
    });

    test('no offering yet means no price at all', () {
      expect(ProOfferSummary.fromOffering(null), isNull);
    });
  });
}
