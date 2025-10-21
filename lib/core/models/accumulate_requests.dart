// Request models for Accumulate API operations
import 'dart:convert';

import 'package:accumulate_lite_wallet/core/models/local_storage_models.dart';

/// Base request class for common fields
abstract class AccumulateRequest {
  final String? memo;
  final Map<String, dynamic>? metadata;

  AccumulateRequest({
    this.memo,
    this.metadata,
  });
}

/// Request for creating an identity (ADI)
class CreateIdentityRequest extends AccumulateRequest {
  final String name; // Identity name (without acc:// prefix)
  final String sponsorAddress; // Lite account sponsoring the creation
  final String keyBookName; // Default key book name (usually "book0")
  final String publicKeyHash; // Public key hash for the first key page

  CreateIdentityRequest({
    required this.name,
    required this.sponsorAddress,
    required this.keyBookName,
    required this.publicKeyHash,
    super.memo,
    super.metadata,
  });

  String get identityUrl => 'acc://$name.acme';
  String get keyBookUrl => '$identityUrl/$keyBookName';
}

/// Request for creating a lite token account
class CreateLiteTokenAccountRequest extends AccumulateRequest {
  final String sponsorAddress; // Sponsoring lite account
  final String? tokenUrl; // Token URL (null for ACME)

  CreateLiteTokenAccountRequest({
    required this.sponsorAddress,
    this.tokenUrl,
    super.memo,
    super.metadata,
  });
}

/// Request for creating an ADI token account
class CreateADITokenAccountRequest extends AccumulateRequest {
  final String name; // Account name
  final String identityUrl; // Parent identity URL
  final String tokenUrl; // Token URL
  final String keyPageUrl; // Key page for signing

  CreateADITokenAccountRequest({
    required this.name,
    required this.identityUrl,
    required this.tokenUrl,
    required this.keyPageUrl,
    super.memo,
    super.metadata,
  });

  String get accountUrl => '$identityUrl/$name';
}

/// Request for creating a data account
class CreateDataAccountRequest extends AccumulateRequest {
  final String name; // Account name
  final String identityUrl; // Parent identity URL
  final String keyPageUrl; // Key page for signing

  CreateDataAccountRequest({
    required this.name,
    required this.identityUrl,
    required this.keyPageUrl,
    super.memo,
    super.metadata,
  });

  String get accountUrl => '$identityUrl/$name';
}

/// Request for creating a key book
class CreateKeyBookRequest extends AccumulateRequest {
  final String name; // Key book name
  final String identityUrl; // Parent identity URL
  final String publicKeyHash; // Public key hash for authorization
  final String keyPageUrl; // Key page for signing

  CreateKeyBookRequest({
    required this.name,
    required this.identityUrl,
    required this.publicKeyHash,
    required this.keyPageUrl,
    super.memo,
    super.metadata,
  });

  String get keyBookUrl => '$identityUrl/$name';
}

/// Request for creating a key page
class CreateKeyPageRequest extends AccumulateRequest {
  final String name; // Key page name (usually a number like "1", "2")
  final String keyBookUrl; // Parent key book URL
  final List<String> publicKeyHashes; // Public key hashes for this page
  final String signerKeyPageUrl; // Key page for signing
  final int keysRequired; // Number of keys required for signing

  CreateKeyPageRequest({
    required this.name,
    required this.keyBookUrl,
    required this.publicKeyHashes,
    required this.signerKeyPageUrl,
    this.keysRequired = 1,
    super.memo,
    super.metadata,
  });

  String get keyPageUrl => '$keyBookUrl/$name';
}

/// Request for creating a custom token
class CreateCustomTokenRequest extends AccumulateRequest {
  final String name; // Token name
  final String symbol; // Token symbol
  final String identityUrl; // Parent identity URL
  final String keyPageUrl; // Key page for signing
  final int precision; // Token precision (default 8)

  CreateCustomTokenRequest({
    required this.name,
    required this.symbol,
    required this.identityUrl,
    required this.keyPageUrl,
    this.precision = 8,
    super.memo,
    super.metadata,
  });

  String get tokenUrl => '$identityUrl/$name';
}

/// Request for minting tokens
class MintTokensRequest extends AccumulateRequest {
  final String tokenUrl; // Token URL to mint
  final String recipientUrl; // Recipient account URL
  final int amount; // Amount to mint (in base units)
  final String keyPageUrl; // Key page for signing

