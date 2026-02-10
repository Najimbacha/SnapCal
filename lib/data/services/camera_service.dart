import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

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
      _cameras = await availableCameras();
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
      _isInitialized = true;
      _isInitializing = false;
      debugPrint('📸 CameraService: Hardware warmed up and ready');
      notifyListeners();
    } catch (e) {
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

  @override
  void dispose() {
    _controller?.dispose();
    _isInitialized = false;
    super.dispose();
  }
}
