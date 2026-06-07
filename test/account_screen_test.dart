import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/data/services/connectivity_service.dart';
import 'package:snapcal/providers/auth_provider.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/settings/settings_screen.dart';

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool get isAnonymous => false;

  @override
  bool get isAuthenticated => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  bool get isPro => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final goRouterForTest = GoRouter(
  initialLocation: '/account',
  routes: [
    GoRoute(
      path: '/account',
      builder: (context, state) => const AccountScreen(),
    ),
  ],
);

Widget _buildApp({
  required AuthProvider auth,
  required SettingsProvider settings,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      ChangeNotifierProvider(create: (_) => ConnectivityService()),
    ],
    child: MaterialApp.router(
      routerConfig: goRouterForTest,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  group('Account screen layout at narrow widths', () {
    testWidgets('renders without overflow at 320px', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildApp(auth: FakeAuthProvider(), settings: FakeSettingsProvider()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow at 360px', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildApp(auth: FakeAuthProvider(), settings: FakeSettingsProvider()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow at 412px', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildApp(auth: FakeAuthProvider(), settings: FakeSettingsProvider()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Delete Account row', () {
    testWidgets('title renders as "Delete Account?" unbroken', (tester) async {
      await tester.pumpWidget(
        _buildApp(auth: FakeAuthProvider(), settings: FakeSettingsProvider()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Delete Account?'), findsOneWidget);
    });

    testWidgets('subtitle is visible', (tester) async {
      await tester.pumpWidget(
        _buildApp(auth: FakeAuthProvider(), settings: FakeSettingsProvider()),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('This action is permanent. All your data will be lost.'),
        findsOneWidget,
      );
    });

    testWidgets('tapping Delete Account opens confirmation dialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(auth: FakeAuthProvider(), settings: FakeSettingsProvider()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete Account?'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Permanently'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  group('Restore Purchases row', () {
    testWidgets('shows "Restore" as default trailing text', (tester) async {
      await tester.pumpWidget(
        _buildApp(auth: FakeAuthProvider(), settings: FakeSettingsProvider()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Restore'), findsOneWidget);
    });

    testWidgets('does not show "Purchases Restored! 🎉" by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(auth: FakeAuthProvider(), settings: FakeSettingsProvider()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Purchases Restored! 🎉'), findsNothing);
    });
  });

  group('Subscription row', () {
    testWidgets('shows "Manage plan" for free users', (tester) async {
      await tester.pumpWidget(
        _buildApp(auth: FakeAuthProvider(), settings: FakeSettingsProvider()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Subscription'), findsOneWidget);
      expect(find.text('Manage plan'), findsOneWidget);
    });
  });

  group('Sign Out row', () {
    testWidgets('shows subtitle "Leave this device session"', (tester) async {
      await tester.pumpWidget(
        _buildApp(auth: FakeAuthProvider(), settings: FakeSettingsProvider()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('Leave this device session'), findsOneWidget);
    });
  });
}
