import 'dart:async';
import 'dart:io';

// The camera plugin's platform boundary is the hardware test double.
// ignore: depend_on_referenced_packages
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/services/camera_service.dart';
import 'package:snapcal/data/services/connectivity_service.dart';
import 'package:snapcal/providers/meal_provider.dart';
import 'package:snapcal/screens/snap/snap_controller.dart';

class _CameraHardware extends CameraPlatform {
  int created = 0;
  final disposed = <int>[];
  Completer<void>? initializing;
  Completer<void>? disposing;
  bool failInitialization = false;
  XFile? picture;
  final events = StreamController<CameraInitializedEvent>.broadcast();
  final errors = StreamController<CameraErrorEvent>.broadcast();

  @override
  Future<List<CameraDescription>> availableCameras() async => const [
    CameraDescription(
      name: 'rear',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 0,
    ),
  ];

  @override
  Future<int> createCameraWithSettings(
    CameraDescription description,
    MediaSettings settings,
  ) async => ++created;

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      const Stream.empty();

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) =>
      events.stream.where((e) => e.cameraId == cameraId);

  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) => errors.stream;

  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {
    await initializing?.future;
    if (failInitialization) throw PlatformException(code: 'camera-error');
    events.add(
      CameraInitializedEvent(
        cameraId,
        640,
        480,
        ExposureMode.auto,
        true,
        FocusMode.auto,
        true,
      ),
    );
  }

  @override
  Future<void> dispose(int cameraId) async {
    await disposing?.future;
    disposed.add(cameraId);
  }

  @override
  Future<XFile> takePicture(int cameraId) async => picture!;
}

class _Connectivity extends Fake implements ConnectivityService {}

class _Meals extends Fake implements MealLog {}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
  final service = CameraService();
  late _CameraHardware hardware;
  Completer<int>? permission;
  Completer<int>? permissionStatus;

  setUp(() async {
    await service.stop();
    hardware = _CameraHardware();
    CameraPlatform.instance = hardware;
    permission = null;
    permissionStatus = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'checkPermissionStatus') {
            return permissionStatus == null
                ? 1
                : await permissionStatus!.future;
          }
          if (call.method == 'requestPermissions') {
            return <int, int>{
              1: permission == null ? 1 : await permission!.future,
            };
          }
          return null;
        });
  });
  tearDown(() async {
    for (final pending in [hardware.initializing, hardware.disposing]) {
      if (pending != null && !pending.isCompleted) pending.complete();
    }
    for (final pending in [permission, permissionStatus]) {
      if (pending != null && !pending.isCompleted) pending.complete(1);
    }
    await service.stop();
  });

  test(
    'closing while permission is pending cannot open the camera later',
    () async {
      permission = Completer<int>();
      final start = service.warmup();
      await _settle();
      final stop = service.stop();
      permission!.complete(1);
      await Future.wait([start, stop]);
      expect(hardware.created, 0);
      expect(service.isInitialized, isFalse);
      expect(service.isInitializing, isFalse);
    },
  );

  test(
    'closing while prewarm checks permission cancels that prewarm',
    () async {
      permissionStatus = Completer<int>();
      final start = service.prewarm();
      await _settle();
      await service.stop();
      permissionStatus!.complete(1);
      await start;
      expect(hardware.created, 0);
    },
  );

  test(
    'restart waits for pending initialization and hardware disposal',
    () async {
      hardware.initializing = Completer<void>();
      final first = service.warmup();
      await _settle();
      expect(hardware.created, 1);
      final stop = service.stop();
      final second = service.warmup();
      await _settle();
      expect(hardware.created, 1);
      hardware.disposing = Completer<void>();
      hardware.initializing!.complete();
      await _settle();
      expect(hardware.created, 1);
      hardware.disposing!.complete();
      await Future.wait([first, stop, second]);
      expect(hardware.disposed, [1]);
      expect(hardware.created, 2);
      expect(service.isInitialized, isTrue);
    },
  );

  test('failed initialization releases hardware before retry', () async {
    hardware.failInitialization = true;
    await service.warmup();
    expect(hardware.disposed, [1]);
    expect(service.controller, isNull);
    expect(service.error, isNotNull);
    hardware.failInitialization = false;
    await service.warmup();
    expect(service.isInitialized, isTrue);
  });

  test('a failed capture still removes the camera temporary file', () async {
    final path =
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'snapcal_failed_capture_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final file = File(path);
    await file.writeAsBytes([1, 2, 3]);
    addTearDown(() async {
      if (await file.exists()) await file.delete();
    });
    hardware.picture = XFile(path);
    await service.warmup();
    final problems = <ScanProblem>[];

    await SnapController().captureAndAnalyze(
      mealProvider: _Meals(),
      settingsProvider: UserSettings.defaults(),
      isPro: false,
      connectivity: _Connectivity(),
      onShowPaywall: () {},
      onShowResult: () {},
      onProblem: problems.add,
    );

    expect(problems, [ScanProblem.failed]);
    expect(await file.exists(), isFalse);
  });
}
