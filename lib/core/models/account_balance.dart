// Core model for account balance - no Flutter dependencies

class AccountBalance {
  final String accountUrl;
  final double balance;
  final String tokenType;
  final DateTime lastUpdated;

  const AccountBalance({
    required this.accountUrl,
    required this.balance,
    required this.tokenType,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'accountUrl': accountUrl,
      'balance': balance,
      'tokenType': tokenType,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory AccountBalance.fromMap(Map<String, dynamic> map) {
    return AccountBalance(
      accountUrl: map['accountUrl']?.toString() ?? '',
      balance: (map['balance'] ?? 0.0).toDouble(),
      tokenType: map['tokenType']?.toString() ?? '',
      lastUpdated: DateTime.parse(
          map['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }
}
