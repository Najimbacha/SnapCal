import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  late FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      await _remoteConfig.setDefaults({
        'gemini_model_id': AppConstants.defaultGeminiModel,
        'groq_coach_model': AppConstants.defaultGroqCoachModel,
        'groq_model_id':
            AppConstants.defaultGroqScannerModel, // Matched to console
        'revenuecat_apple_api_key': AppConstants.defaultRevenueCatAppleApiKey,
        'revenuecat_google_api_key': AppConstants.defaultRevenueCatGoogleApiKey,
        'backend_proxy_url': AppConstants.defaultBackendProxyUrl,
      });

      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: Duration.zero, // Force fresh pull for debugging
        ),
      );

      await fetchAndActivate();

      _initialized = true; // Set this BEFORE logging so the getters work
    } catch (e) {
      debugPrint('❌ ConfigService: Initialization failed: $e');
    }
  }

  Future<void> fetchAndActivate() async {
    try {
      final updated = await _remoteConfig.fetchAndActivate();
      if (updated) {
        debugPrint('🚀 ConfigService: Remote Config updated');
      }
    } catch (e) {
      debugPrint('❌ ConfigService: Fetch failed: $e');
    }
  }

  String get geminiApiKey {
    return '';
  }

  String get groqApiKey {
    return '';
  }

  String get geminiModelId {
    if (!_initialized) return AppConstants.defaultGeminiModel;
    return _remoteConfig.getString('gemini_model_id').trim();
  }

  String get groqCoachModel {
    if (!_initialized) return AppConstants.defaultGroqCoachModel;
    return _remoteConfig.getString('groq_coach_model').trim();
  }

  String get groqScannerModel {
    if (!_initialized) return AppConstants.defaultGroqScannerModel;
    return _remoteConfig.getString('groq_model_id').trim();
  }

  String get revenueCatAppleApiKey {
    if (!_initialized) return AppConstants.defaultRevenueCatAppleApiKey.trim();
    return _remoteConfig.getString('revenuecat_apple_api_key').trim();
  }

  String get revenueCatGoogleApiKey {
    if (!_initialized) return AppConstants.defaultRevenueCatGoogleApiKey.trim();
    return _remoteConfig.getString('revenuecat_google_api_key').trim();
  }

  String get backendProxyUrl {
    if (!_initialized) return AppConstants.defaultBackendProxyUrl;
    final url = _remoteConfig.getString('backend_proxy_url').trim();
    return url.isEmpty ? AppConstants.defaultBackendProxyUrl : url;
  }
}
