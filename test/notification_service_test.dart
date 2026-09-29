import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const timeZoneChannel = MethodChannel('snapcal/timezone');
  const notificationsChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  late NotificationService service;

  setUp(() {
    service = NotificationService();
    service.resetForTesting();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timeZoneChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationsChannel, null);
    debugDefaultTargetPlatformOverride = null;
    service.resetForTesting();
  });

  test(
    'notification initialization retries after a platform failure',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      var initializeCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(notificationsChannel, (call) async {
            if (call.method == 'initialize') {
              initializeCalls++;
              if (initializeCalls == 1) {
                throw PlatformException(code: 'temporarily_unavailable');
              }
              return true;
            }
            return null;
          });

      await service.init();
      await service.init();

      expect(initializeCalls, 2);
    },
  );

  test(
    'timezone initialization uses platform timezone when available',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(timeZoneChannel, (call) async {
            expect(call.method, 'getLocalTimeZone');
            return 'Asia/Riyadh';
          });

      await expectLater(
        service.ensureTimeZoneInitializedForTesting(),
        completes,
      );
    },
  );

  test('timezone initialization falls back when plugin is missing', () async {
    await expectLater(service.ensureTimeZoneInitializedForTesting(), completes);
  });

  test('timezone initialization falls back on platform exception', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timeZoneChannel, (call) async {
          throw PlatformException(code: 'timezone_error');
        });

    await expectLater(service.ensureTimeZoneInitializedForTesting(), completes);
  });

  test('timezone initialization is safe for simultaneous callers', () async {
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timeZoneChannel, (call) async {
          calls++;
          return 'Asia/Riyadh';
        });

    await Future.wait([
      service.ensureTimeZoneInitializedForTesting(),
      service.ensureTimeZoneInitializedForTesting(),
    ]);

    expect(calls, 1);
  });
}
