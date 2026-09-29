import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'config_service.dart';

typedef BackendProbe = Future<void> Function(String url);

/// Wakes the scan backend without making app startup or navigation wait.
///
/// Concurrent callers share one request, and a successful probe stays fresh
/// briefly so launch, resume, and scan entry do not create duplicate traffic.
class BackendWarmupService {
  BackendWarmupService({
    BackendProbe? probe,
    String Function()? backendUrl,
    DateTime Function()? clock,
    this.freshness = const Duration(minutes: 10),
    this.timeout = const Duration(seconds: 30),
  }) : _probe = probe ?? _defaultProbe,
       _backendUrl = backendUrl ?? (() => ConfigService().backendProxyUrl),
       _clock = clock ?? DateTime.now;

  static final BackendWarmupService instance = BackendWarmupService();

  static final Dio _client = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  final BackendProbe _probe;
  final String Function() _backendUrl;
  final DateTime Function() _clock;
  final Duration freshness;
  final Duration timeout;

  // State is per probed URL: the proxy URL changes once Remote Config loads
  // (launch starts on the built-in default), and a warm host says nothing
  // about a different one.
  final Map<String, Future<void>> _inFlight = {};
  final Map<String, DateTime> _lastSuccess = {};

  Future<void> prewarm() {
    final String url;
    try {
      // Append rather than Uri.resolve('/startup'): like every other caller of
      // the proxy URL, keep any path prefix the base URL carries.
      final base = _backendUrl().replaceAll(RegExp(r'/+$'), '');
      url = '$base/startup';
    } catch (error) {
      debugPrint('⚠️ Backend warmup skipped: $error');
      return Future.value();
    }

    final lastSuccess = _lastSuccess[url];
    if (lastSuccess != null && _clock().difference(lastSuccess) < freshness) {
      return Future.value();
    }

    final running = _inFlight[url];
    if (running != null) return running;

    late final Future<void> tracked;
    tracked = _runProbe(url).whenComplete(() {
      if (identical(_inFlight[url], tracked)) _inFlight.remove(url);
    });
    _inFlight[url] = tracked;
    return tracked;
  }

  Future<void> _runProbe(String url) async {
    final stopwatch = Stopwatch()..start();
    try {
      await _probe(url).timeout(timeout);
      _lastSuccess[url] = _clock();
      debugPrint(
        '⚡ Backend warmup completed in ${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (error) {
      // This is only an optimization. Offline launch and navigation must never
      // fail or wait because the optional wake-up request did not complete.
      debugPrint('⚠️ Backend warmup skipped: $error');
    }
  }

  static Future<void> _defaultProbe(String url) async {
    await _client.get<void>(url);
  }
}