  MintTokensRequest({
    required this.tokenUrl,
    required this.recipientUrl,
    required this.amount,
    required this.keyPageUrl,
    super.memo,
    super.metadata,
  });
}

/// Request for burning tokens
class BurnTokensRequest extends AccumulateRequest {
  final String tokenAccountUrl; // Token account URL to burn from
  final int amount; // Amount to burn (in base units)
  final String keyPageUrl; // Key page for signing

  BurnTokensRequest({
    required this.tokenAccountUrl,
    required this.amount,
    required this.keyPageUrl,
    super.memo,
    super.metadata,
  });
}


/// Response for successful operations
class AccumulateResponse {
  final bool success;
  final String? transactionId;
  final String? hash;
  final String? error;
  final Map<String, dynamic>? data;

  AccumulateResponse({
    required this.success,
    this.transactionId,
    this.hash,
    this.error,
    this.data,
  });

  AccumulateResponse.success({
    String? transactionId,
    String? hash,
    Map<String, dynamic>? data,
  }) : this(
      success: true,
      transactionId: transactionId,
      hash: hash,
      data: data,
    );

  AccumulateResponse.failure(String error) : this(
      success: false,
      error: error,
    );
}

/// Request for sending tokens
class SendTokensRequest extends AccumulateRequest {
  final String fromAccountUrl; // Source account URL
  final List<TokenRecipient> recipients; // List of recipients
  final String signerUrl; // Signing account (lite account or key page)

  SendTokensRequest({
    required this.fromAccountUrl,
    required this.recipients,
    required this.signerUrl,
    super.memo,
    super.metadata,
  });
}

/// Token recipient for send operations
class TokenRecipient {
  final String accountUrl; // Recipient account URL
  final int amount; // Amount in base units

  TokenRecipient({
    required this.accountUrl,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': accountUrl,
      'amount': amount,
    };
  }
}

/// Request for querying account balance
class QueryBalanceRequest {
  final String accountUrl;
  final String? tokenUrl; // null for ACME, specific URL for custom tokens

  QueryBalanceRequest({
    required this.accountUrl,
    this.tokenUrl,
  });
}

/// Response for balance queries
class BalanceResponse {
  final bool success;
  final String? error;
  final int? balance; // Balance in base units
  final String? tokenUrl;
  final int? precision;

  BalanceResponse({
    required this.success,
    this.error,
    this.balance,
    this.tokenUrl,
    this.precision,
  });

  factory BalanceResponse.success({
    required int balance,
    String? tokenUrl,
    int? precision,
  }) {
    return BalanceResponse(
      success: true,
      balance: balance,
      tokenUrl: tokenUrl,
      precision: precision,
    );
  }

  factory BalanceResponse.failure(String error) {
    return BalanceResponse(
      success: false,
      error: error,
    );
  }
}

/// Request for querying transaction history
class QueryTransactionHistoryRequest {
  final String accountUrl;
  final int start; // Starting index for pagination
  final int count; // Number of transactions to fetch
  final bool? scratch; // Query scratch space

  QueryTransactionHistoryRequest({
    required this.accountUrl,
    this.start = 0,
    this.count = 50,
    this.scratch,
  });
}

/// Transaction history response
class TransactionHistoryResponse {
  final bool success;
  final String? error;
  final List<TransactionRecord> transactions;
  final int? total; // Total number of transactions

  TransactionHistoryResponse({
    required this.success,
    this.error,
    this.transactions = const [],
    this.total,
  });

  factory TransactionHistoryResponse.success({
    required List<TransactionRecord> transactions,
    int? total,
  }) {
    return TransactionHistoryResponse(
      success: true,
      transactions: transactions,
      total: total,
    );
  }

  factory TransactionHistoryResponse.failure(String error) {
    return TransactionHistoryResponse(
      success: false,
      error: error,
    );
  }
}

/// Individual transaction record
class TransactionRecord {
  final String transactionId;
  final String type; // send_token, receive_token, add_credits, etc.
  final String direction; // Incoming, Outgoing
  final String? fromUrl;
  final String? toUrl;
  final int? amount; // Amount in base units
  final String? tokenUrl;
  final DateTime? timestamp;
  final String? status; // delivered, pending, failed
  final String? memo;

