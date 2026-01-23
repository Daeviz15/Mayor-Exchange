import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecurityUtils {
  /// Hashes a string using SHA-256.
  static String hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies if a plain text string matches a hash.
  static bool verifyHash(String plainText, String hash) {
    return hashString(plainText) == hash;
  }
}
