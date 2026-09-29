import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import '../../data/services/gemini_service.dart';
import '../../data/services/barcode_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/resilience/app_failure.dart';
import '../../core/resilience/retry_policy.dart';
import '../../core/resilience/safe_async.dart';
import '../../core/resilience/timeout_policy.dart';
import '../../core/utils/image_utils.dart';
import '../../data/models/user_settings.dart';
import '../../data/services/connectivity_service.dart';
import '../../providers/meal_provider.dart';

import '../../data/services/camera_service.dart';

/// Why a scan ended without a result, so the screen can say which.
///
/// Every failure used to open the result screen empty -- "Food item, 0 kcal"
/// with nothing to type calories into -- so a phone with no signal looked
/// like a photo with no food, and the only way out was back.
enum ScanProblem {
  offline,
  slow,
  noFood,
  unreadableImage,
  barcodeNotFound,
  failed,

  /// The photo library itself would not open (permission, or the picker
  /// failed), as opposed to a photo that could not be read.
  galleryUnavailable,

  /// Too many scans in a short time (the server's rate limit, HTTP 429) --
  /// not the monthly free limit, which is the paywall.
  busy,

  /// A Pro user reached today's fair-use limit (HTTP 429). It resets
  /// tomorrow, so the paywall would be wrong and "wait a few minutes" too.
  dailyLimit,
}

/// Why the camera preview is not showing.
enum CameraProblem { slow, permission, unavailable }

enum _Gate { open, offline }

class SnapController {
  VoidCallback? onStateChanged;
  bool _isCapturing = false;
  bool _isAnalyzing = false;
  bool _isScanningBarcode = false;
  bool _lastAttemptWasBarcode = false;
  FlashMode _flashMode = FlashMode.off;

  Uint8List? _capturedImageBytes;
  DateTime? _photoTakenAt;
  bool _isPicking = false;
  List<NutritionResult>? _analysisResults;
  CameraProblem? _cameraProblem;

  final AIService _geminiService = AIService();
  final BarcodeService _barcodeService = BarcodeService();
  int _operationGeneration = 0;
  bool _disposed = false;

  SnapController();

  CameraController? get cameraController => CameraService().controller;
  bool get isInitialized => CameraService().isInitialized;
  bool get isCapturing => _isCapturing;
  bool get isAnalyzing => _isAnalyzing;
  bool get isScanningBarcode => _isScanningBarcode;
  FlashMode get flashMode => _flashMode;
  Uint8List? get capturedImageBytes => _capturedImageBytes;

  /// When an older gallery photo was taken, so the meal lands on the day and
  /// time it was eaten. Null for camera photos and for recent gallery photos.
  DateTime? get photoTakenAt => _photoTakenAt;
  List<NutritionResult>? get analysisResults => _analysisResults;
  NutritionResult? get analysisResult =>
      _analysisResults?.isNotEmpty == true ? _analysisResults!.first : null;
  CameraProblem? get cameraProblem => _cameraProblem;

  /// Whether the last attempt was a barcode, so a problem offers "Scan again"
  /// rather than a photo retry.
  bool get lastAttemptWasBarcode => _lastAttemptWasBarcode;

  /// A photo is kept from a scan that failed on the connection, so "Try
  /// again" can resend it without a retake once the signal is back.
  bool get canRetryLastPhoto =>
      !_lastAttemptWasBarcode &&
      _capturedImageBytes != null &&
      !_isCapturing &&
      !_isAnalyzing;

  set isScanningBarcode(bool value) {
    if (_isScanningBarcode == value) return;
    _isScanningBarcode = value;

    if (_isScanningBarcode) {
      CameraService().stop();
    } else {
      initializeCamera();
    }

    onStateChanged?.call();
  }

  /// The light is simply on or off. It cycled off, auto, always and torch,
  /// so nothing visibly lit until the third tap and the icon showed "on" for
  /// two settings that did nothing until the photo was taken.
  Future<void> toggleFlash() async {
    _flashMode =
        _flashMode == FlashMode.torch ? FlashMode.off : FlashMode.torch;

    try {
      await CameraService().controller?.setFlashMode(_flashMode);
    } catch (e) {
      debugPrint('Flash toggle unavailable: $e');
    }
    onStateChanged?.call();
  }