  TransactionRecord({
    required this.transactionId,
    required this.type,
    required this.direction,
    this.fromUrl,
    this.toUrl,
    this.amount,
    this.tokenUrl,
    this.timestamp,
    this.status,
    this.memo,
  });

  Map<String, dynamic> toMap() {
    return {
      'transaction_id': transactionId,
      'type': type,
      'direction': direction,
      'from_url': fromUrl,
      'to_url': toUrl,
      'amount': amount,
      'token_url': tokenUrl,
      'timestamp': timestamp?.millisecondsSinceEpoch,
      'status': status,
      'memo': memo,
    };
  }

  factory TransactionRecord.fromMap(Map<String, dynamic> map) {
    return TransactionRecord(
      transactionId: map['transaction_id'] ?? '',
      type: map['type'] ?? '',
      direction: map['direction'] ?? '',
      fromUrl: map['from_url'],
      toUrl: map['to_url'],
      amount: map['amount'],
      tokenUrl: map['token_url'],
      timestamp: map['timestamp'] != null ? DateTime.fromMillisecondsSinceEpoch(map['timestamp']) : null,
      status: map['status'],
      memo: map['memo'],
    );
  }
}

/// Request for validating an address
class ValidateAddressRequest {
  final String address; // Address to validate

  ValidateAddressRequest({
    required this.address,
  });
}

/// Response for address validation
class ValidateAddressResponse {
  final bool success;
  final String? error;
  final bool isValid;
  final String? accountType; // lite_account, token_account, data_account, identity
  final Map<String, dynamic>? accountInfo;

  ValidateAddressResponse({
    required this.success,
    this.error,
    required this.isValid,
    this.accountType,
    this.accountInfo,
  });

  factory ValidateAddressResponse.success({
    required bool isValid,
    String? accountType,
    Map<String, dynamic>? accountInfo,
  }) {
    return ValidateAddressResponse(
      success: true,
      isValid: isValid,
      accountType: accountType,
      accountInfo: accountInfo,
    );
  }

  factory ValidateAddressResponse.failure(String error) {
    return ValidateAddressResponse(
      success: false,
      error: error,
      isValid: false,
    );
  }
}

/// Request for writing data to a data account
class WriteDataRequest extends AccumulateRequest {
  final String dataAccountUrl; // Target data account URL
  final List<String> dataEntries; // List of data entries to write
  final String signerUrl; // Signing account (lite account or key page)
  final bool scratch; // Write to scratch space
  final bool writeToState; // Write to state (not allowed for lite data accounts)

  WriteDataRequest({
    required this.dataAccountUrl,
    required this.dataEntries,
    required this.signerUrl,
    this.scratch = false,
    this.writeToState = false,
    super.memo,
    super.metadata,
  });
}


/// Request for querying data from a data account
class QueryDataRequest {
  final String dataAccountUrl; // Data account URL to query
  final String? entryHash; // Specific entry hash (optional)
  final int start; // Starting index for pagination
  final int count; // Number of entries to fetch
  final bool? scratch; // Query scratch space

  QueryDataRequest({
    required this.dataAccountUrl,
    this.entryHash,
    this.start = 0,
    this.count = 50,
    this.scratch,
  });
}

/// Response for data operations
class DataResponse {
  final bool success;
  final String? error;
  final String? transactionId;
  final String? hash;
  final List<DataEntry>? entries;
  final Map<String, dynamic>? data;

  DataResponse({
    required this.success,
    this.error,
    this.transactionId,
    this.hash,
    this.entries,
    this.data,
  });

  factory DataResponse.success({
    String? transactionId,
    String? hash,
    List<DataEntry>? entries,
    Map<String, dynamic>? data,
  }) {
    return DataResponse(
      success: true,
      transactionId: transactionId,
      hash: hash,
      entries: entries,
      data: data,
    );
  }

  factory DataResponse.failure(String error) {
    return DataResponse(
      success: false,
      error: error,
    );
  }
}

/// Individual data entry
class DataEntry {
  final String? entryHash; // Hash of the data entry
  final String data; // The actual data content
  final DateTime? timestamp; // When the entry was written
  final String? transactionId; // Transaction that created this entry
  final bool isState; // Whether this is state data or scratch data
  final Map<String, dynamic>? metadata;

