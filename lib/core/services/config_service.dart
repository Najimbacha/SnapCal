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
        'free_macros_enabled': AppConstants.defaultFreeMacrosEnabled,
        'voice_logging_enabled': AppConstants.defaultVoiceLoggingEnabled,
        'quick_foods_enabled': AppConstants.defaultQuickFoodsEnabled,
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
    final buildOverride = AppConstants.backendProxyUrlOverride.trim();
    if (buildOverride.isNotEmpty) return _withoutTrailingSlash(buildOverride);
    if (!_initialized) return AppConstants.defaultBackendProxyUrl;
    final url = _remoteConfig.getString('backend_proxy_url').trim();
    return _withoutTrailingSlash(
      url.isEmpty ? AppConstants.defaultBackendProxyUrl : url,
    );
  }

  String _withoutTrailingSlash(String url) {
    return url.replaceFirst(RegExp(r'/+$'), '');
  }

  /// Whether free users can see macro grams on scan results and the home
  /// dashboard. Defaults to true; flip in Remote Config to A/B the gate.
  bool get freeMacrosEnabled {
    if (!_initialized) return AppConstants.defaultFreeMacrosEnabled;
    return _remoteConfig.getBool('free_macros_enabled');
  }

  /// Remote kill switch for the voice-meal entry point. Debug builds expose
  /// it automatically so it can be exercised before the production flag is
  /// enabled; release builds stay off until Remote Config says otherwise.
  bool get voiceLoggingEnabled {
    if (kDebugMode) return true;
    if (!_initialized) return AppConstants.defaultVoiceLoggingEnabled;
    return _remoteConfig.getBool('voice_logging_enabled');
  }

  /// Remote kill switch for the regional Quick Add surface.
  bool get quickFoodsEnabled {
    if (kDebugMode) return true;
    if (!_initialized) return AppConstants.defaultQuickFoodsEnabled;
    return _remoteConfig.getBool('quick_foods_enabled');
  }

  String get latestVersion {
    if (!_initialized) return '';
    return _remoteConfig.getString('latest_version').trim();
  }

  String get updateUrl {
    if (!_initialized) return '';
    return _remoteConfig.getString('update_url').trim();
  }

  String get updatePromptTitle {
    if (!_initialized) return '';
    return _remoteConfig.getString('update_prompt_title').trim();
  }

  String get updatePromptMessage {
    if (!_initialized) return '';
    return _remoteConfig.getString('update_prompt_message').trim();
  }
}
