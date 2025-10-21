// Local storage models for SQLite database
import 'dart:convert';

/// Utility functions for metadata encoding/decoding
String _encodeMetadata(Map<String, dynamic> metadata) {
  return json.encode(metadata);
}

Map<String, dynamic> _decodeMetadata(String metadata) {
  try {
    return json.decode(metadata) as Map<String, dynamic>;
  } catch (e) {
    return {};
  }
}

/// Account model for storing wallet accounts locally
class WalletAccount {
  final int? id;
  final String address; // Use address/URL as the primary identifier
  final String accountType; // 'lite_account', 'adi', 'token_account', 'data_account'
  final bool isActive;
  final int? parentIdentityId;
  final String? tokenUrl;
  final int? keyBookId;
  final int? keyPageId;
  final Map<String, dynamic>? metadata;

  WalletAccount({
    this.id,
    required this.address,
    required this.accountType,
    this.isActive = true,
    this.parentIdentityId,
    this.tokenUrl,
    this.keyBookId,
    this.keyPageId,
    this.metadata,
  });

  /// Getter for display name - returns the address/URL
  String get name => address;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': address, // Use address as name for database compatibility
      'address': address,
      'account_type': accountType,
      'is_active': isActive ? 1 : 0,
      'parent_identity_id': parentIdentityId,
      'token_url': tokenUrl,
      'key_book_id': keyBookId,
      'key_page_id': keyPageId,
      'metadata': metadata != null ? _encodeMetadata(metadata!) : null,
    };
  }

  factory WalletAccount.fromMap(Map<String, dynamic> map) {
    return WalletAccount(
      id: map['id'],
      address: map['address'],
      accountType: map['account_type'],
      isActive: map['is_active'] == 1,
      parentIdentityId: map['parent_identity_id'],
      tokenUrl: map['token_url'],
      keyBookId: map['key_book_id'],
      keyPageId: map['key_page_id'],
      metadata: map['metadata'] != null ? _decodeMetadata(map['metadata']) : null,
    );
  }

  WalletAccount copyWith({
    int? id,
    String? address,
    String? accountType,
    bool? isActive,
    int? parentIdentityId,
    String? tokenUrl,
    int? keyBookId,
    int? keyPageId,
    Map<String, dynamic>? metadata,
  }) {
    return WalletAccount(
      id: id ?? this.id,
      address: address ?? this.address,
      accountType: accountType ?? this.accountType,
      isActive: isActive ?? this.isActive,
      parentIdentityId: parentIdentityId ?? this.parentIdentityId,
      tokenUrl: tokenUrl ?? this.tokenUrl,
      keyBookId: keyBookId ?? this.keyBookId,
      keyPageId: keyPageId ?? this.keyPageId,
      metadata: metadata ?? this.metadata,
    );
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

/// Identity (ADI) model for Accumulate Digital Identifiers
class AccumulateIdentity {
  final int? id;
  final String name;
  final String url;
  final int keyBookCount;
  final int accountCount;
  final String? sponsorAddress;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  AccumulateIdentity({
    this.id,
    required this.name,
    required this.url,
    this.keyBookCount = 1,
    this.accountCount = 0,
    this.sponsorAddress,
    this.isActive = true,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'key_book_count': keyBookCount,
      'account_count': accountCount,
      'sponsor_address': sponsorAddress,
      'is_active': isActive ? 1 : 0,
      'metadata': metadata != null ? _encodeMetadata(metadata!) : null,
    };
  }

  factory AccumulateIdentity.fromMap(Map<String, dynamic> map) {
    return AccumulateIdentity(
      id: map['id'],
      name: map['name'],
      url: map['url'],
      keyBookCount: map['key_book_count'] ?? 1,
      accountCount: map['account_count'] ?? 0,
      sponsorAddress: map['sponsor_address'],
      isActive: map['is_active'] == 1,
      metadata: map['metadata'] != null ? _decodeMetadata(map['metadata']) : null,
    );
  }
}

/// KeyBook model for key management hierarchy
class AccumulateKeyBook {
  final int? id;
  final int identityId;
  final String name;
  final String url;
  final String? publicKeyHash;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  AccumulateKeyBook({
    this.id,
    required this.identityId,
    required this.name,
    required this.url,
    this.publicKeyHash,
    this.isActive = true,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'identity_id': identityId,
      'name': name,
      'url': url,
      'public_key_hash': publicKeyHash,
      'is_active': isActive ? 1 : 0,
      'metadata': metadata != null ? _encodeMetadata(metadata!) : null,
    };
  }

  factory AccumulateKeyBook.fromMap(Map<String, dynamic> map) {
    return AccumulateKeyBook(
      id: map['id'],
      identityId: map['identity_id'],
      name: map['name'],
      url: map['url'],
      publicKeyHash: map['public_key_hash'],
      isActive: map['is_active'] == 1,
      metadata: map['metadata'] != null ? _decodeMetadata(map['metadata']) : null,
    );
  }
}

/// KeyPage model for key management hierarchy
class AccumulateKeyPage {
  final int? id;
  final int keyBookId;
  final String name;
  final String url;
  final int keysRequired;
  final int keysRequiredOf;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  AccumulateKeyPage({
    this.id,
    required this.keyBookId,
    required this.name,
    required this.url,
    this.keysRequired = 1,
    this.keysRequiredOf = 1,
    this.isActive = true,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'key_book_id': keyBookId,
      'name': name,
      'url': url,
      'keys_required': keysRequired,
      'keys_required_of': keysRequiredOf,
      'is_active': isActive ? 1 : 0,
      'metadata': metadata != null ? _encodeMetadata(metadata!) : null,
    };
  }

  factory AccumulateKeyPage.fromMap(Map<String, dynamic> map) {
    return AccumulateKeyPage(
      id: map['id'],
      keyBookId: map['key_book_id'],
      name: map['name'],
      url: map['url'],
      keysRequired: map['keys_required'] ?? 1,
      keysRequiredOf: map['keys_required_of'] ?? 1,
      isActive: map['is_active'] == 1,
      metadata: map['metadata'] != null ? _decodeMetadata(map['metadata']) : null,
    );
  }
}

/// Key model for cryptographic keys
class AccumulateKey {
  final int? id;
  final int keyPageId;
  final String name;
  final String publicKey;
  final String privateKeyEncrypted;
  final String? publicKeyHash;
  final bool isDefault;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  AccumulateKey({
    this.id,
    required this.keyPageId,
    required this.name,
    required this.publicKey,
    required this.privateKeyEncrypted,
    this.publicKeyHash,
    this.isDefault = false,
    this.isActive = true,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'key_page_id': keyPageId,
      'nickname': name,
      'public_key': publicKey,
      'private_key_encrypted': privateKeyEncrypted,
      'public_key_hash': publicKeyHash,
      'is_default': isDefault ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'metadata': metadata != null ? _encodeMetadata(metadata!) : null,
    };
  }

  factory AccumulateKey.fromMap(Map<String, dynamic> map) {
    return AccumulateKey(
      id: map['id'],
      keyPageId: map['key_page_id'],
      name: map['nickname'],
      publicKey: map['public_key'],
      privateKeyEncrypted: map['private_key_encrypted'],
      publicKeyHash: map['public_key_hash'],
      isDefault: map['is_default'] == 1,
      isActive: map['is_active'] == 1,
      metadata: map['metadata'] != null ? _decodeMetadata(map['metadata']) : null,
    );
  }
}

/// Custom Token model for user-created tokens
class AccumulateCustomToken {
  final int? id;
  final String name;
  final String symbol;
  final String url;
  final int precision;
  final int? creatorIdentityId;
  final Map<String, dynamic>? metadata;

  AccumulateCustomToken({
    this.id,
    required this.name,
    required this.symbol,
    required this.url,
    this.precision = 8,
    this.creatorIdentityId,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'url': url,
      'precision': precision,
      'creator_identity_id': creatorIdentityId,
      'metadata': metadata != null ? _encodeMetadata(metadata!) : null,
    };
  }

  factory AccumulateCustomToken.fromMap(Map<String, dynamic> map) {
    return AccumulateCustomToken(
      id: map['id'],
      name: map['name'],
      symbol: map['symbol'],
      url: map['url'],
      precision: map['precision'] ?? 8,
      creatorIdentityId: map['creator_identity_id'],
      metadata: map['metadata'] != null ? _decodeMetadata(map['metadata']) : null,
    );
  }
}

/// Data Account model for data storage
class AccumulateDataAccount {
  final int? id;
  final String name;
  final String url;
  final int parentIdentityId;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  AccumulateDataAccount({
    this.id,
    required this.name,
    required this.url,
    required this.parentIdentityId,
    this.isActive = true,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'parent_identity_id': parentIdentityId,
      'is_active': isActive ? 1 : 0,
      'metadata': metadata != null ? _encodeMetadata(metadata!) : null,
    };
  }

  factory AccumulateDataAccount.fromMap(Map<String, dynamic> map) {
    return AccumulateDataAccount(
      id: map['id'],
      name: map['name'],
      url: map['url'],
      parentIdentityId: map['parent_identity_id'],
      isActive: map['is_active'] == 1,
      metadata: map['metadata'] != null ? _decodeMetadata(map['metadata']) : null,
    );
  }
}