  DataEntry({
    this.entryHash,
    required this.data,
    this.timestamp,
    this.transactionId,
    this.isState = false,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'entry_hash': entryHash,
      'data': data,
      'timestamp': timestamp?.millisecondsSinceEpoch,
      'transaction_id': transactionId,
      'is_state': isState ? 1 : 0,
      'metadata': metadata != null ? jsonEncode(metadata) : null,
    };
  }

  factory DataEntry.fromMap(Map<String, dynamic> map) {
    return DataEntry(
      entryHash: map['entry_hash'],
      data: map['data'] ?? '',
      timestamp: map['timestamp'] != null ? DateTime.fromMillisecondsSinceEpoch(map['timestamp']) : null,
      transactionId: map['transaction_id'],
      isState: (map['is_state'] ?? 0) == 1,
      metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : null,
    );
  }

  factory DataEntry.fromNetworkResponse(Map<String, dynamic> response) {
    return DataEntry(
      entryHash: response['entryHash'],
      data: response['data'] ?? '',
      timestamp: response['timestamp'] != null
          ? DateTime.fromMicrosecondsSinceEpoch(response['timestamp'])
          : null,
      transactionId: response['txid'],
      isState: response['type'] == 'AccumulateDataEntry',
    );
  }
}

/// Request for querying data account information
class QueryDataAccountRequest {
  final String dataAccountUrl;
  final bool? expand; // Expand the response with additional details

  QueryDataAccountRequest({
    required this.dataAccountUrl,
    this.expand,
  });
}

/// Response for data account information
class DataAccountResponse {
  final bool success;
  final String? error;
  final String? url;
  final String? accountType;
  final List<String>? authorities;
  final int? entryCount;
  final String? lastEntryHash;
  final Map<String, dynamic>? chainInfo;

  DataAccountResponse({
    required this.success,
    this.error,
    this.url,
    this.accountType,
    this.authorities,
    this.entryCount,
    this.lastEntryHash,
    this.chainInfo,
  });

  factory DataAccountResponse.success({
    String? url,
    String? accountType,
    List<String>? authorities,
    int? entryCount,
    String? lastEntryHash,
    Map<String, dynamic>? chainInfo,
  }) {
    return DataAccountResponse(
      success: true,
      url: url,
      accountType: accountType,
      authorities: authorities,
      entryCount: entryCount,
      lastEntryHash: lastEntryHash,
      chainInfo: chainInfo,
    );
  }

  factory DataAccountResponse.failure(String error) {
    return DataAccountResponse(
      success: false,
      error: error,
    );
  }
}

/// Request for data account history
class QueryDataHistoryRequest {
  final String dataAccountUrl;
  final int start; // Starting index for pagination
  final int count; // Number of entries to fetch
  final bool? scratch; // Query scratch space
  final bool? expand; // Expand entries with additional details

  QueryDataHistoryRequest({
    required this.dataAccountUrl,
    this.start = 0,
    this.count = 50,
    this.scratch,
    this.expand,
  });
}

/// Response for data history
class DataHistoryResponse {
  final bool success;
  final String? error;
  final List<DataEntry> entries;
  final int? totalCount;
  final String? nextStart;

  DataHistoryResponse({
    required this.success,
    this.error,
    this.entries = const [],
    this.totalCount,
    this.nextStart,
  });

  factory DataHistoryResponse.success({
    required List<DataEntry> entries,
    int? totalCount,
    String? nextStart,
  }) {
    return DataHistoryResponse(
      success: true,
      entries: entries,
      totalCount: totalCount,
      nextStart: nextStart,
    );
  }

  factory DataHistoryResponse.failure(String error) {
    return DataHistoryResponse(
      success: false,
      error: error,
    );
  }
}

/// Request for purchasing credits
class PurchaseCreditsRequest extends AccumulateRequest {
  final String recipientUrl; // Target account to receive credits (lite account or key page)
  final int creditAmount; // Amount of credits to purchase
  final String payerUrl; // ACME payer account (lite account)
  final int oracleValue; // Current oracle value for credit calculation

  PurchaseCreditsRequest({
    required this.recipientUrl,
    required this.creditAmount,
    required this.payerUrl,
    required this.oracleValue,
    super.memo,
    super.metadata,
  });

  /// Calculate ACME amount needed for the credit purchase
  int get acmeAmountRequired {
    // Credits are priced in ACME based on oracle value
    // Formula: (creditAmount * 10^8) / oracleValue
    return (creditAmount * 100000000) ~/ oracleValue;
  }
}

