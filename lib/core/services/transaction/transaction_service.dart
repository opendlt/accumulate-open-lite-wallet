import 'package:flutter/foundation.dart';
// Transaction service for send/receive operations
import 'dart:typed_data';
import '../blockchain/enhanced_accumulate_service.dart';
import '../crypto/key_management_service.dart';
import '../storage/database_helper.dart';
import '../../models/accumulate_requests.dart';
import '../../models/local_storage_models.dart' hide TransactionRecord;
import 'package:accumulate_api/accumulate_api.dart';

class TransactionService {
  final DatabaseHelper _dbHelper;
  final KeyManagementService _keyService;
  final EnhancedAccumulateService _accumulateService;

  TransactionService({
    required DatabaseHelper dbHelper,
    required KeyManagementService keyService,
    required EnhancedAccumulateService accumulateService,
  })  : _dbHelper = dbHelper,
        _keyService = keyService,
        _accumulateService = accumulateService;

  /// Send tokens from one account to another
  Future<AccumulateResponse> sendTokens(SendTokensRequest request) async {
    try {
      // Validate recipients
      if (request.recipients.isEmpty) {
        return AccumulateResponse.failure('At least one recipient is required');
      }

      // Determine signing method based on account type
      final signer = await _createSigner(request.signerUrl);
      if (signer == null) {
        return AccumulateResponse.failure('Unable to create signer for account');
      }

      // Create send tokens parameters
      final sendTokensParam = SendTokensParam();
      sendTokensParam.to = request.recipients.map((recipient) {
        final tokenRecipientParam = TokenRecipientParam();
        tokenRecipientParam.url = recipient.accountUrl;
        tokenRecipientParam.amount = recipient.amount;
        return tokenRecipientParam;
      }).toList();

      if (request.memo != null) {
        sendTokensParam.memo = request.memo;
      }

      if (request.metadata != null) {
        sendTokensParam.metadata = Uint8List.fromList(request.metadata.toString().codeUnits);
      }

      // Execute the transaction
      final client = ACMEClient(_accumulateService.baseUrl);
      final response = await client.sendTokens(
        request.fromAccountUrl,
        sendTokensParam,
        signer,
      );

      final result = _parseResponse(response);

      if (result.success && result.transactionId != null) {
        // Store transaction record locally
        for (final recipient in request.recipients) {
          final transactionRecord = TransactionRecord(
            transactionId: result.transactionId!,
            type: 'send_token',
            direction: 'Outgoing',
            fromUrl: request.fromAccountUrl,
            toUrl: recipient.accountUrl,
            amount: recipient.amount,
            tokenUrl: await _getTokenUrlFromAccount(request.fromAccountUrl),
            timestamp: DateTime.now(),
            status: 'pending',
            memo: request.memo,
          );

          await _dbHelper.insertTransaction(transactionRecord);
        }
      }

      return result;
    } catch (e) {
      return AccumulateResponse.failure('Error sending tokens: ${e.toString()}');
    }
  }

  /// Query account balance
  Future<BalanceResponse> queryBalance(QueryBalanceRequest request) async {
    try {
      final client = ACMEClient(_accumulateService.baseUrl);
      final response = await client.queryUrl(request.accountUrl);

      if (response['result'] != null) {
        final data = response['result']['data'];

        if (data != null) {
          // Handle different account types
          if (data['balance'] != null) {
            // Token account balance
            final balance = int.tryParse(data['balance'].toString()) ?? 0;
            final tokenUrl = data['tokenUrl'] ?? request.tokenUrl ?? 'acc://ACME';

            return BalanceResponse.success(
              balance: balance,
              tokenUrl: tokenUrl,
              precision: await _getTokenPrecision(tokenUrl),
            );
          } else if (data['creditBalance'] != null) {
            // Credit balance for lite accounts
            final balance = int.tryParse(data['creditBalance'].toString()) ?? 0;

            return BalanceResponse.success(
              balance: balance,
              tokenUrl: 'credits',
              precision: 8,
            );
          }
        }
      }

      return BalanceResponse.failure('Unable to query account balance');
    } catch (e) {
      return BalanceResponse.failure('Error querying balance: ${e.toString()}');
    }
  }

