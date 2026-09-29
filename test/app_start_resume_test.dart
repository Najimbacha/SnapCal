import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/core/services/app_lifecycle_service.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/services/notification_service.dart';
import 'package:snapcal/providers/cloud_sync_provider.dart';
import 'package:snapcal/router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('first launch', () {
    final fresh = UserSettings.defaults();
    final done = fresh.copyWith(onboardingComplete: true);

    test('goes straight to setup, before any sign-in', () {
      expect(
        appRedirect(location: '/', settings: fresh, hasAccount: false),
        '/onboarding',
      );
    });

    test('someone set up stays where they are', () {
      expect(
        appRedirect(location: '/', settings: done, hasAccount: false),
        isNull,
      );
      expect(
        appRedirect(location: '/onboarding', settings: done, hasAccount: true),
        '/',
      );
    });

    test('"I already have an account" is not sent back to setup', () {
      expect(
        appRedirect(location: '/auth', settings: fresh, hasAccount: false),
        isNull,
      );
      expect(
        appRedirect(location: '/auth', settings: done, hasAccount: true),
        '/',
      );
    });
  });

  group('coming back to the app', () {
    final app = AppLifecycleService();
    var calls = 0;
    void count() => calls++;

    setUp(() {
      app.didChangeAppLifecycleState(AppLifecycleState.resumed);
      calls = 0;
      app.addListener(count);
    });
    tearDown(() => app.removeListener(count));

    test('home button and back is a return', () {
      for (final s in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
      ]) {
        app.didChangeAppLifecycleState(s);
        expect(app.cameBack, isFalse);
      }
      app.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(app.cameBack, isTrue);
    });

    test('the notification shade is not', () {
      app.didChangeAppLifecycleState(AppLifecycleState.inactive);
      app.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(app.isResumed, isTrue);
      expect(app.cameBack, isFalse);
      expect(shouldSyncCloudAfterLifecycle(app), isFalse);
    });

    test('hidden is treated as paused before returning from Recents', () {
      app.didChangeAppLifecycleState(AppLifecycleState.hidden);
      expect(app.isPaused, isTrue);
      expect(app.cameBack, isFalse);

      app.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(app.cameBack, isTrue);
      expect(shouldSyncCloudAfterLifecycle(app), isTrue);
    });

    test('a detached Flutter view refreshes when it is reattached', () {
      app.didChangeAppLifecycleState(AppLifecycleState.detached);
      expect(app.isPaused, isTrue);
      expect(app.cameBack, isFalse);

      app.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(app.cameBack, isTrue);
    });

    test('low memory counts, but does not rerun resume work', () {
      final before = app.memoryPressureCount;
      app.didHaveMemoryPressure();
      expect(app.memoryPressureCount, before + 1);
      expect(calls, 0);
    });
  });

  group('a reminder tap', () {
    tearDown(() {
      NotificationService.onFoodReminderTapped = null;
      NotificationService.takeWaitingFoodReminder();
    });

    test('that starts the app waits for the screens', () {
      NotificationService.onFoodReminderTapped = null;
      NotificationService.openFoodReminder();
      expect(NotificationService.takeWaitingFoodReminder(), isTrue);
      expect(NotificationService.takeWaitingFoodReminder(), isFalse);
    });

    test('with the app open opens the camera at once', () {
      var opened = 0;
      NotificationService.onFoodReminderTapped = () => opened++;
      NotificationService.openFoodReminder();
      expect(opened, 1);
      expect(NotificationService.takeWaitingFoodReminder(), isFalse);
    });
  });
}
