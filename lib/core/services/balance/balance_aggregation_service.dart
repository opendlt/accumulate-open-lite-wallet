import 'package:flutter/foundation.dart';
// Simplified balance aggregation service - direct RPC queries
import '../storage/database_helper.dart';
import '../../models/local_storage_models.dart';
import '../../constants/app_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BalanceAggregationService {
  final DatabaseHelper _dbHelper;
  static const String _apiUrl = AppConstants.defaultAccumulateDevnetUrl;

  // Simple rate limiting - max once every 30 seconds
  static DateTime? _lastBalanceCheck;
  static Future<BalanceAggregationResult>? _currentRequest;

  BalanceAggregationService({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  /// Simple balance aggregation - query accounts directly and update SQLite
  Future<BalanceAggregationResult> getTotalWalletBalance() async {
    // Prevent concurrent requests
    if (_currentRequest != null) {
      return await _currentRequest!;
    }

    // Rate limit - max once every 30 seconds
    final now = DateTime.now();
    if (_lastBalanceCheck != null &&
        now.difference(_lastBalanceCheck!).inSeconds < 30) {
      return getCachedWalletBalance();
    }

    _lastBalanceCheck = now;
    _currentRequest = _queryAllBalances();

    try {
      final result = await _currentRequest!;
      return result;
    } finally {
      _currentRequest = null;
    }
  }

  /// Direct RPC query approach: query(<account_url>) -> parse JSON -> update SQLite
  Future<BalanceAggregationResult> _queryAllBalances() async {
    try {
      final accounts = await _dbHelper.getAllAccounts();
      final List<AccountBalanceData> accountBalances = [];
      final List<String> errors = [];
      double totalBalance = 0.0;

      debugPrint('BALANCE: Checking ${accounts.length} accounts...');

      for (final account in accounts) {
        // Only check token accounts (lite and ADI)
        if (account.accountType == 'lite_account' ||
            account.accountType == 'token_account') {

          try {
            // Direct RPC call
            final balance = await _queryAccountBalance(account.address);
            if (balance > 0) {
              totalBalance += balance;

              final accountBalance = AccountBalanceData(
                accountAddress: account.address,
                accountName: account.name,
                acmeBalance: balance,
                accountType: account.accountType,
                updatedAt: DateTime.now(),
              );
              accountBalances.add(accountBalance);

              // Update SQLite
              await _dbHelper.insertOrUpdateAccountBalance(
                AccountBalance(
                  accountAddress: account.address,
                  accountName: account.name,
                  acmeBalance: balance,
                  accountType: account.accountType,
                  updatedAt: DateTime.now(),
                ),
              );

              debugPrint('${account.name}: ${balance.toStringAsFixed(2)} ACME');
            }
          } catch (e) {
            errors.add('Error querying ${account.address}: $e');
          }
        }
      }

      debugPrint(' Total: ${totalBalance.toStringAsFixed(2)} ACME');

      return BalanceAggregationResult(
        totalBalance: totalBalance,
        accountBalances: accountBalances,
        errors: errors,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      return BalanceAggregationResult(
        totalBalance: 0.0,
        accountBalances: [],
        errors: ['Error: $e'],
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Direct HTTP query to Accumulate API
  Future<double> _queryAccountBalance(String accountUrl) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'jsonrpc': '2.0',
          'method': 'query',
          'params': {'url': accountUrl},
          'id': 1,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'];

        if (result != null && result['data'] != null) {
          final accountData = result['data'];

          // Handle different balance fields
          final balance = accountData['balance'] ?? accountData['creditBalance'] ?? 0;

          // Convert from credits to ACME (divide by 100000000)
          return (balance is int ? balance : int.tryParse(balance.toString()) ?? 0) / 100000000.0;
        }
      }
      return 0.0;
    } catch (e) {
      debugPrint(' Error querying $accountUrl: $e');
      return 0.0;
    }
  }

  /// Get cached balances from database (fast)
  Future<BalanceAggregationResult> getCachedWalletBalance() async {
    try {
      final accountBalances = await _dbHelper.getAccountBalances();
      final totalBalance = accountBalances.fold<double>(
        0.0,
        (sum, account) => sum + account.acmeBalance,
      );

      return BalanceAggregationResult(
        totalBalance: totalBalance,
        accountBalances: accountBalances.map((ab) => AccountBalanceData(
          accountAddress: ab.accountAddress,
          accountName: ab.accountName,
          acmeBalance: ab.acmeBalance,
          accountType: ab.accountType,
          updatedAt: ab.updatedAt,
        )).toList(),
        errors: [],
        lastUpdated: accountBalances.isNotEmpty
          ? accountBalances.map((ab) => ab.updatedAt).reduce((a, b) => a.isAfter(b) ? a : b)
          : DateTime.now(),
      );
    } catch (e) {
      return BalanceAggregationResult(
        totalBalance: 0.0,
        accountBalances: [],
        errors: ['Error getting cached balances: $e'],
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Simple background refresh - just call getTotalWalletBalance which has rate limiting
  Future<void> refreshBalancesInBackground() async {
    getTotalWalletBalance().catchError((e) {
      debugPrint(' Background refresh failed: $e');
    });
  }

  /// Get balance summary for UI display
  Future<WalletBalanceSummary> getBalanceSummary() async {
    // Always get fresh data for the summary since this is the main display
    final fresh = await getTotalWalletBalance();

    // Get latest ACME price for USD calculation
    final latestAcmePrice = await _dbHelper.getLatestAcmePrice();
    final totalUsdValue = fresh.totalBalance * latestAcmePrice;

    // Calculate percentages for pie chart
    final List<AccountBalancePercentage> percentages = [];
    if (fresh.totalBalance > 0) {
      for (final account in fresh.accountBalances) {
        percentages.add(AccountBalancePercentage(
          accountAddress: account.accountAddress,
          accountName: account.accountName,
          acmeBalance: account.acmeBalance,
          percentage: (account.acmeBalance / fresh.totalBalance) * 100,
          accountType: account.accountType,
        ));
      }
    }

    return WalletBalanceSummary(
      totalBalance: fresh.totalBalance,
      totalUsdValue: totalUsdValue,
      latestAcmePrice: latestAcmePrice,
      accountCount: fresh.accountBalances.length,
      accountBalances: percentages,
      lastUpdated: fresh.lastUpdated,
      hasErrors: fresh.errors.isNotEmpty,
    );
  }
}

// Data classes
class BalanceAggregationResult {
  final double totalBalance;
  final List<AccountBalanceData> accountBalances;
  final List<String> errors;
  final DateTime lastUpdated;

  BalanceAggregationResult({
    required this.totalBalance,
    required this.accountBalances,
    required this.errors,
    required this.lastUpdated,
  });
}

class AccountBalanceData {
  final String accountAddress;
  final String accountName;
  final double acmeBalance;
  final String accountType;
  final DateTime updatedAt;

  AccountBalanceData({
    required this.accountAddress,
    required this.accountName,
    required this.acmeBalance,
    required this.accountType,
    required this.updatedAt,
  });
}

class AccountBalancePercentage {
  final String accountAddress;
  final String accountName;
  final double acmeBalance;
  final double percentage;
  final String accountType;

  AccountBalancePercentage({
    required this.accountAddress,
    required this.accountName,
    required this.acmeBalance,
    required this.percentage,
    required this.accountType,
  });
}

class WalletBalanceSummary {
  final double totalBalance;
  final double totalUsdValue;
  final double latestAcmePrice;
  final int accountCount;
  final List<AccountBalancePercentage> accountBalances;
  final DateTime lastUpdated;
  final bool hasErrors;

  WalletBalanceSummary({
    required this.totalBalance,
    required this.totalUsdValue,
    required this.latestAcmePrice,
    required this.accountCount,
    required this.accountBalances,
    required this.lastUpdated,
    required this.hasErrors,
  });
}