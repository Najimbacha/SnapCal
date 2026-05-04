import 'dart:convert';
import 'dart:typed_data';
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

  /// Get or create an encryption key for Hive boxes
  Future<Uint8List> getEncryptionKey() async {
    if (_encryptionKey != null) return _encryptionKey!;

    final encodedKey = await _secureStorage.read(key: _encryptionKeyName);
    if (encodedKey == null) {
      // Create new key
      final key = Hive.generateSecureKey();
      await _secureStorage.write(
        key: _encryptionKeyName,
        value: base64UrlEncode(key),
      );
      _encryptionKey = Uint8List.fromList(key);
    } else {
      _encryptionKey = base64Url.decode(encodedKey);
    }

    return _encryptionKey!;
  }

  /// Securely clear keys (e.g. on factory reset)
  Future<void> clearKeys() async {
    await _secureStorage.delete(key: _encryptionKeyName);
    _encryptionKey = null;
  }
}
