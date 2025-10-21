import 'package:flutter/foundation.dart';
// Faucet service for requesting test tokens on devnet/testnet
import 'dart:convert';
import 'package:path/path.dart';

import '../blockchain/enhanced_accumulate_service.dart';
import '../crypto/key_management_service.dart';
import '../storage/database_helper.dart';
import '../token/token_management_service.dart';
import '../../models/accumulate_requests.dart';
import '../../models/local_storage_models.dart' show WalletAccount;
import '../../constants/app_constants.dart';
import 'package:accumulate_api/accumulate_api.dart';

class FaucetService {
  final DatabaseHelper _dbHelper;
  final KeyManagementService _keyService;
  final EnhancedAccumulateService _accumulateService;
  final TokenManagementService _tokenService;

  FaucetService({
    required DatabaseHelper dbHelper,
    required KeyManagementService keyService,
    required EnhancedAccumulateService accumulateService,
    required TokenManagementService tokenService,
  })  : _dbHelper = dbHelper,
        _keyService = keyService,
        _accumulateService = accumulateService,
        _tokenService = tokenService;

  /// Request test tokens from faucet (devnet/testnet only)
  Future<FaucetResponse> requestTokens(FaucetRequest request) async {
    try {
      // Validate network (faucet only works on devnet/testnet)
      if (!_isTestNetwork()) {
        return FaucetResponse.failure('Faucet is only available on devnet and testnet');
      }

      // Validate account URL
      if (!_isValidAccumulateUrl(request.accountUrl)) {
        return FaucetResponse.failure('Invalid account URL format');
      }

      // Use the faucet API endpoint
      final response = await _callFaucetAPI(request);

      final result = _parseResponse(response);

      if (result.success && result.transactionId != null) {
        // Determine faucet address for transaction record
        String faucetAddress;
        final endpoint = _accumulateService.baseUrl;
        if (endpoint.contains('devnet') || endpoint.contains('localhost')) {
          faucetAddress = AppConstants.devnetFaucetAddress;
        } else if (endpoint.contains('testnet')) {
          faucetAddress = AppConstants.testnetFaucetAddress;
        } else {
          faucetAddress = 'faucet';
        }

        // Store transaction record for tracking
        final transactionRecord = TransactionRecord(
          transactionId: result.transactionId!,
          type: 'faucet',
          direction: 'Incoming',
          fromUrl: faucetAddress,
          toUrl: request.accountUrl,
          amount: request.amount,
          tokenUrl: request.tokenUrl,
          timestamp: DateTime.now(),
          status: 'pending',
          memo: request.memo ?? 'Faucet tokens',
        );

        try {
          await _dbHelper.insertTransaction(transactionRecord);
        } catch (e) {
          // Ignore database errors for transaction logging
        }

        return FaucetResponse.success(
          transactionId: result.transactionId,
          hash: result.hash,
          tokensReceived: request.amount,
          tokenUrl: request.tokenUrl,
          data: result.data,
        );
      }

      return FaucetResponse.failure(result.error ?? 'Faucet request failed');
    } catch (e) {
      return FaucetResponse.failure('Error requesting tokens: ${e.toString()}');
    }
  }

  /// Get available lite accounts for faucet
  Future<List<WalletAccount>> getLiteAccountsForFaucet() async {
    try {
      return await _tokenService.getAllLiteAccounts();
    } catch (e) {
      return [];
    }
  }

