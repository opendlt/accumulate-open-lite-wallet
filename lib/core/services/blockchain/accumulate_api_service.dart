import 'package:flutter/foundation.dart';
// Core Accumulate blockchain API service - no Flutter dependencies
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/pending_transaction.dart';
import '../../models/account_balance.dart';
import '../../constants/app_constants.dart';
import '../networking/network_service.dart';

class AccumulateApiService {
  final String baseUrl;
  final NetworkService _networkService;

  AccumulateApiService({
    this.baseUrl = AppConstants.defaultAccumulateDevnetUrl,
  }) : _networkService = NetworkService() {
    debugPrint('Accumulate API Service initialized with endpoint: $baseUrl');
  }

  /// Query account balance
  Future<AccountBalance?> getAccountBalance(String accountUrl) async {
    try {
      final result = await _networkService.post(
        '$baseUrl/v3/query',
        headers: {'Content-Type': 'application/json'},
        body: {
          'method': 'query',
          'params': {
            'url': accountUrl,
          },
        },
      );

      if (result.success && result.statusCode == 200) {
        final data = result.jsonData;

        if (data != null &&
            data['result'] != null &&
            data['result']['data'] != null) {
          final accountData = data['result']['data'];

          return AccountBalance(
            accountUrl: accountUrl,
            balance: (accountData['balance'] ?? 0).toDouble(),
            tokenType: accountData['tokenUrl']?.toString().split('/').last ??
                AppConstants.acmeTokenType,
            lastUpdated: DateTime.now(),
          );
        }
      }
      return null;
    } catch (e) {
      // Log error in production app
      return null;
    }
  }

  /// Query pending transactions for a signer
  Future<List<PendingTransaction>> getPendingTransactions(
      String signerUrl) async {
    try {
      final result = await _networkService.post(
        '$baseUrl/v3/query',
        headers: {'Content-Type': 'application/json'},
        body: {
          'method': 'query-directory',
          'params': {
            'url': '$signerUrl/pending',
          },
        },
      );

      if (result.success && result.statusCode == 200) {
        final data = result.jsonData;

        if (data != null &&
            data['result'] != null &&
            data['result']['items'] != null) {
          final items = data['result']['items'] as List;

          return items.map((item) {
            return PendingTransaction(
              txId: item['txid']?.toString(),
              hash: item['hash']?.toString(),
              type: item['type']?.toString(),
            );
          }).toList();
        }
      }
      return [];
    } catch (e) {
      // Log error in production app
      return [];
    }
  }

  /// Submit a transaction
  Future<TransactionResult> submitTransaction(
      Map<String, dynamic> transactionData) async {
    try {
      final result = await _networkService.post(
        '$baseUrl/v3/submit',
        headers: {'Content-Type': 'application/json'},
        body: transactionData,
      );

      if (result.success && result.statusCode == 200) {
        final data = result.jsonData;

        return TransactionResult(
          success: data != null && data['result'] != null,
          transactionId: data?['result']?['txid']?.toString(),
          hash: data?['result']?['hash']?.toString(),
          error: data?['error']?['message']?.toString(),
        );
      } else {
        return TransactionResult(
          success: false,
          error: result.error ?? 'HTTP ${result.statusCode}: ${result.data}',
        );
      }
    } catch (e) {
      return TransactionResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}

class TransactionResult {
  final bool success;
  final String? transactionId;
  final String? hash;
  final String? error;

  const TransactionResult({
    required this.success,
    this.transactionId,
    this.hash,
    this.error,
  });
}
