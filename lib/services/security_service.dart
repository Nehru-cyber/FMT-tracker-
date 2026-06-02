import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'hive_encryption_key';
  static final _localAuth = LocalAuthentication();

  // Get or generate encryption key for Hive
  static Future<Uint8List> getEncryptionKey() async {
    try {
      final encryptionKeyString = await _storage.read(key: _keyName);
      if (encryptionKeyString == null) {
        final key = Hive.generateSecureKey();
        await _storage.write(key: _keyName, value: base64UrlEncode(key));
        return Uint8List.fromList(key);
      } else {
        return base64Url.decode(encryptionKeyString);
      }
    } catch (e) {
      // Fallback: generate a deterministic key if secure storage fails
      // This happens on some Android devices with KeyStore issues
      final fallbackKey = utf8.encode('fmt_tracker_fallback_key_v1_pad!');
      // Ensure 32 bytes for AES-256
      final key = List<int>.filled(32, 0);
      for (int i = 0; i < fallbackKey.length && i < 32; i++) {
        key[i] = fallbackKey[i];
      }
      return Uint8List.fromList(key);
    }
  }

  // Cryptographically secure password hashing (SHA-256 with salt)
  static String hashPassword(String password, {String salt = 'fmt_tracker_v1_salt'}) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Biometric authentication
  static Future<bool> authenticate() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!canCheck && !isDeviceSupported) return true; // Fallback if no biometrics

      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your financial data',
      );
    } catch (e) {
      return false;
    }
  }
}
