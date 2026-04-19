import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// HMAC-based score integrity guard with memory obfuscation.
/// Prevents memory editors and simple tampering.
class ScoreGuard {
  ScoreGuard._();

  // Obfuscation key XOR'd with actual score in memory
  static int _xorKey = 0;
  static int _obfuscatedScore = 0;
  static int _obfuscatedHighScore = 0;

  // HMAC secret derived from build-time value + package identity
  static final String _hmacSecret = _deriveSecret();
  static const String _salt = 'polarity_salt_v1';

  static String _deriveSecret() {
    // Combine multiple app-specific constants to create a key that's
    // harder to extract than a single hardcoded string
    const parts = [
      'com.polarity.game',
      'p0l4r1ty',
      '2024',
      'mAgN3t1c',
    ];
    final key = utf8.encode(parts.join(':'));
    final bytes = utf8.encode('polarity_key_derivation');
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).toString();
  }

  static void initialize() {
    final rng = Random.secure();
    _xorKey = rng.nextInt(0x7FFFFFFF);
    _obfuscatedScore = _xorKey ^ 0;
    _obfuscatedHighScore = _xorKey ^ 0;
  }

  static void setScore(int score) {
    _obfuscatedScore = _xorKey ^ score;
  }

  static int getScore() {
    return _xorKey ^ _obfuscatedScore;
  }

  static void setHighScore(int score) {
    _obfuscatedHighScore = _xorKey ^ score;
  }

  static int getHighScore() {
    return _xorKey ^ _obfuscatedHighScore;
  }

  /// Generate HMAC signature for a score value
  static String generateSignature(int score) {
    final data = '$_salt:$score:${score * 7 + 13}';
    final key = utf8.encode(_hmacSecret);
    final bytes = utf8.encode(data);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  /// Validate that a score + signature pair is legitimate
  static bool validateScore(int score, String signature) {
    return generateSignature(score) == signature;
  }

  /// Encode score for persistent storage: "score:hmac"
  static String encodeForStorage(int score) {
    return '$score:${generateSignature(score)}';
  }

  /// Decode and validate score from storage. Returns null if tampered.
  static int? decodeFromStorage(String stored) {
    try {
      final parts = stored.split(':');
      if (parts.length != 2) return null;
      final score = int.parse(parts[0]);
      final sig = parts[1];
      if (validateScore(score, sig)) return score;
      return null;
    } catch (_) {
      return null;
    }
  }
}
