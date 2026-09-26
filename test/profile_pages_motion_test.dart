import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:snapcal/data/models/body_metric.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/auth_state_provider.dart';
import 'package:snapcal/providers/cloud_sync_provider.dart';
import 'package:snapcal/providers/metrics_provider.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/settings/about_screen.dart';
import 'package:snapcal/screens/settings/account_screen.dart';
import 'package:snapcal/screens/settings/body_profile_screen.dart';
import 'package:snapcal/screens/settings/data_sync_screen.dart';
import 'package:snapcal/widgets/motion/done_tick.dart';
import 'package:snapcal/widgets/motion/spring_dialog.dart';

class _Settings extends Settings {
  @override
  Future<UserSettings> build() async => UserSettings.defaults().copyWith(
    startingWeight: 84,
    targetWeight: 72,
    weightUnit: 'kg',
  );
}

class _Metrics extends BodyMetrics {
  @override
  Future<List<BodyMetric>> build() async => [
    BodyMetric(date: DateTime(2026, 9, 20), weight: 78),
  ];

  void weighIn(double kg) =>
      state = AsyncData([BodyMetric(date: DateTime(2026, 9, 26), weight: kg)]);
}

class _User implements User {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  bool get isAnonymous => false;

  @override
  String? get displayName => 'Sam';

  @override
  String? get email => 'sam@example.com';

  @override
  String get uid => 'uid-1';
}

/// Syncs in 600ms, then succeeds.
class _Sync extends CloudSyncNotifier {
  @override
  CloudSyncState build() =>
      CloudSyncState(lastSyncedAt: DateTime(2026, 9, 26, 7, 30));

  @override
  Future<bool> syncNow({bool manual = false}) async {
    state = CloudSyncState(
      phase: CloudSyncPhase.syncing,
      lastSyncedAt: state.lastSyncedAt,
    );
    await Future<void>.delayed(const Duration(milliseconds: 600));
    state = CloudSyncState(lastSyncedAt: DateTime(2026, 9, 26, 9, 41));
    return true;
  }
}

Widget _host(
  Widget child, {
  List<Override> overrides = const [],
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith(() => _Settings()),
      authStateProvider.overrideWith((ref) => Stream.value(_User())),
      ...overrides,
    ],
    child: MaterialApp.router(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(
        routes: [GoRoute(path: '/', builder: (_, _) => child)],
      ),
    ),
  );
}

Future<void> _pumpFor(WidgetTester tester, int ms) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

String _percent(WidgetTester tester) =>
    tester
        .widget<Text>(find.byKey(const ValueKey('weight-progress-percent')))
        .data!;

void main() {
  testWidgets('body profile bar fills from the start, then glides on a '
      'weigh-in and celebrates the target', (tester) async {
    final metrics = _Metrics();
    await tester.pumpWidget(
      _host(
        const BodyProfileScreen(),
        overrides: [bodyMetricsProvider.overrideWith(() => metrics)],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Starts near empty and counts up to 50% (84 → 78 of 84 → 72).
    expect(int.parse(_percent(tester).replaceAll('%', '')), lessThan(25));
    await _pumpFor(tester, 1600);
    expect(_percent(tester), '50%');
    expect(find.text('6.0 kg left to reach target'), findsOneWidget);

    // A new weigh-in glides rather than jumps.
    metrics.weighIn(75);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final mid = int.parse(_percent(tester).replaceAll('%', ''));
    expect(mid, inExclusiveRange(50, 75));
    await _pumpFor(tester, 1200);
    expect(_percent(tester), '75%');

    // Reaching the target says so.
    metrics.weighIn(72);
    await tester.pump();
    await _pumpFor(tester, 2500);
    expect(_percent(tester), '100%');
    expect(find.text('Goal reached! 🎉'), findsOneWidget);
    await _pumpFor(tester, 2000);
  });

  testWidgets('cloud sync spins, ticks and says it is synced, then settles', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const DataSyncScreen(),
        overrides: [cloudSyncProvider.overrideWith(_Sync.new)],
      ),
    );
    await _pumpFor(tester, 800);

    await tester.tap(find.text('Cloud sync'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('sync-busy')), findsOneWidget);
    expect(find.text('Syncing…'), findsOneWidget);

    await _pumpFor(tester, 900);
    expect(find.byKey(const ValueKey('sync-done')), findsOneWidget);
    expect(find.text('Everything is synced'), findsOneWidget);
    // No snack bar on success any more; the row says it.
    expect(find.byType(SnackBar), findsNothing);

    await _pumpFor(tester, 2800);
    expect(find.byType(DoneTick), findsNothing);
    expect(find.textContaining('Last synced'), findsOneWidget);
  });

  testWidgets('sign out and delete ask in a dialog that grows from the row', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const AccountScreen(),
        overrides: [
          bodyMetricsProvider.overrideWith(_Metrics.new),
          effectiveIsProProvider.overrideWithValue(false),
        ],
      ),
    );
    await _pumpFor(tester, 800);

    await tester.tap(find.text('Sign Out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    // Still small while it grows.
    final early = tester.getRect(find.byType(AlertDialog));
    await _pumpFor(tester, 600);
    final settled = tester.getRect(find.byType(AlertDialog));
    expect(early.width, lessThan(settled.width));
    expect(find.text('Are you sure you want to sign out?'), findsOneWidget);
    expect(find.byType(DialogBadge), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await _pumpFor(tester, 600);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.text('Delete Account?'));
    await _pumpFor(tester, 1200);
    final badge = tester.widget<DialogBadge>(find.byType(DialogBadge));
    expect(badge.shake, isTrue);
    await tester.tap(find.text('Cancel'));
    await _pumpFor(tester, 600);
  });

  testWidgets('about page speaks the phone language and assembles itself', (
    tester,
  ) async {
    PackageInfo.setMockInitialValues(
      appName: 'Wazn',
      packageName: 'app.wazn',
      version: '1.4.0',
      buildNumber: '42',
      buildSignature: '',
    );
    await tester.pumpWidget(
      _host(const AboutScreen(), locale: const Locale('es')),
    );
    await tester.pump();
    await _pumpFor(tester, 2500);

    expect(find.text('Contador de calorías con IA'), findsOneWidget);
    expect(find.text('SÍGUENOS'), findsOneWidget);
    expect(find.text('AI-Powered Calorie Tracker'), findsNothing);
    expect(find.text('v1.4.0+42'), findsOneWidget);
    expect(find.bySemanticsLabel('Wazn'), findsWidgets);
  });
}
