import 'package:flutter/foundation.dart';
// Purchase credits service for buying credits with ACME
import 'dart:convert';
import 'dart:typed_data';
import '../blockchain/enhanced_accumulate_service.dart';
import '../crypto/key_management_service.dart';
import '../storage/database_helper.dart';
import '../identity/identity_management_service.dart';
import '../token/token_management_service.dart';
import '../../models/accumulate_requests.dart';
import '../../models/local_storage_models.dart' hide TransactionRecord;
import 'package:accumulate_api/accumulate_api.dart';

class PurchaseCreditsService {
  final DatabaseHelper _dbHelper;
  final KeyManagementService _keyService;
  final EnhancedAccumulateService _accumulateService;
  final IdentityManagementService _identityService;
  final TokenManagementService _tokenService;

  PurchaseCreditsService({
    required DatabaseHelper dbHelper,
    required KeyManagementService keyService,
    required EnhancedAccumulateService accumulateService,
    required IdentityManagementService identityService,
    required TokenManagementService tokenService,
  })  : _dbHelper = dbHelper,
        _keyService = keyService,
        _accumulateService = accumulateService,
        _identityService = identityService,
        _tokenService = tokenService;

  /// Purchase credits for a lite account or key page
  Future<PurchaseCreditsResponse> purchaseCredits(PurchaseCreditsRequest request) async {
    try {
      // Validate inputs
      if (request.creditAmount <= 0) {
        return PurchaseCreditsResponse.failure('Credit amount must be greater than 0');
      }

      if (request.oracleValue <= 0) {
        return PurchaseCreditsResponse.failure('Invalid oracle value');
      }

      // Validate URLs
      if (!_isValidAccumulateUrl(request.recipientUrl)) {
        return PurchaseCreditsResponse.failure('Invalid recipient URL format');
      }

      if (!_isValidAccumulateUrl(request.payerUrl)) {
        return PurchaseCreditsResponse.failure('Invalid payer URL format');
      }

      // For lite token accounts, we need to use the base lite identity for signing
      // Extract base lite identity from token account URL
      String baseLiteIdentity = request.payerUrl;
      if (request.payerUrl.endsWith('/ACME')) {
        baseLiteIdentity = request.payerUrl.substring(0, request.payerUrl.length - 5);
      }

      // Get payer signer (must be a lite identity)
      final payerSigner = await _keyService.createLiteIdentitySigner(baseLiteIdentity);
      if (payerSigner == null) {
        return PurchaseCreditsResponse.failure('Unable to create signer for payer lite identity: $baseLiteIdentity');
      }

      // Calculate ACME amount required
      final acmeRequired = request.acmeAmountRequired;

      debugPrint('Payer token account: ${request.payerUrl}');
      debugPrint('Payer lite identity: $baseLiteIdentity');
      debugPrint('Recipient: ${request.recipientUrl}');
      debugPrint('ACME amount: $acmeRequired');
      debugPrint('Oracle value: ${request.oracleValue}');

      // Create addCredits parameters
      final addCreditsParam = AddCreditsParam();
      addCreditsParam.recipient = request.recipientUrl;
      addCreditsParam.amount = acmeRequired;
      addCreditsParam.oracle = request.oracleValue;

      if (request.memo != null) {
        addCreditsParam.memo = request.memo;
      }

      if (request.metadata != null) {
        addCreditsParam.metadata = utf8.encode(jsonEncode(request.metadata)).asUint8List();
      }

      // Execute the transaction
      final client = ACMEClient(_accumulateService.baseUrl);
      final response = await client.addCredits(
        request.payerUrl,
        addCreditsParam,
        payerSigner,
      );

      final result = _parseResponse(response);

      if (result.success && result.transactionId != null) {
        // Store transaction record for tracking
        final transactionRecord = TransactionRecord(
          transactionId: result.transactionId!,
          type: 'add_credits',
          direction: 'Outgoing',
          fromUrl: request.payerUrl,
          toUrl: request.recipientUrl,
          amount: acmeRequired,
          tokenUrl: 'credits',
          timestamp: DateTime.now(),
          status: 'pending',
          memo: request.memo,
        );

        try {
          await _dbHelper.insertTransaction(transactionRecord);
        } catch (e) {
          // Ignore database errors for transaction logging
        }

        return PurchaseCreditsResponse.success(
          transactionId: result.transactionId,
          hash: result.hash,
          creditsPurchased: request.creditAmount,
          acmeSpent: acmeRequired,
          data: result.data,
        );
      }

      return PurchaseCreditsResponse.failure(result.error ?? 'Transaction failed');
    } catch (e) {
      return PurchaseCreditsResponse.failure('Error purchasing credits: ${e.toString()}');
    }
  }

  /// Query current oracle value
  Future<OracleResponse> queryOracleValue() async {
    try {
      final client = ACMEClient(_accumulateService.baseUrl);
      final oracleValue = await client.valueFromOracle();

      if (oracleValue > 0) {
        return OracleResponse.success(oracleValue: oracleValue);
      }

      return OracleResponse.failure('Invalid oracle value received');
    } catch (e) {
      return OracleResponse.failure('Error querying oracle: ${e.toString()}');
    }
  }

