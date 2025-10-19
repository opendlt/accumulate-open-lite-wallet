// String extensions for common operations
extension StringExtensions on String {
  /// Check if string is a valid email
  bool get isValidEmail {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(this);
  }

  /// Check if string is a valid Accumulate URL
  bool get isValidAccumulateUrl {
    return startsWith('acc://') && contains('.acme');
  }

  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  /// Truncate string to specified length
  String truncate(int length) {
    if (this.length <= length) return this;
    return '${substring(0, length)}...';
  }
}
