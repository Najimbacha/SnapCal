import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

/// Service for handling application security, specifically local data encryption.
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  static const String _encryptionKeyName = 'hive_encryption_key';
  static const _secureStorage = FlutterSecureStorage();

  Uint8List? _encryptionKey;
  Future<Uint8List>? _encryptionKeyFuture;

  /// Get or create an encryption key for Hive boxes
  Future<Uint8List> getEncryptionKey() async {
    if (_encryptionKey != null) return _encryptionKey!;

    // Prevent concurrent calls to secure storage which can cause hangs on Android
    _encryptionKeyFuture ??= _getOrCreateKey();
    return _encryptionKeyFuture!;
  }

  Future<Uint8List> _getOrCreateKey() async {
    int attempts = 0;
    const maxAttempts = 2;

    while (attempts < maxAttempts) {
      try {
        final encodedKey = await _secureStorage
            .read(key: _encryptionKeyName)
            .timeout(
              const Duration(seconds: 3),
              onTimeout:
                  () => throw TimeoutException('Secure storage read timed out'),
            );

        if (encodedKey == null) {
          final key = Hive.generateSecureKey();
          await _secureStorage
              .write(key: _encryptionKeyName, value: base64UrlEncode(key))
              .timeout(
                const Duration(seconds: 3),
                onTimeout:
                    () =>
                        throw TimeoutException(
                          'Secure storage write timed out',
                        ),
              );
          _encryptionKey = Uint8List.fromList(key);
        } else {
          _encryptionKey = base64Url.decode(encodedKey);
        }
        return _encryptionKey!;
      } catch (e) {
        attempts++;
        debugPrint(
          '⚠️ SecurityService: Secure storage attempt $attempts failed: $e',
        );
        if (attempts >= maxAttempts) {
          debugPrint('❌ SecurityService: All attempts failed, using fallback.');
          break;
        }
        // Small delay before retry
        await Future.delayed(Duration(milliseconds: 200 * attempts));
      }
    }

    // Fallback to a non-persisted key if secure storage fails
    final fallbackKey = Hive.generateSecureKey();
    _encryptionKey = Uint8List.fromList(fallbackKey);
    return _encryptionKey!;
  }

  /// Securely clear keys (e.g. on factory reset)
  Future<void> clearKeys() async {
    await _secureStorage.delete(key: _encryptionKeyName);
    _encryptionKey = null;
  }
}