  Future<void> setFocusPoint(Offset point) async {
    try {
      final ctrl = CameraService().controller;
      if (ctrl == null || !ctrl.value.isInitialized) return;
      await ctrl.setFocusPoint(point);
      await ctrl.setExposurePoint(point);
    } catch (e) {
      debugPrint('Focus/exposure not supported here: $e');
    }
  }

  Future<void> initializeCamera() async {
    _cameraProblem = null;
    // A camera that starts afresh starts with its light off, so the button
    // never shows "on" over a dark lens.
    _flashMode = FlashMode.off;
    final warmup = CameraService().warmup();
    var slow = false;
    await warmup.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        slow = true;
      },
    );
    if (_disposed) return;
    if (slow) {
      _cameraProblem = CameraProblem.slow;
      onStateChanged?.call();
      // The warm-up carries on past the timeout. Without this the "taking
      // longer" panel stayed up after the camera was ready, until something
      // else happened to rebuild the screen.
      unawaited(warmup.then((_) => _settleCameraProblem()));
      return;
    }
    await _settleCameraProblem();
  }

  Future<void> _settleCameraProblem() async {
    if (_disposed) return;
    if (CameraService().error == null) {
      _cameraProblem = null;
    } else {
      final status = await Permission.camera.status;
      if (_disposed) return;
      _cameraProblem =
          status.isGranted
              ? CameraProblem.unavailable
              : CameraProblem.permission;
    }
    onStateChanged?.call();
  }

  void dispose() {
    _disposed = true;
    _operationGeneration++;
    onStateChanged = null;
  }

  bool _isCurrent(int op) => !_disposed && op == _operationGeneration;

  /// Stops waiting on a scan in flight, for "Add manually" on the waiting
  /// screen. The request finishes in the background and its answer is
  /// ignored.
  void cancelScan() {
    _operationGeneration++;
    _isCapturing = false;
    _isAnalyzing = false;
    _capturedImageBytes = null;
    _photoTakenAt = null;
    _analysisResults = null;
    onStateChanged?.call();
  }

  /// What a scan's failure means to the person holding the phone.
  @visibleForTesting
  static ScanProblem problemFor(AppFailure failure) {
    switch (failure.type) {
      case AppFailureType.offline:
        return ScanProblem.offline;
      case AppFailureType.quotaExceeded:
        return failure.isDailyLimit ? ScanProblem.dailyLimit : ScanProblem.busy;
      case AppFailureType.timeout:
        return ScanProblem.slow;
      default:
        return failure.rawError is UnsupportedImageException
            ? ScanProblem.unreadableImage
            : ScanProblem.failed;
    }
  }

  Future<_Gate> _gate(ConnectivityService connectivity, bool isPro) async {
    if (!await connectivity.refreshReachability(force: true)) {
      return _Gate.offline;
    }
    // The backend owns quota enforcement. A stale local count must not block
    // a scan, and a cached photo remains free even at zero remaining scans.
    return _Gate.open;
  }

  void _reportGate(
    _Gate gate,
    VoidCallback onShowPaywall,
    void Function(ScanProblem problem) onProblem,
  ) {
    if (gate == _Gate.offline) {
      HapticFeedback.vibrate();
      onProblem(ScanProblem.offline);
    }
  }

  /// Ends an attempt with [problem], unless it has been overtaken.
  void _endAttempt(
    int op,
    ScanProblem problem,
    void Function(ScanProblem problem) onProblem,
  ) {
    if (!_isCurrent(op)) return;
    _isCapturing = false;
    _isAnalyzing = false;
    if (problem == ScanProblem.unreadableImage ||
        problem == ScanProblem.noFood) {
      // Not worth resending: the answer would be the same.
      _capturedImageBytes = null;
    }
    onStateChanged?.call();
    onProblem(problem);
  }

  /// Compresses a photo for upload. Throws [UnsupportedImageException] when it
  /// cannot be read, or is still too large to send.
  Future<Uint8List> _prepare(Uint8List bytes) async {
    final compressed = await ImageUtils.compressImageBytesAsync(bytes);
    if (compressed == null ||
        compressed.length > AppConstants.maxImageUploadBytes) {
      throw const UnsupportedImageException();
    }
    return compressed;
  }

  Future<void> captureAndAnalyze({
    required MealLog mealProvider,
    required UserSettings settingsProvider,
    required bool isPro,
    required ConnectivityService connectivity,
    required VoidCallback onShowPaywall,
    required VoidCallback onShowResult,
    required void Function(ScanProblem problem) onProblem,
  }) async {
    if (_isCapturing || _isAnalyzing) return;
    final op = ++_operationGeneration;
    _lastAttemptWasBarcode = false;
    _capturedImageBytes = null;
    _photoTakenAt = null;
    _isCapturing = true;
    onStateChanged?.call();

    // The picture is taken the moment the shutter is tapped. The connection
    // check used to come first -- a lookup of up to two seconds -- so the
    // photo was of wherever the phone had moved to by then; and offline no
    // photo was taken at all, leaving "Try again" nothing to resend.
    final camera = CameraService().controller;
    if (camera == null || !camera.value.isInitialized) {
      _isCapturing = false;
      onStateChanged?.call();
      return;
    }

    HapticFeedback.mediumImpact();

    XFile? imageFile;
    try {
      imageFile = await camera.takePicture().timeout(TimeoutPolicy.camera);
      if (!_isCurrent(op)) return;
      final bytes = await imageFile.readAsBytes().timeout(
        TimeoutPolicy.gallery,
      );
      final prepared = await _prepare(bytes);
      if (!_isCurrent(op)) return;
      _capturedImageBytes = prepared;
    } on UnsupportedImageException {
      _endAttempt(op, ScanProblem.unreadableImage, onProblem);
      return;
    } catch (e) {
      debugPrint('Camera capture failed: $e');
      _endAttempt(op, ScanProblem.failed, onProblem);
      return;
    } finally {
      if (imageFile != null) await _deleteQuietly(imageFile);
    }
    if (!_isCurrent(op)) return;

    // Offline, the photo is kept, so "Try again" sends it once the
    // connection is back instead of asking for another.
    final gate = await _gate(connectivity, isPro);
    if (!_isCurrent(op)) return;
    if (gate != _Gate.open) {
      HapticFeedback.vibrate();
      _endAttempt(op, ScanProblem.offline, onProblem);
      return;
    }

    await _analyze(
      op: op,
      label: 'AI food scan',
      mealProvider: mealProvider,
      settings: settingsProvider,
      isPro: isPro,
      onShowPaywall: onShowPaywall,
      onShowResult: onShowResult,
      onProblem: onProblem,
    );
  }

  /// The camera writes every photo to a file; once read, it is not needed.
  /// Nothing removed them, so each scan left a photo behind in the cache.
  static Future<void> _deleteQuietly(XFile file) async {
    try {
      final f = File(file.path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  Future<void> pickFromGallery({
    required MealLog mealProvider,
    required UserSettings settingsProvider,
    required bool isPro,
    required ConnectivityService connectivity,
    required VoidCallback onShowPaywall,
    required VoidCallback onShowResult,
    required void Function(ScanProblem problem) onProblem,
  }) async {
    // A second tap while the first picker is opening would open another.
    if (_isAnalyzing || _isCapturing || _isPicking) return;
    _isPicking = true;
    try {
      await _pickFromGallery(
        mealProvider: mealProvider,
        settingsProvider: settingsProvider,
        isPro: isPro,
        connectivity: connectivity,
        onShowPaywall: onShowPaywall,
        onShowResult: onShowResult,
        onProblem: onProblem,
      );
    } finally {
      _isPicking = false;
    }
  }

  Future<void> _pickFromGallery({
    required MealLog mealProvider,
    required UserSettings settingsProvider,
    required bool isPro,
    required ConnectivityService connectivity,
    required VoidCallback onShowPaywall,
    required VoidCallback onShowResult,
    required void Function(ScanProblem problem) onProblem,
  }) async {
    final op = ++_operationGeneration;
    _lastAttemptWasBarcode = false;
    _capturedImageBytes = null;
    _photoTakenAt = null;

    final XFile? imageFile;
    try {
      imageFile = await pickImage();
    } catch (e) {
      debugPrint('Gallery could not open: $e');
      _endAttempt(op, ScanProblem.galleryUnavailable, onProblem);
      return;
    }
    if (imageFile == null || !_isCurrent(op)) return;

    // The waiting screen from the moment a photo is chosen. Reading and
    // shrinking it used to happen with nothing on screen and the shutter
    // still live, and a tap on it quietly replaced the gallery scan.
    HapticFeedback.selectionClick();
    _isAnalyzing = true;
    onStateChanged?.call();

    try {
      final picked = await imageFile.readAsBytes().timeout(
        TimeoutPolicy.gallery,
      );
      if (!_isCurrent(op)) return;
      // Shown while the photo is prepared; replaced by the upload copy.
      _capturedImageBytes = picked;
      onStateChanged?.call();
      _photoTakenAt = mealTimeFromPhoto(picked, DateTime.now());
      final prepared = await _prepare(picked);
      if (!_isCurrent(op)) return;
      _capturedImageBytes = prepared;
    } on UnsupportedImageException {
      _endAttempt(op, ScanProblem.unreadableImage, onProblem);
      return;
    } catch (e) {
      debugPrint('Gallery photo could not be read: $e');
      _endAttempt(op, ScanProblem.unreadableImage, onProblem);
      return;
    }
    if (!_isCurrent(op)) return;

    // Match camera capture: keep a selected photo when offline so Try again
    // can send it later without making the user reopen the picker.
    final gate = await _gate(connectivity, isPro);
    if (!_isCurrent(op)) return;
    if (gate != _Gate.open) {
      HapticFeedback.vibrate();
      _endAttempt(op, ScanProblem.offline, onProblem);
      return;
    }

    await _analyze(
      op: op,
      label: 'Gallery food scan',
      mealProvider: mealProvider,
      settings: settingsProvider,
      isPro: isPro,
      onShowPaywall: onShowPaywall,
      onShowResult: onShowResult,
      onProblem: onProblem,
    );
  }

  /// Opens the photo library. Replaceable in tests.
  @visibleForTesting
  Future<XFile?> pickImage() => ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 90,
  );

  /// The time an older photo was taken, read from its EXIF data, when it
  /// should decide the meal's day and time: at least [recentWindow] old (a
  /// photo from minutes ago is simply "now"), not in the future, and no more
  /// than [maxAge] back. Null otherwise, or when the photo carries no date.
  @visibleForTesting
  static DateTime? mealTimeFromPhoto(
    Uint8List bytes,
    DateTime now, {
    Duration recentWindow = const Duration(hours: 2),
    Duration maxAge = const Duration(days: 7),
  }) {
    final DateTime? taken;
    try {
      taken = readPhotoDate(bytes);
    } catch (_) {
      return null;
    }
    if (taken == null) return null;
    final age = now.difference(taken);
    if (age < recentWindow || age > maxAge) return null;
    return taken;
  }

  /// When a JPEG says it was taken ("2026:09:27 20:14:03", local time).
  @visibleForTesting
  static DateTime? readPhotoDate(Uint8List bytes) {
    final exif = img.decodeJpgExif(bytes);
    if (exif == null) return null;
    final raw =
        exif.exifIfd['DateTimeOriginal']?.toString() ??
        exif.exifIfd['DateTimeDigitized']?.toString() ??
        exif.imageIfd['DateTime']?.toString();
    if (raw == null) return null;
    final m = RegExp(
      r'^(\d{4}):(\d{2}):(\d{2})[ T](\d{2}):(\d{2}):(\d{2})',
    ).firstMatch(raw.trim());
    if (m == null) return null;
    final parts = [for (var i = 1; i <= 6; i++) int.parse(m.group(i)!)];
    if (parts[0] < 2000 || parts[1] < 1 || parts[1] > 12 || parts[2] < 1) {
      return null;
    }
    return DateTime(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]);
  }

  /// Sends the photo from a scan that failed on the connection again.
  Future<void> retryLastScan({
    required MealLog mealProvider,
    required UserSettings settingsProvider,
    required bool isPro,
    required ConnectivityService connectivity,
    required VoidCallback onShowPaywall,
    required VoidCallback onShowResult,
    required void Function(ScanProblem problem) onProblem,
  }) async {
    if (!canRetryLastPhoto) return;
    final op = ++_operationGeneration;
    // The waiting screen, while the connection is checked.
    _isAnalyzing = true;
    onStateChanged?.call();

    final gate = await _gate(connectivity, isPro);
    if (!_isCurrent(op)) return;
    if (gate != _Gate.open) {
      _isAnalyzing = false;
      onStateChanged?.call();
      _reportGate(gate, onShowPaywall, onProblem);
      return;
    }

    await _analyze(
      op: op,
      label: 'Retried food scan',
      mealProvider: mealProvider,
      settings: settingsProvider,
      isPro: isPro,
      onShowPaywall: onShowPaywall,
      onShowResult: onShowResult,
      onProblem: onProblem,
    );
  }

  Future<void> _analyze({
    required int op,
    required String label,
    required MealLog mealProvider,
    required UserSettings settings,
    required bool isPro,
    required VoidCallback onShowPaywall,
    required VoidCallback onShowResult,
    required void Function(ScanProblem problem) onProblem,
  }) async {
    final bytes = _capturedImageBytes;
    if (bytes == null) return;
    _isCapturing = false;
    _isAnalyzing = true;
    onStateChanged?.call();

    final result = await SafeAsync.run<List<NutritionResult>>(
      label: label,
      operation:
          () => _geminiService.analyzeFood(
            bytes,
            language: settings.languageCode ?? 'en',
            prepared: true,
          ),
      timeout: TimeoutPolicy.aiScan,
      retryPolicy: RetryPolicy.scan,
      // One key per attempt: a scan abandoned for manual entry may still be
      // in flight, and a shared key would turn the next scan away as
      // "already running".
      operationKey: 'snap:scan:$op',
      isActive: () => _isCurrent(op),
    );
    if (!_isCurrent(op)) return;

    if (result.isFailure) {
      final failure = result.failure!;
      if (failure.type == AppFailureType.cancelled) {
        _isAnalyzing = false;
        onStateChanged?.call();
        return;
      }
      // Free-tier monthly limit hit (HTTP 402): this is the moment of
      // highest intent — show the paywall, not an error. Only 402: a 429 is
      // the server's short-term rate limit, which Pro users meet as well,
      // and it used to put the paywall in front of people already paying.
      if (failure.type == AppFailureType.quotaExceeded &&
          failure.statusCode == 402) {
        _isAnalyzing = false;
        _capturedImageBytes = null;
        onStateChanged?.call();
        onShowPaywall();
        return;
      }
      _endAttempt(op, problemFor(failure), onProblem);
      return;
    }

    final items = result.requireData;
    if (items.isEmpty) {
      _endAttempt(op, ScanProblem.noFood, onProblem);
      return;
    }

    _analysisResults = items;
    if (!_isCurrent(op)) return;
    _isAnalyzing = false;
    onStateChanged?.call();
    onShowResult();
  }

  Future<void> handleBarcodeDetected(
    String code, {
    required ConnectivityService connectivity,
    required VoidCallback onShowResult,
    required void Function(ScanProblem problem) onProblem,
  }) async {
    if (_isAnalyzing) return;
    final op = ++_operationGeneration;
    _lastAttemptWasBarcode = true;
    _capturedImageBytes = null;

    final hasInternet = await connectivity.refreshReachability(force: true);
    if (!_isCurrent(op)) return;
    if (!hasInternet) {
      isScanningBarcode = false;
      HapticFeedback.vibrate();
      onProblem(ScanProblem.offline);
      return;
    }

    // Barcode scanning is free and unrestricted for all users
    isScanningBarcode = false;
    _isAnalyzing = true;
    onStateChanged?.call();

    final lookup = await SafeAsync.run<NutritionResult?>(
      label: 'Barcode lookup',
      operation: () => _barcodeService.fetchProductByBarcode(code),
      timeout: TimeoutPolicy.barcode,
      retryPolicy: RetryPolicy.network,
      operationKey: 'snap:barcode:$code',
      isActive: () => _isCurrent(op),
    );
    if (!_isCurrent(op)) return;

    if (lookup.isFailure) {
      final failure = lookup.failure!;
      if (failure.type == AppFailureType.cancelled) {
        _isAnalyzing = false;
        onStateChanged?.call();
        return;
      }
      final problem =
          failure.type == AppFailureType.notFound
              ? ScanProblem.barcodeNotFound
              : problemFor(failure);
      _endAttempt(
        op,
        problem == ScanProblem.unreadableImage ? ScanProblem.failed : problem,
        onProblem,
      );
      return;
    }

    final result = lookup.data;
    if (result == null) {
      _endAttempt(op, ScanProblem.barcodeNotFound, onProblem);
      return;
    }
    _analysisResults = [result];
    // Barcode scans are free and do not increment the monthly scan limit
    _isAnalyzing = false;
    onStateChanged?.call();
    onShowResult();
  }

  void reset() {
    cancelScan();
  }
}
