import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/screens/snap/widgets/barcode_scanner_view.dart';

class _ScannerPlatform extends MobileScannerPlatform {
  final _barcodes = StreamController<BarcodeCapture?>.broadcast();
  int starts = 0;
  int stops = 0;

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodes.stream;

  @override
  Stream<TorchState> get torchStateStream =>
      Stream.value(TorchState.unavailable);

  @override
  Stream<double> get zoomScaleStateStream => Stream.value(1);

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    starts++;
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.unavailable,
      size: Size(640, 480),
      numberOfCameras: 1,
      initialDeviceOrientation: DeviceOrientation.portraitUp,
    );
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Widget buildCameraView() => const SizedBox.expand();

  void emit(String value) {
    _barcodes.add(BarcodeCapture(barcodes: [Barcode(rawValue: value)]));
  }

  @override
  Future<void> dispose() => _barcodes.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('barcode camera stops in background and restarts from Recents', (
    tester,
  ) async {
    final originalPlatform = MobileScannerPlatform.instance;
    final platform = _ScannerPlatform();
    final detected = <String>[];
    MobileScannerPlatform.instance = platform;
    addTearDown(() async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      MobileScannerPlatform.instance = originalPlatform;
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BarcodeScannerView(
          onBarcodeDetected: detected.add,
          onCancel: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(platform.starts, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(platform.stops, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(platform.starts, 2);
    platform.emit('0123456789012');
    await tester.pump();
    expect(detected, ['0123456789012']);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('barcode camera waits when its screen is built in background', (
    tester,
  ) async {
    final originalPlatform = MobileScannerPlatform.instance;
    final platform = _ScannerPlatform();
    MobileScannerPlatform.instance = platform;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    addTearDown(() {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      MobileScannerPlatform.instance = originalPlatform;
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BarcodeScannerView(onBarcodeDetected: (_) {}, onCancel: () {}),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(platform.starts, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(platform.starts, 1);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
