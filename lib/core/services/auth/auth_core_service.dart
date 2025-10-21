import 'package:flutter/foundation.dart';
// Core authentication business logic - no Flutter dependencies

class AuthCoreService {
  /// Generate email from username using consistent domain
  static String generateEmailFromUsername(String username) {
    return "$username@accu2.io";
  }

  /// Validate username and password for account creation
  static ValidationResult validateCredentials(
      String username, String password) {
    final errors = <String>[];

    // Username validation
    if (username.isEmpty) {
      errors.add('Username cannot be empty');
    } else if (username.length < 3) {
      errors.add('Username must be at least 3 characters');
    } else if (username.length > 50) {
      errors.add('Username must be 50 characters or less');
    } else if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(username)) {
      errors.add('Username can only contain letters, numbers, and hyphens');
    }

    // Password validation
    if (password.isEmpty) {
      errors.add('Password cannot be empty');
    } else if (password.length < 6) {
      errors.add('Password must be at least 6 characters');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Create user data map for storage
  static Map<String, dynamic> createUserDataMap(String username, String email) {
    return {
      'username': username,
      'email': email,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult({
    required this.isValid,
    required this.errors,
  });
}