  /// Query transaction history for an account
  Future<TransactionHistoryResponse> queryTransactionHistory(
      QueryTransactionHistoryRequest request) async {
    try {
      final client = ACMEClient(_accumulateService.baseUrl);

      // Set up pagination parameters
      final pagination = QueryPagination();
      pagination.start = request.start;
      pagination.count = request.count;

      final historyOptions = TxHistoryQueryOptions();
      if (request.scratch != null) {
        historyOptions.scratch = request.scratch;
      }

      // Query from network
      final response = await client.queryTxHistory(
        request.accountUrl,
        pagination,
        historyOptions,
      );

      final transactions = <TransactionRecord>[];

      if (response['result'] != null && response['result']['items'] != null) {
        final items = response['result']['items'] as List;

        for (final item in items) {
          final transactionRecord = _parseTransactionFromHistory(item, request.accountUrl);
          if (transactionRecord != null) {
            transactions.add(transactionRecord);

            // Store in local database for caching
            try {
              await _dbHelper.insertTransaction(transactionRecord);
            } catch (e) {
              // Ignore duplicate key errors
            }
          }
        }
      }

      // Also get local transactions that might not be on network yet
      final localTransactions = await _dbHelper.getTransactionHistory(
        address: request.accountUrl,
        limit: request.count,
        offset: request.start,
      );

      // Merge and deduplicate transactions
      final allTransactions = <String, TransactionRecord>{};

      // Add network transactions first (they're more authoritative)
      for (final tx in transactions) {
        allTransactions[tx.transactionId] = tx;
      }

      // Add local transactions that aren't already present
      for (final tx in localTransactions) {
        if (!allTransactions.containsKey(tx.transactionId)) {
          allTransactions[tx.transactionId] = tx;
        }
      }

      // Sort by timestamp descending
      final sortedTransactions = allTransactions.values.toList();
      sortedTransactions.sort((a, b) {
        if (a.timestamp == null && b.timestamp == null) return 0;
        if (a.timestamp == null) return 1;
        if (b.timestamp == null) return -1;
        return b.timestamp!.compareTo(a.timestamp!);
      });

      return TransactionHistoryResponse.success(
        transactions: sortedTransactions.take(request.count).toList(),
        total: sortedTransactions.length,
      );
    } catch (e) {
      // Fall back to local data on network error
      final localTransactions = await _dbHelper.getTransactionHistory(
        address: request.accountUrl,
        limit: request.count,
        offset: request.start,
      );

      return TransactionHistoryResponse.success(
        transactions: localTransactions,
        total: localTransactions.length,
      );
    }
  }

  /// Validate an account address
  Future<ValidateAddressResponse> validateAddress(ValidateAddressRequest request) async {
    try {
      // Check format first
      if (!_isValidAccumulateUrl(request.address)) {
        return ValidateAddressResponse.success(isValid: false);
      }

      // Query the network to check if account exists
      final client = ACMEClient(_accumulateService.baseUrl);
      final response = await client.queryUrl(request.address);

      if (response['result'] != null) {
        final data = response['result']['data'];
        final type = response['result']['type'];

        return ValidateAddressResponse.success(
          isValid: true,
          accountType: _mapAccountType(type),
          accountInfo: data != null ? Map<String, dynamic>.from(data) : null,
        );
      }

      return ValidateAddressResponse.success(isValid: false);
    } catch (e) {
      // If network query fails, still validate format
      return ValidateAddressResponse.success(
        isValid: _isValidAccumulateUrl(request.address),
      );
    }
  }