/// Response for purchase credits operation
class PurchaseCreditsResponse {
  final bool success;
  final String? error;
  final String? transactionId;
  final String? hash;
  final int? creditsPurchased;
  final int? acmeSpent;
  final Map<String, dynamic>? data;

  PurchaseCreditsResponse({
    required this.success,
    this.error,
    this.transactionId,
    this.hash,
    this.creditsPurchased,
    this.acmeSpent,
    this.data,
  });

  factory PurchaseCreditsResponse.success({
    String? transactionId,
    String? hash,
    int? creditsPurchased,
    int? acmeSpent,
    Map<String, dynamic>? data,
  }) {
    return PurchaseCreditsResponse(
      success: true,
      transactionId: transactionId,
      hash: hash,
      creditsPurchased: creditsPurchased,
      acmeSpent: acmeSpent,
      data: data,
    );
  }

  factory PurchaseCreditsResponse.failure(String error) {
    return PurchaseCreditsResponse(
      success: false,
      error: error,
    );
  }
}

/// Request for querying oracle value
class QueryOracleRequest {
  // No parameters needed for basic oracle query
  const QueryOracleRequest();
}

/// Response for oracle value query
class OracleResponse {
  final bool success;
  final String? error;
  final int? oracleValue; // Current oracle value

  OracleResponse({
    required this.success,
    this.error,
    this.oracleValue,
  });

  factory OracleResponse.success({
    required int oracleValue,
  }) {
    return OracleResponse(
      success: true,
      oracleValue: oracleValue,
    );
  }

  factory OracleResponse.failure(String error) {
    return OracleResponse(
      success: false,
      error: error,
    );
  }
}

/// Credit account information for dropdown selection
class CreditAccount {
  final String name;
  final String url;
  final String accountType; // 'lite_account' or 'key_page'
  final String? parentIdentity; // For key pages

  CreditAccount({
    required this.name,
    required this.url,
    required this.accountType,
    this.parentIdentity,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
      'accountType': accountType,
      'parentIdentity': parentIdentity,
    };
  }

  factory CreditAccount.fromLiteAccount(WalletAccount account) {
    return CreditAccount(
      name: account.name,
      url: account.address,
      accountType: 'lite_account',
    );
  }

  factory CreditAccount.fromKeyPage(AccumulateKeyPage keyPage, String? parentIdentityName) {
    return CreditAccount(
      name: keyPage.name,
      url: keyPage.url,
      accountType: 'key_page',
      parentIdentity: parentIdentityName,
    );
  }

  String get displayName {
    if (accountType == 'key_page' && parentIdentity != null) {
      return '$name ($parentIdentity)';
    }
    return '$name ($accountType)';
  }
}

/// Key pair data for key management
class KeyPairData {
  final String publicKey;
  final String privateKey;
  final String publicKeyHash;

  KeyPairData({
    required this.publicKey,
    required this.privateKey,
    required this.publicKeyHash,
  });
}

/// Request for faucet tokens (devnet/testnet only)
class FaucetRequest extends AccumulateRequest {
  final String accountUrl; // Account to receive test tokens
  final String tokenUrl; // Token type to request (usually ACME)
  final int amount; // Amount to request (in smallest units)

  FaucetRequest({
    required this.accountUrl,
    required this.tokenUrl,
    required this.amount,
    super.memo,
    super.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'accountUrl': accountUrl,
      'tokenUrl': tokenUrl,
      'amount': amount,
      'memo': memo,
      'metadata': metadata,
    };
  }
}

/// Response for faucet token requests
class FaucetResponse extends AccumulateResponse {
  final String? transactionId;
  final String? hash;
  final int? tokensReceived;
  final String? tokenUrl;

  FaucetResponse.success({
    this.transactionId,
    this.hash,
    this.tokensReceived,
    this.tokenUrl,
    super.data,
  }) : super.success();

  FaucetResponse.failure(String error) :
    transactionId = null,
    hash = null,
    tokensReceived = null,
    tokenUrl = null,
    super.failure(error);

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'error': error,
      'transactionId': transactionId,
      'hash': hash,
      'tokensReceived': tokensReceived,
      'tokenUrl': tokenUrl,
      'data': data,
    };
  }
}