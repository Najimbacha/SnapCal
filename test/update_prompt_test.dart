import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/services/force_update_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/widgets/update_available_modal.dart';

void main() {
  group('store link', () {
    test('Android goes to SnapCal on Google Play by default', () {
      expect(
        ForceUpdateService.storeUri(isAndroid: true).toString(),
        ForceUpdateService.androidStoreUrl,
      );
    });

    test("a notification's own store link wins", () {
      const link =
          'https://play.google.com/store/apps/details?id=com.snapcal.snapcal&ref=push';
      expect(
        ForceUpdateService.storeUri(
          preferred: link,
          isAndroid: true,
        ).toString(),
        link,
      );
    });

    // Anyone able to send a notification must not be able to send people to
    // an arbitrary site.
    test('a link to anywhere but an app store is ignored', () {
      const elsewhere = 'https://example.com/snapcal.apk';
      expect(
        ForceUpdateService.storeUri(
          preferred: elsewhere,
          isAndroid: true,
        ).toString(),
        ForceUpdateService.androidStoreUrl,
      );
      expect(
        ForceUpdateService.storeUri(preferred: elsewhere, isAndroid: false),
        isNull,
      );
    });

    test('iOS uses the App Store link set in Remote Config', () {
      const appStore = 'https://apps.apple.com/app/id1234567890';
      expect(
        ForceUpdateService.storeUri(
          configured: appStore,
          isAndroid: false,
        ).toString(),
        appStore,
      );
      expect(ForceUpdateService.storeUri(isAndroid: false), isNull);
    });
  });

  group('when to prompt', () {
    test('only when the released version is newer', () {
      expect(ForceUpdateService.isNewer('1.0.25', '1.0.24+42'), isTrue);
      expect(ForceUpdateService.isNewer('1.1.0', '1.0.30+50'), isTrue);
      expect(ForceUpdateService.isNewer('1.0.24', '1.0.24+42'), isFalse);
      expect(ForceUpdateService.isNewer('', '1.0.24+42'), isFalse);
    });

    test('"Later" holds it off for three days, not for good', () {
      final now = DateTime(2026, 9, 11, 12);
      int ago(Duration d) => now.subtract(d).millisecondsSinceEpoch;
      expect(ForceUpdateService.isSnoozed(null, now), isFalse);
      expect(
        ForceUpdateService.isSnoozed(ago(const Duration(days: 1)), now),
        isTrue,
      );
      expect(
        ForceUpdateService.isSnoozed(ago(const Duration(days: 4)), now),
        isFalse,
      );
    });
  });

  // With no wording set in Remote Config the dialog used to be an empty box.
  testWidgets('the prompt has wording even when Firebase sets none', (
    tester,
  ) async {
    var updated = 0;
    var dismissed = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  onPressed:
                      () => UpdateAvailableModal.show(
                        context,
                        onUpdate: () => updated++,
                        onDismiss: () => dismissed++,
                      ),
                  child: const Text('open'),
                ),
              ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Update available'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);

    await tester.tap(find.text('Update now'));
    await tester.pumpAndSettle();
    expect(updated, 1);
    expect(dismissed, 0);
  });
}
