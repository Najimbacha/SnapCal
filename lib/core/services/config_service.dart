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
        'gemini_api_key': AppConstants.defaultGeminiApiKey,
        'groq_api_key': AppConstants.defaultGroqApiKey,
        'gemini_model_id': AppConstants.defaultGeminiModel,
        'groq_coach_model': AppConstants.defaultGroqCoachModel,
        'groq_model_id': AppConstants.defaultGroqScannerModel, // Matched to console
      });

      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: Duration.zero, // Force fresh pull for debugging
      ));

      await fetchAndActivate();
      
      // REAL TRACE: confirm what is actually inside Remote Config
      _initialized = true; // Set this BEFORE logging so the getters work
      final gKey = geminiApiKey;
      final grKey = groqApiKey;
      debugPrint('🔑 ConfigService: Gemini Key (Prefix): ${gKey.length >= 5 ? gKey.substring(0, 5) : gKey}...');
      debugPrint('🔑 ConfigService: Groq Key (Prefix): ${grKey.length >= 4 ? grKey.substring(0, 4) : grKey}...');
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
    if (!_initialized) return AppConstants.defaultGeminiApiKey.trim();
    return _remoteConfig.getString('gemini_api_key').trim();
  }

  String get groqApiKey {
    if (!_initialized) return AppConstants.defaultGroqApiKey.trim();
    return _remoteConfig.getString('groq_api_key').trim();
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
}