  /// Update transaction status (for pending transactions)
  Future<void> updateTransactionStatus(String transactionId, String status) async {
    await _dbHelper.updateTransactionStatus(transactionId, status);
  }

  /// Create appropriate signer based on account URL
  Future<TxSigner?> _createSigner(String accountUrl) async {
    try {
      if (accountUrl.contains('.acme')) {
        // ADI account - use key page signer
        return await _keyService.createADISigner(accountUrl);
      } else {
        // Lite account - use lite identity signer
        return await _keyService.createLiteIdentitySigner(accountUrl);
      }
    } catch (e) {
      return null;
    }
  }

  /// Get token URL from account
  Future<String?> _getTokenUrlFromAccount(String accountUrl) async {
    try {
      final client = ACMEClient(_accumulateService.baseUrl);
      final response = await client.queryUrl(accountUrl);

      if (response['result'] != null && response['result']['data'] != null) {
        return response['result']['data']['tokenUrl'] ?? 'acc://ACME';
      }

      return 'acc://ACME';
    } catch (e) {
      return 'acc://ACME';
    }
  }

  /// Get token precision
  Future<int> _getTokenPrecision(String tokenUrl) async {
    try {
      if (tokenUrl == 'acc://ACME' || tokenUrl == 'credits') {
        return 8;
      }

      // Check local custom tokens first
      final customTokens = await _dbHelper.getAllCustomTokens();
      for (final token in customTokens) {
        if (token.url == tokenUrl) {
          return token.precision;
        }
      }

      // Query network for token info
      final client = ACMEClient(_accumulateService.baseUrl);
      final response = await client.queryUrl(tokenUrl);

      if (response['result'] != null && response['result']['data'] != null) {
        return response['result']['data']['precision'] ?? 8;
      }

      return 8;
    } catch (e) {
      return 8;
    }
  }

  /// Parse transaction from history response
  TransactionRecord? _parseTransactionFromHistory(Map<String, dynamic> item, String accountUrl) {
    try {
      final txid = item['txid'];
      final type = item['type'];
      final timestamp = _parseTimestamp(item);

      if (txid == null || type == null) return null;

      switch (type) {
        case 'sendTokens':
          return _parseSendTokens(item, accountUrl, timestamp);
        case 'syntheticDepositTokens':
          return _parseDepositTokens(item, accountUrl, timestamp);
        case 'addCredits':
          return _parseAddCredits(item, accountUrl, timestamp);
        case 'faucet':
          return _parseFaucet(item, accountUrl, timestamp);
        default:
          return TransactionRecord(
            transactionId: txid,
            type: type,
            direction: 'Unknown',
            timestamp: timestamp,
            status: item['status']?['code'] ?? 'delivered',
          );
      }
    } catch (e) {
      return null;
    }
  }

  /// Parse sendTokens transaction
  TransactionRecord _parseSendTokens(Map<String, dynamic> item, String accountUrl, DateTime? timestamp) {
    final data = item['data'];
    final from = data['from'];
    final to = data['to'];

    String? toUrl;
    int? amount;

    if (to is List && to.isNotEmpty) {
      toUrl = to[0]['url'];
      amount = int.tryParse(to[0]['amount'].toString());
    }

    return TransactionRecord(
      transactionId: item['txid'],
      type: 'send_token',
      direction: from == accountUrl ? 'Outgoing' : 'Incoming',
      fromUrl: from,
      toUrl: toUrl,
      amount: amount,
      tokenUrl: 'acc://ACME',
      timestamp: timestamp,
      status: item['status']?['code'] ?? 'delivered',
    );
  }

  /// Parse syntheticDepositTokens transaction
  TransactionRecord _parseDepositTokens(Map<String, dynamic> item, String accountUrl, DateTime? timestamp) {
    final data = item['data'];

    return TransactionRecord(
      transactionId: item['txid'],
      type: 'receive_token',
      direction: 'Incoming',
      fromUrl: data['source'],
      toUrl: accountUrl,
      amount: int.tryParse(data['amount'].toString()),
      tokenUrl: data['token'] ?? 'acc://ACME',
      timestamp: timestamp,
      status: item['status']?['code'] ?? 'delivered',
    );
  }

