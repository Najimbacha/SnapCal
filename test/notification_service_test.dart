import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const timeZoneChannel = MethodChannel('snapcal/timezone');
  late NotificationService service;

  setUp(() {
    service = NotificationService();
    service.resetForTesting();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timeZoneChannel, null);
    service.resetForTesting();
  });

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
