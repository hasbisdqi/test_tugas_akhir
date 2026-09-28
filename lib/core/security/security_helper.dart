import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class SecurityHelper {
  // 32-char AES key (256-bit) and 16-char IV for local encrypted fields/tokens
  static const String _defaultKeyString = 'AgroSmartCryptoSecKey2026System!'; // 32 chars
  static const String _defaultIvString = 'AgroSmartIV2026!'; // 16 chars

  /// Hashes a password using SHA-256 with optional salt.
  static String hashPassword(String password, {String salt = 'AgroSmartSalt2026'}) {
    final bytes = utf8.encode('$password:$salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies a plain password against an existing SHA-256 hash.
  static bool verifyPassword(String plainPassword, String storedHash, {String salt = 'AgroSmartSalt2026'}) {
    final computedHash = hashPassword(plainPassword, salt: salt);
    return computedHash == storedHash;
  }

  /// Encrypts plain text using AES-CBC (PKCS7).
  static String encryptAES(String plainText, {String? customKey}) {
    final keyStr = (customKey != null && customKey.length == 32) ? customKey : _defaultKeyString;
    final key = enc.Key.fromUtf8(keyStr);
    final iv = enc.IV.fromUtf8(_defaultIvString);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted.base64;
  }

  /// Decrypts AES base64 string.
  static String decryptAES(String encryptedBase64, {String? customKey}) {
    try {
      final keyStr = (customKey != null && customKey.length == 32) ? customKey : _defaultKeyString;
      final key = enc.Key.fromUtf8(keyStr);
      final iv = enc.IV.fromUtf8(_defaultIvString);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      final decrypted = encrypter.decrypt64(encryptedBase64, iv: iv);
      return decrypted;
    } catch (e) {
      return '';
    }
  }
}
