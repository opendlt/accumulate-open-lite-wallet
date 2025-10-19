// Core crypto utilities - no Flutter dependencies
import 'dart:typed_data';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

class CryptoUtils {
  /// Convert bytes to hex string
  static String bytesToHex(Uint8List bytes) {
    return hex.encode(bytes);
  }

  /// Convert hex string to bytes
  static Uint8List hexToBytes(String hexString) {
    return Uint8List.fromList(hex.decode(hexString));
  }

  /// Generate SHA-256 hash of input data
  static String sha256Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate SHA-256 hash of bytes
  static Uint8List sha256HashBytes(Uint8List input) {
    final digest = sha256.convert(input);
    return Uint8List.fromList(digest.bytes);
  }

  /// Validate hex string format
  static bool isValidHex(String hexString) {
    try {
      hex.decode(hexString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate if string is a valid Accumulate URL
  static bool isValidAccumulateUrl(String url) {
    return url.startsWith('acc://') && url.contains('.acme');
  }

  /// Extract username from Accumulate URL
  static String? extractUsernameFromUrl(String url) {
    if (!isValidAccumulateUrl(url)) return null;

    final urlWithoutProtocol = url.replaceFirst('acc://', '');
    final parts = urlWithoutProtocol.split('.');
    if (parts.isNotEmpty) {
      return parts.first;
    }
    return null;
  }
}