  /// Parse addCredits transaction
  TransactionRecord _parseAddCredits(Map<String, dynamic> item, String accountUrl, DateTime? timestamp) {
    final data = item['data'];

    return TransactionRecord(
      transactionId: item['txid'],
      type: 'add_credits',
      direction: 'Incoming',
      fromUrl: item['sponsor'],
      toUrl: data['recipient'],
      amount: int.tryParse(data['amount'].toString()),
      tokenUrl: 'credits',
      timestamp: timestamp,
      status: item['status']?['code'] ?? 'delivered',
    );
  }

  /// Parse faucet transaction
  TransactionRecord _parseFaucet(Map<String, dynamic> item, String accountUrl, DateTime? timestamp) {
    final data = item['data'];

    return TransactionRecord(
      transactionId: item['txid'],
      type: 'faucet',
      direction: 'Incoming',
      fromUrl: 'acc://ACME',
      toUrl: accountUrl,
      amount: int.tryParse(data['amount'].toString()),
      tokenUrl: data['token'] ?? 'acc://ACME',
      timestamp: timestamp,
      status: item['status']?['code'] ?? 'delivered',
    );
  }

  /// Parse timestamp from transaction item
  DateTime? _parseTimestamp(Map<String, dynamic> item) {
    try {
      final signatures = item['signatures'];
      if (signatures is List && signatures.isNotEmpty) {
        final sig = signatures.last;
        final timestamp = sig['timestamp'];
        if (timestamp != null && timestamp != 1) {
          return DateTime.fromMicrosecondsSinceEpoch(timestamp);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Validate Accumulate URL format
  bool _isValidAccumulateUrl(String url) {
    // Basic validation for Accumulate URL format
    final RegExp urlPattern = RegExp(r'^acc://[a-zA-Z0-9\-\.\/]+$');
    return urlPattern.hasMatch(url) && url.length > 6;
  }

  /// Map network account type to our internal type
  String? _mapAccountType(String? networkType) {
    switch (networkType) {
      case 'tokenAccount':
        return 'token_account';
      case 'liteTokenAccount':
        return 'lite_account';
      case 'dataAccount':
        return 'data_account';
      case 'identity':
        return 'identity';
      case 'keyBook':
        return 'key_book';
      case 'keyPage':
        return 'key_page';
      default:
        return networkType;
    }
  }

  /// Parse API response to standardized format
  AccumulateResponse _parseResponse(Map<String, dynamic> response) {
    try {
      final result = response['result'];

      if (result != null) {
        // Check for transaction result format
        if (result is List && result.isNotEmpty) {
          // Handle array format responses
          final firstItem = result[0];
          if (firstItem is Map && firstItem.containsKey('failed') && firstItem['failed'] == true) {
            final error = firstItem['error']?['message'] ?? 'Transaction failed';
            return AccumulateResponse.failure(error);
          }
        }

        // Extract transaction ID
        final txId = response['result']?['txid'] ?? response['result']?['transactionId'];
        final hash = response['result']?['hash'];

        if (txId != null) {
          return AccumulateResponse.success(
            transactionId: txId.toString(),
            hash: hash?.toString(),
            data: result is Map ? Map<String, dynamic>.from(result) : null,
          );
        }
      }

      // Check for error in response
      final error = response['error'];
      if (error != null) {
        final message = error['message'] ?? error.toString();
        return AccumulateResponse.failure(message);
      }

      return AccumulateResponse.failure('Unknown response format');
    } catch (e) {
      return AccumulateResponse.failure('Error parsing response: ${e.toString()}');
    }
  }
}