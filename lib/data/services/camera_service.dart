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

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  String? get error => _error;

  /// Warm up the camera hardware in the background
  Future<void> warmup() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      // Explicitly check for permission
      final status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        _error = 'Camera permission denied. Please enable it in Settings.';
        _isInitializing = false;
        notifyListeners();
        return;
      }

      _cameras = await availableCameras();
      if (!_isInitializing) return; // Stopped while getting cameras

      if (_cameras == null || _cameras!.isEmpty) {
        _error = 'No cameras available';
        _isInitializing = false;
        notifyListeners();
        return;
      }

      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      if (!_isInitializing) {
        // Stopped while initializing
        await _controller?.dispose();
        _controller = null;
        return;
      }

      _isInitialized = true;
      _isInitializing = false;
      debugPrint('📸 CameraService: Hardware warmed up and ready');
      notifyListeners();
    } catch (e) {
      if (!_isInitializing) return; // Ignore errors if we've already stopped
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