  /// Check if account can receive faucet tokens
  Future<bool> canReceiveFaucetTokens(String accountUrl) async {
    try {
      final client = ACMEClient(_accumulateService.baseUrl);
      final response = await client.queryUrl(accountUrl);

      if (response['result'] != null) {
        final type = response['result']['type'];
        // Faucet tokens can be sent to lite accounts primarily
        return type == 'liteTokenAccount' || type == 'lite_account';
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get recent faucet transactions
  Future<List<TransactionRecord>> getRecentFaucetTransactions({int limit = 20}) async {
    try {
      final allTransactions = await _dbHelper.getTransactionHistory(limit: limit * 2);
      return allTransactions
          .where((tx) => tx.type == 'faucet')
          .take(limit)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if current network supports faucet
  bool _isTestNetwork() {
    // This should be coordinated with the main app's network selection
    // For now, assume we can check the accumulate service endpoint
    final endpoint = _accumulateService.baseUrl;
    return endpoint.contains('testnet') || endpoint.contains('devnet') || endpoint.contains('localhost') || endpoint.contains('10.0.2.2');
  }

  /// Validate Accumulate URL format
  bool _isValidAccumulateUrl(String url) {
    final RegExp urlPattern = RegExp(r'^acc://[a-zA-Z0-9\\-\\.\\/]+$');
    return urlPattern.hasMatch(url) && url.length > 6;
  }

  /// Verify that account exists on the network
  Future<bool> _verifyAccountExists(String accountUrl) async {
    try {
      final client = ACMEClient(_accumulateService.baseUrl);
      final response = await client.queryUrl(accountUrl);
      return response['result'] != null;
    } catch (e) {
      return false;
    }
  }

  /// Call the faucet API to request tokens
  Future<Map<String, dynamic>> _callFaucetAPI(FaucetRequest request) async {
    try {
      final client = ACMEClient(_accumulateService.baseUrl);

      // Determine faucet address based on network
      String faucetAddress;
      final endpoint = _accumulateService.baseUrl;
      if (endpoint.contains('devnet') || endpoint.contains('localhost') || endpoint.contains('10.0.2.2')) {
        faucetAddress = AppConstants.devnetFaucetAddress;
      } else if (endpoint.contains('testnet')) {
        faucetAddress = AppConstants.testnetFaucetAddress;
      } else {
        throw Exception('Faucet not available on mainnet');
      }

      debugPrint('Using faucet address: $faucetAddress');
      debugPrint('Target account: ${request.accountUrl}');
      debugPrint('Amount: ${request.amount}');

      // Debug the client setup
      debugPrint('Client endpoint: ${_accumulateService.baseUrl}');
      debugPrint('Request account URL: ${request.accountUrl}');

      // Test basic connectivity first with a simple describe call
      try {
        debugPrint('Testing basic connectivity with describe call...');
        final describeResponse = await client.describe();
        debugPrint(' Describe response: $describeResponse');
      } catch (e) {
        debugPrint(' Describe call failed: $e');
        throw Exception('Cannot connect to network: ${e.toString()}');
      }

      // Try using the built-in faucet method
      try {
        final accountUrl = AccURL(request.accountUrl);
        debugPrint('AccURL object created: $accountUrl');
        debugPrint('AccURL string representation: ${accountUrl.toString()}');
        debugPrint('About to call client.faucet()...');

        final faucetResponse = await client.faucet(accountUrl);
        debugPrint(' Faucet response received: $faucetResponse');
        return faucetResponse;
      } catch (e, stackTrace) {
        debugPrint('  Faucet method failed: $e');
        debugPrint('Error type: ${e.runtimeType}');
        debugPrint('Stack trace: $stackTrace');

        // Try the simple string-based faucet method as fallback
        try {
          debugPrint('Trying faucetSimple method...');
          final simpleFaucetResponse = await client.faucetSimple(request.accountUrl);
          debugPrint(' Simple faucet response: $simpleFaucetResponse');
          return simpleFaucetResponse;
        } catch (simpleError) {
          debugPrint(' Simple faucet also failed: $simpleError');
        }

        // For now, let the error propagate so we can see what's happening
        rethrow;

        // TODO: Re-enable fallback once we debug the real faucet issue
        // return {
        //   'result': {
        //     'txid': 'faucet_${DateTime.now().millisecondsSinceEpoch}',
        //     'hash': 'hash_${DateTime.now().millisecondsSinceEpoch}',
        //     'from': faucetAddress,
        //     'to': request.accountUrl,
        //     'amount': request.amount,
        //   }
        // };
      }
    } catch (e) {
      throw Exception('Faucet request failed: ${e.toString()}');
    }
  }

  /// Parse API response to standardized format
  FaucetResponse _parseResponse(Map<String, dynamic> response) {
    try {
      final result = response['result'];

      if (result != null) {
        // Check for transaction result format
        if (result is List && result.isNotEmpty) {
          // Handle array format responses
          final firstItem = result[0];
          if (firstItem is Map && firstItem.containsKey('failed') && firstItem['failed'] == true) {
            final error = firstItem['error']?['message'] ?? 'Faucet request failed';
            return FaucetResponse.failure(error);
          }
        }

        // Extract transaction ID
        final txId = response['result']?['txid'] ?? response['result']?['transactionId'];
        final hash = response['result']?['hash'];

        if (txId != null) {
          return FaucetResponse.success(
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
        return FaucetResponse.failure(message);
      }

      return FaucetResponse.failure('Unknown response format');
    } catch (e) {
      return FaucetResponse.failure('Error parsing response: ${e.toString()}');
    }
  }
}