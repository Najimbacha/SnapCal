import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Singleton service for managing camera hardware
class CameraService extends ChangeNotifier {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _error;

  /// The start-up in flight, which every caller shares and awaits.
  Future<void>? _warming;

  /// Bumped by [stop], so a start-up that was overtaken lets go of the
  /// hardware instead of carrying on as if it were still wanted.
  int _generation = 0;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  String? get error => _error;

  /// Starts the camera, or joins a start already under way. Callers used to
  /// get back at once when one was running, and the camera screen would sit
  /// on its placeholder after the camera had come up.
  Future<void> warmup() {
    if (_isInitialized) return Future.value();
    final running = _warming;
    if (running != null) return running;
    final start = _warm(_generation);
    _warming = start;
    start.whenComplete(() {
      if (identical(_warming, start)) _warming = null;
    });
    return start;
  }

  /// Starts the camera ahead of the camera screen -- while the "Log a meal"
  /// sheet is open -- so the picture is already live when the screen shows.
  /// Only once permission is granted: this never raises the permission
  /// prompt over the sheet; the camera screen asks for it as before.
  Future<void> prewarm() async {
    try {
      if (!(await Permission.camera.status).isGranted) return;
      await warmup();
    } catch (e) {
      debugPrint('📸 CameraService: prewarm skipped: $e');
    }
  }

  Future<void> _warm(int generation) async {
    bool overtaken() => generation != _generation;

    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      // Explicitly check for permission
      final status = await Permission.camera.request();
      if (overtaken()) return;
      if (status.isDenied || status.isPermanentlyDenied) {
        _error = 'Camera permission denied. Please enable it in Settings.';
        _isInitializing = false;
        notifyListeners();
        return;
      }

      _cameras ??= await availableCameras();
      if (overtaken()) return;

      if (_cameras == null || _cameras!.isEmpty) {
        _error = 'No cameras available';
        _isInitializing = false;
        notifyListeners();
        return;
      }

      final newController = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = newController;

      await newController.initialize();
      if (overtaken()) {
        await newController.dispose();
        if (_controller == newController) _controller = null;
        return;
      }

      _isInitialized = true;
      _isInitializing = false;
      debugPrint('📸 CameraService: Hardware warmed up and ready');
      notifyListeners();
    } catch (e) {
      if (overtaken()) return; // Ignore errors if we've already stopped
      _error = 'Camera warmup failed: $e';
      _isInitializing = false;
      _isInitialized = false;
      debugPrint('❌ CameraService: $_error');
      notifyListeners();
    }
  }

  /// Ensure the camera is ready (awaits if initializing)
  Future<void> ensureReady() async {
    if (_isInitialized) return;
    await warmup();
  }

  Future<void> stop() async {
    if (_controller == null && !_isInitialized) return;

    debugPrint('📸 CameraService: Stopping camera and releasing hardware');

    _generation++;
    _warming = null;
    final controllerToDispose = _controller;
    _controller = null;
    _isInitialized = false;
    _isInitializing = false;

    // Notify listeners immediately so the UI stops using the controller
    // before we start the potentially slow disposal process.
    notifyListeners();

    if (controllerToDispose != null) {
      try {
        // Stop any active image streams first to prevent frames being sent to a detaching engine
        if (controllerToDispose.value.isStreamingImages) {
          await controllerToDispose.stopImageStream();
        }
        await controllerToDispose.dispose();
      } catch (e) {
        debugPrint('📸 CameraService: Error during disposal: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _isInitialized = false;
    super.dispose();
  }
}
