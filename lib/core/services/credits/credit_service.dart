import 'package:flutter/foundation.dart';
// Credit service for purchasing credits using ACME tokens
import 'dart:math';
import '../blockchain/enhanced_accumulate_service.dart';
import '../crypto/key_management_service.dart';
import '../storage/database_helper.dart';
import '../../models/accumulate_requests.dart';
// Note: Using TransactionRecord from accumulate_requests (same as DatabaseHelper)
import '../../constants/app_constants.dart';
import 'package:accumulate_api/accumulate_api.dart';

class CreditService {
  final DatabaseHelper _dbHelper;
  final KeyManagementService _keyService;
  final EnhancedAccumulateService _accumulateService;

  CreditService({
    required DatabaseHelper dbHelper,
    required KeyManagementService keyService,
    required EnhancedAccumulateService accumulateService,
  })  : _dbHelper = dbHelper,
        _keyService = keyService,
        _accumulateService = accumulateService;

  /// Purchase credits by converting ACME tokens to credits
  Future<CreditResponse> purchaseCredits(PurchaseCreditRequest request) async {
    try {
      // Validate input parameters
      if (request.creditAmount <= 0) {
        return CreditResponse.failure('Credit amount must be greater than 0');
      }

      if (request.recipientUrl.isEmpty || request.payerAccountUrl.isEmpty) {
        return CreditResponse.failure('Recipient and payer accounts are required');
      }

      // Get current oracle value for conversion
      final client = ACMEClient(_accumulateService.baseUrl);
      debugPrint('Getting oracle value...');
      final oracle = await client.valueFromOracle();
      debugPrint('Oracle value: $oracle');

      // Calculate ACME amount needed
      // Formula: acmeAmount = (creditAmount * 100 * 10^8) / oracle
      // Multiply by 100 because credits need to be scaled to the proper protocol units
      final acmeAmount = (request.creditAmount * 100 * pow(10, 8).toInt()) ~/ oracle;
      debugPrint('Credits requested: ${request.creditAmount}');
      debugPrint('ACME amount required: $acmeAmount');

      // Create signer for the payer account
      // For lite accounts, the signer is the LiteIdentity (without /ACME)
      String signerUrl = request.payerAccountUrl;
      if (request.payerAccountUrl.endsWith('/ACME')) {
        signerUrl = request.payerAccountUrl.substring(0, request.payerAccountUrl.length - 5);
      }

      debugPrint('Payer account: ${request.payerAccountUrl}');
      debugPrint('Signer (LID): $signerUrl');

      // Debug: Check what keys exist for this account
      debugPrint('Debugging account keys...');
      await _keyService.debugAccountKeys(request.payerAccountUrl);

      // Also check what accounts exist in the database
      debugPrint('Checking database accounts...');
      final allAccounts = await _dbHelper.getAllAccounts();
      debugPrint('Database accounts found: ${allAccounts.length}');
      for (final account in allAccounts) {
        debugPrint('   - ${account.address} (${account.accountType})');
      }

      final payerSigner = await _createSigner(signerUrl);
      if (payerSigner == null) {
        return CreditResponse.failure('Unable to create signer for payer account');
      }

      // Create AddCreditsParam
      final addCreditsParam = AddCreditsParam();
      addCreditsParam.recipient = request.recipientUrl;
      addCreditsParam.amount = acmeAmount;
      addCreditsParam.oracle = oracle;
      addCreditsParam.memo = request.memo ?? 'Credit purchase via Accumulate Lite Wallet';

      debugPrint('Purchasing credits...');
      debugPrint('From: ${request.payerAccountUrl}');
      debugPrint('To: ${request.recipientUrl}');
      debugPrint('Credits: ${request.creditAmount}');
      debugPrint('ACME cost: $acmeAmount');

      // Execute the addCredits transaction
      final response = await client.addCredits(
        request.payerAccountUrl,
        addCreditsParam,
        payerSigner!,
      );

      debugPrint('Add credits response: $response');

      final result = _parseResponse(response);

      if (result.success && result.transactionId != null) {
        // Store transaction record for tracking
        final transactionRecord = TransactionRecord(
          transactionId: result.transactionId!,
          type: 'add_credits',
          direction: 'Outgoing',
          fromUrl: request.payerAccountUrl,
          toUrl: request.recipientUrl,
          amount: acmeAmount,
          tokenUrl: 'ACME',
          timestamp: DateTime.now(),
          status: 'pending',
          memo: 'Credit purchase: ${request.creditAmount} credits',
        );

        try {
          await _dbHelper.insertTransaction(transactionRecord);
        } catch (e) {
          // Ignore database errors for transaction logging
          debugPrint(' Warning: Could not store transaction record: $e');
        }

        return CreditResponse.success(
          transactionId: result.transactionId,
          hash: result.hash,
          creditsAmount: request.creditAmount,
          acmeAmount: acmeAmount,
          oracle: oracle,
          data: result.data,
        );
      }

      return CreditResponse.failure(result.error ?? 'Credit purchase failed');
    } catch (e) {
      return CreditResponse.failure('Error purchasing credits: ${e.toString()}');
    }
  }

  /// Get current oracle value for credit cost calculations
  Future<int?> getCurrentOracleValue() async {
    try {
      final client = ACMEClient(_accumulateService.baseUrl);
      return await client.valueFromOracle();
    } catch (e) {
      debugPrint('Error getting oracle value: $e');
      return null;
    }
  }

