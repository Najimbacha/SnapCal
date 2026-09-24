import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

typedef SpeechWordsCallback = void Function(String words, bool isFinal);
typedef SpeechStatusCallback = void Function(String status);
typedef SpeechErrorCallback = void Function(String message, bool permanent);

/// Thin lifecycle-safe wrapper around Android's native speech recognizer.
///
/// Wazn never records or uploads an audio file. The platform recognizer
/// emits text, and only that transcript is later sent to the nutrition API.
class SpeechRecognitionService {
  SpeechRecognitionService({SpeechToText? speech})
    : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  bool _initialized = false;

  bool get isListening => _speech.isListening;

  Future<bool> initialize({
    required SpeechStatusCallback onStatus,
    required SpeechErrorCallback onError,
  }) async {
    if (_initialized) return _speech.isAvailable;

    _initialized = await _speech.initialize(
      onStatus: onStatus,
      onError:
          (SpeechRecognitionError error) =>
              onError(error.errorMsg, error.permanent),
      finalTimeout: const Duration(seconds: 2),
      // Phone microphone only for the first release. This avoids asking for
      // three unrelated Bluetooth permissions just to log a meal.
      options: [SpeechToText.androidNoBluetooth],
    );
    return _initialized;
  }

  Future<String?> bestLocaleFor(String languageCode) async {
    if (!_initialized) return null;
    final wanted = languageCode.toLowerCase();
    final locales = await _speech.locales();
    for (final locale in locales) {
      final normalized = locale.localeId.replaceAll('_', '-').toLowerCase();
      if (normalized == wanted || normalized.startsWith('$wanted-')) {
        return locale.localeId;
      }
    }
    final system = await _speech.systemLocale();
    return system?.localeId;
  }

  Future<void> listen({
    required String? localeId,
    required SpeechWordsCallback onWords,
    required void Function(double level) onSoundLevel,
  }) async {
    await _speech.listen(
      onResult:
          (SpeechRecognitionResult result) =>
              onWords(result.recognizedWords, result.finalResult),
      onSoundLevelChange: onSoundLevel,
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
        onDevice: false,
        listenMode: ListenMode.dictation,
        autoPunctuation: true,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: localeId,
      ),
    );
  }

  Future<void> stop() => _speech.stop();

  Future<void> cancel() => _speech.cancel();
}
