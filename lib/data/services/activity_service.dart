import 'dart:async';
import 'dart:io';

import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

enum ActivityTrackingStatus {
  disconnected,
  connected,
  permissionDenied,
  unsupported,
  error,
}

abstract class ActivitySource {
  String get sourceName;
  bool get isSupported;
  Stream<StepCount> get stepCountStream;
  Stream<PedestrianStatus> get pedestrianStatusStream;
  Future<ActivityTrackingStatus> requestPermission();
  Future<ActivityTrackingStatus> checkStatus();
}

class PedometerActivitySource implements ActivitySource {
  @override
  String get sourceName => 'Phone step tracking';

  @override
  bool get isSupported => Platform.isAndroid || Platform.isIOS;

  @override
  Stream<StepCount> get stepCountStream => Pedometer.stepCountStream;

  @override
  Stream<PedestrianStatus> get pedestrianStatusStream =>
      Pedometer.pedestrianStatusStream;

  @override
  Future<ActivityTrackingStatus> checkStatus() async {
    if (!isSupported) return ActivityTrackingStatus.unsupported;
    final status = await Permission.activityRecognition.status;
    return status.isGranted
        ? ActivityTrackingStatus.connected
        : ActivityTrackingStatus.disconnected;
  }

  @override
  Future<ActivityTrackingStatus> requestPermission() async {
    if (!isSupported) return ActivityTrackingStatus.unsupported;
    final status = await Permission.activityRecognition.request();
    return status.isGranted
        ? ActivityTrackingStatus.connected
        : ActivityTrackingStatus.permissionDenied;
  }
}

class HealthConnectActivitySource {
  // TODO(activity-sources): Add Health Connect here after Google Play health
  // data review is intentionally pursued. This class is not used by Android
  // production code and must not import Health Connect or health APIs yet.
}

class ActivityService {
  ActivityService({ActivitySource? source})
    : source = source ?? PedometerActivitySource();

  final ActivitySource source;

  String get sourceName => source.sourceName;

  Future<ActivityTrackingStatus> checkStatus() => source.checkStatus();

  Future<ActivityTrackingStatus> requestPermission() {
    return source.requestPermission();
  }

  Stream<StepCount> get stepCountStream => source.stepCountStream;

  Stream<PedestrianStatus> get pedestrianStatusStream {
    return source.pedestrianStatusStream;
  }
}