  /// Calculate ACME cost for a given number of credits
  Future<CreditCostCalculation> calculateCreditCost(int creditAmount) async {
    try {
      final oracle = await getCurrentOracleValue();
      if (oracle == null) {
        return CreditCostCalculation.failure('Unable to get oracle value');
      }

      final acmeAmount = (creditAmount * 100 * pow(10, 8).toInt()) ~/ oracle;
      final acmeTokens = acmeAmount / 100000000; // Convert to ACME tokens

      return CreditCostCalculation.success(
        creditAmount: creditAmount,
        acmeAmount: acmeAmount,
        acmeTokens: acmeTokens,
        oracle: oracle,
      );
    } catch (e) {
      return CreditCostCalculation.failure('Error calculating cost: ${e.toString()}');
    }
  }

  /// Get recent credit transactions
  Future<List<TransactionRecord>> getRecentCreditTransactions({int limit = 20}) async {
    try {
      final allTransactions = await _dbHelper.getTransactionHistory(limit: limit * 2);
      return allTransactions
          .where((tx) => tx.type == 'add_credits')
          .take(limit)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Create appropriate signer based on account URL
  Future<TxSigner?> _createSigner(String accountUrl) async {
    try {
      if (accountUrl.contains('.acme')) {
        // ADI account - use key page signer
        final keyPageUrl = accountUrl.contains('/book/')
            ? accountUrl
            : '${accountUrl.replaceAll('/ACME', '')}/book/1';
        debugPrint('🔐 Creating ADI signer for key page: $keyPageUrl');
        return await _keyService.createADISigner(keyPageUrl);
      } else {
        // Lite account - use lite identity signer
        // Extract base lite identity from token account URL if needed
        String baseLiteIdentity = accountUrl;
        if (accountUrl.endsWith('/ACME')) {
          baseLiteIdentity = accountUrl.substring(0, accountUrl.length - 5);
        }

        debugPrint('Creating lite identity signer for: $baseLiteIdentity');
        final signer = await _keyService.createLiteIdentitySigner(baseLiteIdentity);

        if (signer == null) {
          // Try with the full account URL (including /ACME) in case that's how it was stored
          debugPrint('Retrying with full account URL: $accountUrl');
          final signerWithFullUrl = await _keyService.createLiteIdentitySigner(accountUrl);
          if (signerWithFullUrl != null) {
            debugPrint(' Found signer using full account URL');
            return signerWithFullUrl;
          }

          debugPrint(' No private key found for either:');
          debugPrint('   - Base identity: $baseLiteIdentity');
          debugPrint('   - Full account: $accountUrl');
          return null;
        }

        return signer;
      }
    } catch (e) {
      debugPrint(' Error creating signer: $e');
      return null;
    }
  }

  /// Parse API response to standardized format
  CreditResponse _parseResponse(Map<String, dynamic> response) {
    try {
      final result = response['result'];

      if (result != null) {
        // Check for transaction result format
        if (result is List && result.isNotEmpty) {
          // Handle array format responses
          final firstItem = result[0];
          if (firstItem is Map && firstItem.containsKey('failed') && firstItem['failed'] == true) {
            final error = firstItem['error']?['message'] ?? 'Credit transaction failed';
            return CreditResponse.failure(error);
          }
        }

        // Extract transaction ID
        final txId = response['result']?['txid'] ?? response['result']?['transactionId'];
        final hash = response['result']?['hash'];

        if (txId != null) {
          return CreditResponse.success(
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
        return CreditResponse.failure(message);
      }

      return CreditResponse.failure('Unknown response format');
    } catch (e) {
      return CreditResponse.failure('Error parsing response: ${e.toString()}');
    }
  }
}

/// Request model for purchasing credits
class PurchaseCreditRequest {
  final String recipientUrl;
  final String payerAccountUrl;
  final int creditAmount;
  final String? memo;

  PurchaseCreditRequest({
    required this.recipientUrl,
    required this.payerAccountUrl,
    required this.creditAmount,
    this.memo,
  });
}

/// Response model for credit operations
class CreditResponse {
  final bool success;
  final String? error;
  final String? transactionId;
  final String? hash;
  final int? creditsAmount;
  final int? acmeAmount;
  final int? oracle;
  final Map<String, dynamic>? data;

  CreditResponse._({
    required this.success,
    this.error,
    this.transactionId,
    this.hash,
    this.creditsAmount,
    this.acmeAmount,
    this.oracle,
    this.data,
  });

  factory CreditResponse.success({
    String? transactionId,
    String? hash,
    int? creditsAmount,
    int? acmeAmount,
    int? oracle,
    Map<String, dynamic>? data,
  }) {
    return CreditResponse._(
      success: true,
      transactionId: transactionId,
      hash: hash,
      creditsAmount: creditsAmount,
      acmeAmount: acmeAmount,
      oracle: oracle,
      data: data,
    );
  }

  factory CreditResponse.failure(String error) {
    return CreditResponse._(
      success: false,
      error: error,
    );
  }
}

/// Cost calculation response
class CreditCostCalculation {
  final bool success;
  final String? error;
  final int? creditAmount;
  final int? acmeAmount;
  final double? acmeTokens;
  final int? oracle;

  CreditCostCalculation._({
    required this.success,
    this.error,
    this.creditAmount,
    this.acmeAmount,
    this.acmeTokens,
    this.oracle,
  });

  factory CreditCostCalculation.success({
    required int creditAmount,
    required int acmeAmount,
    required double acmeTokens,
    required int oracle,
  }) {
    return CreditCostCalculation._(
      success: true,
      creditAmount: creditAmount,
      acmeAmount: acmeAmount,
      acmeTokens: acmeTokens,
      oracle: oracle,
    );
  }

  factory CreditCostCalculation.failure(String error) {
    return CreditCostCalculation._(
      success: false,
      error: error,
    );
  }
}