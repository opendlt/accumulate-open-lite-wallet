// Local storage models for SQLite database

/// Account model for storing wallet accounts locally
class WalletAccount {
  final int? id;
  final String name;
  final String address;
  final String accountType; // 'lite_account', 'adi', 'token_account', 'data_account'
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  WalletAccount({
    this.id,
    required this.name,
    required this.address,
    required this.accountType,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'account_type': accountType,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
      'metadata': metadata != null ? _encodeMetadata(metadata!) : null,
    };
  }

  factory WalletAccount.fromMap(Map<String, dynamic> map) {
    return WalletAccount(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      accountType: map['account_type'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      isActive: map['is_active'] == 1,
      metadata: map['metadata'] != null ? _decodeMetadata(map['metadata']) : null,
    );
  }

  WalletAccount copyWith({
    int? id,
    String? name,
    String? address,
    String? accountType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return WalletAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      accountType: accountType ?? this.accountType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  static String _encodeMetadata(Map<String, dynamic> metadata) {
    // Simple JSON encoding - in production use proper JSON encoder
    return metadata.toString();
  }

  static Map<String, dynamic> _decodeMetadata(String metadata) {
    // Simple JSON decoding - in production use proper JSON decoder
    return {};
  }
}

/// Transaction history model for local storage
class TransactionRecord {
  final int? id;
  final String txHash;
  final String fromAddress;
  final String toAddress;
  final String amount;
  final String tokenType;
  final String transactionType; // 'send', 'receive', 'data_write', 'vote', 'sign'
  final DateTime timestamp;
  final String status; // 'pending', 'confirmed', 'failed'
  final String? memo;
  final Map<String, dynamic>? metadata;

  TransactionRecord({
    this.id,
    required this.txHash,
    required this.fromAddress,
    required this.toAddress,
    required this.amount,
    required this.tokenType,
    required this.transactionType,
    required this.timestamp,
    this.status = 'pending',
    this.memo,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tx_hash': txHash,
      'from_address': fromAddress,
      'to_address': toAddress,
      'amount': amount,
      'token_type': tokenType,
      'transaction_type': transactionType,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status,
      'memo': memo,
      'metadata': metadata?.toString(),
    };
  }

  factory TransactionRecord.fromMap(Map<String, dynamic> map) {
    return TransactionRecord(
      id: map['id'],
      txHash: map['tx_hash'],
      fromAddress: map['from_address'],
      toAddress: map['to_address'],
      amount: map['amount'],
      tokenType: map['token_type'],
      transactionType: map['transaction_type'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      status: map['status'],
      memo: map['memo'],
      metadata: map['metadata'] != null ? {} : null, // Simplified
    );
  }
}

/// User preferences model
class UserPreferences {
  final int? id;
  final String key;
  final String value;
  final String valueType; // 'string', 'int', 'bool', 'double'
  final DateTime updatedAt;

  UserPreferences({
    this.id,
    required this.key,
    required this.value,
    required this.valueType,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'key': key,
      'value': value,
      'value_type': valueType,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      id: map['id'],
      key: map['key'],
      value: map['value'],
      valueType: map['value_type'],
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  // Helper methods for type conversion
  bool get boolValue => value.toLowerCase() == 'true';
  int get intValue => int.tryParse(value) ?? 0;
  double get doubleValue => double.tryParse(value) ?? 0.0;
  String get stringValue => value;
}

/// Address book entry model
class AddressBookEntry {
  final int? id;
  final String name;
  final String address;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;

  AddressBookEntry({
    this.id,
    required this.name,
    required this.address,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory AddressBookEntry.fromMap(Map<String, dynamic> map) {
    return AddressBookEntry(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      isFavorite: map['is_favorite'] == 1,
    );
  }
}

/// Price data for line chart
class PriceData {
  final int? id;
  final DateTime date;
  final double price;
  final String tokenSymbol;

  PriceData({
    this.id,
    required this.date,
    required this.price,
    required this.tokenSymbol,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'price': price,
      'token_symbol': tokenSymbol,
    };
  }

  factory PriceData.fromMap(Map<String, dynamic> map) {
    return PriceData(
      id: map['id'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      price: map['price'].toDouble(),
      tokenSymbol: map['token_symbol'],
    );
  }
}

/// Account balance data for pie chart
class AccountBalance {
  final int? id;
  final String accountAddress;
  final String accountName;
  final double acmeBalance;
  final String accountType;
  final DateTime updatedAt;

  AccountBalance({
    this.id,
    required this.accountAddress,
    required this.accountName,
    required this.acmeBalance,
    required this.accountType,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_address': accountAddress,
      'account_name': accountName,
      'acme_balance': acmeBalance,
      'account_type': accountType,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory AccountBalance.fromMap(Map<String, dynamic> map) {
    return AccountBalance(
      id: map['id'],
      accountAddress: map['account_address'],
      accountName: map['account_name'],
      acmeBalance: map['acme_balance'].toDouble(),
      accountType: map['account_type'],
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }
}