  /// Get available credit accounts (lite accounts + key pages) for dropdown
  Future<List<CreditAccount>> getCreditAccountsForDropdown() async {
    final creditAccounts = <CreditAccount>[];

    try {
      // Get lite accounts
      final liteAccounts = await _tokenService.getAllLiteAccounts();
      for (final account in liteAccounts) {
        creditAccounts.add(CreditAccount.fromLiteAccount(account));
      }

      // Get key pages
      final keyPages = await _identityService.getAllKeyPages();
      for (final keyPage in keyPages) {
        // Get parent identity name for display
        String? parentIdentityName;
        // TODO: Implement getKeyBookById and getIdentityById methods
        // if (keyPage.keyBookId != null) {
        //   final keyBook = await _identityService.getKeyBookById(keyPage.keyBookId!);
        //   if (keyBook != null && keyBook.identityId != null) {
        //     final identity = await _identityService.getIdentityById(keyBook.identityId!);
        //     parentIdentityName = identity?.name;
        //   }
        // }

        creditAccounts.add(CreditAccount.fromKeyPage(keyPage, parentIdentityName));
      }
    } catch (e) {
      // Return empty list on error
    }

    return creditAccounts;
  }

  /// Get available ACME payer accounts (lite accounts only) for dropdown
  Future<List<CreditAccount>> getACMEPayerAccountsForDropdown() async {
    try {
      final liteAccounts = await _tokenService.getAllLiteAccounts();
      return liteAccounts.map((account) => CreditAccount.fromLiteAccount(account)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Calculate cost preview for credit purchase
  Future<Map<String, dynamic>> calculateCreditCost({
    required int creditAmount,
    int? oracleValue,
  }) async {
    try {
      // Get current oracle value if not provided
      int currentOracle = oracleValue ?? 0;
      if (currentOracle <= 0) {
        final oracleResponse = await queryOracleValue();
        if (oracleResponse.success && oracleResponse.oracleValue != null) {
          currentOracle = oracleResponse.oracleValue!;
        } else {
          return {
            'success': false,
            'error': 'Unable to get oracle value',
          };
        }
      }

      // Calculate ACME cost
      final acmeCost = (creditAmount * 100000000) ~/ currentOracle;
      final acmeCostFormatted = _formatACMEAmount(acmeCost);

      return {
        'success': true,
        'creditAmount': creditAmount,
        'acmeCost': acmeCost,
        'acmeCostFormatted': acmeCostFormatted,
        'oracleValue': currentOracle,
        'costPerCredit': acmeCost / creditAmount,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error calculating cost: ${e.toString()}',
      };
    }
  }

  /// Validate if an account can receive credits
  Future<bool> canReceiveCredits(String accountUrl) async {
    try {
      final client = ACMEClient(_accumulateService.baseUrl);
      final response = await client.queryUrl(accountUrl);

      if (response['result'] != null) {
        final type = response['result']['type'];
        // Credits can be added to lite accounts and key pages
        return type == 'liteTokenAccount' ||
               type == 'keyPage' ||
               type == 'lite_account';
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get credit balance for an account
  Future<int?> getCreditBalance(String accountUrl) async {
    try {
      final client = ACMEClient(_accumulateService.baseUrl);
      final response = await client.queryUrl(accountUrl);

      if (response['result'] != null && response['result']['data'] != null) {
        final data = response['result']['data'];
        return data['creditBalance'] ?? data['credits'];
      }

      return null;
    } catch (e) {
      return null;
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

  /// Validate Accumulate URL format
  bool _isValidAccumulateUrl(String url) {
    final RegExp urlPattern = RegExp(r'^acc://[a-zA-Z0-9\-\.\/]+$');
    return urlPattern.hasMatch(url) && url.length > 6;
  }

  /// Format ACME amount for display
  String _formatACMEAmount(int amount) {
    final divisor = 100000000; // 10^8
    final major = amount ~/ divisor;
    final minor = amount % divisor;

    if (minor == 0) {
      return major.toString();
    }

    final minorStr = minor.toString().padLeft(8, '0');
    final trimmedMinor = minorStr.replaceAll(RegExp(r'0+$'), '');

    if (trimmedMinor.isEmpty) {
      return major.toString();
    }

    return '$major.$trimmedMinor';
  }

  /// Parse API response to standardized format
  PurchaseCreditsResponse _parseResponse(Map<String, dynamic> response) {
    try {
      final result = response['result'];

      if (result != null) {
        // Check for transaction result format
        if (result is List && result.isNotEmpty) {
          // Handle array format responses
          final firstItem = result[0];
          if (firstItem is Map && firstItem.containsKey('failed') && firstItem['failed'] == true) {
            final error = firstItem['error']?['message'] ?? 'Transaction failed';
            return PurchaseCreditsResponse.failure(error);
          }
        }

        // Extract transaction ID
        final txId = response['result']?['txid'] ?? response['result']?['transactionId'];
        final hash = response['result']?['hash'];

        if (txId != null) {
          return PurchaseCreditsResponse.success(
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
        return PurchaseCreditsResponse.failure(message);
      }

      return PurchaseCreditsResponse.failure('Unknown response format');
    } catch (e) {
      return PurchaseCreditsResponse.failure('Error parsing response: ${e.toString()}');
    }
  }
}