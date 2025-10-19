// Core validation utilities - no Flutter dependencies

class ValidationUtils {
  /// Validate username format
  static bool isValidUsername(String username) {
    if (username.isEmpty) return false;

    // Username should only contain alphanumeric characters and hyphens
    final regex = RegExp(r'^[a-zA-Z0-9-]+$');
    return regex.hasMatch(username) && username.length <= 50;
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;

    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return regex.hasMatch(email);
  }

  /// Validate token amount
  static bool isValidTokenAmount(String amount) {
    if (amount.isEmpty) return false;

    try {
      final value = double.parse(amount);
      return value > 0;
    } catch (e) {
      return false;
    }
  }

  /// Validate transaction hash format
  static bool isValidTransactionHash(String hash) {
    if (hash.isEmpty) return false;

    // Transaction hashes should be 64 character hex strings
    final regex = RegExp(r'^[a-fA-F0-9]{64}$');
    return regex.hasMatch(hash);
  }

  /// Validate public key format
  static bool isValidPublicKey(String publicKey) {
    if (publicKey.isEmpty) return false;

    // Public keys should be 64 character hex strings
    final regex = RegExp(r'^[a-fA-F0-9]{64}$');
    return regex.hasMatch(publicKey);
  }

  /// Validate memo text length
  static bool isValidMemo(String memo) {
    return memo.length <= 256; // Reasonable memo length limit
  }
}
