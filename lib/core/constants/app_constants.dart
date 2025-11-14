// Core application constants - no Flutter dependencies

import 'package:flutter/material.dart';

class AppConstants {
  // Network URLs - Using Kermit testnet
  static const String defaultAccumulateTestnetUrl =
      'https://testnet.accumulatenetwork.io/v2';
  static const String defaultAccumulateKermitTestnetUrl =
      'https://kermit.accumulatenetwork.io/v2';  // Kermit testnet endpoint
  // Commented out other networks - using testnet only
  // static const String defaultAccumulateDevnetUrl =
  //     'http://10.0.2.2:26660/v2';  // Use 10.0.2.2 for Android emulator to reach host localhost
  // static const String defaultMainnetUrl =
  //     'https://mainnet.accumulatenetwork.io/v3';

  // Explorer URLs
  static const String testnetExplorerBaseUrl =
      'https://kermit.explorer.accumulatenetwork.io';  // Kermit testnet explorer
  static const String mainnetExplorerBaseUrl =
      'https://explorer.accumulatenetwork.io';

  // Polling intervals
  static const Duration defaultPendingTxPollingInterval = Duration(seconds: 45);
  static const Duration badgeRefreshInterval = Duration(minutes: 30);

  // Token types
  static const String acmeTokenType = 'ACME';

  // Faucet addresses
  static const String devnetFaucetAddress = 'acc://a21555da824d14f3f066214657a44e6a1a347dad3052a23a/ACME';
  static const String testnetFaucetAddress = 'acc://faucet.testnet/ACME';

  // Account types
  static const String defaultBookPath = '/book/1';

  // Storage keys
  static const String userIdKey = 'userId';
  static const String addTxMemosKey = 'add_tx_memos';

  /// Format lite account address to show first 6 and last 6 characters
  /// Example: acc://a21555da824d14f3f066214657a44e6a1a347dad3052a23a/ACME
  /// becomes: acc://a21555...052a23a/ACME
  static String formatLiteAccountAddress(String address) {
    try {
      if (!address.startsWith('acc://')) {
        return address; // Return as-is if not an accumulate address
      }

      // Split by '/' to handle token suffix
      final parts = address.split('/');
      if (parts.length < 2) {
        return address; // Return as-is if format is unexpected
      }

      final baseUrl = parts[0]; // acc://hash
      final suffix = parts.length > 2 ? '/${parts.sublist(2).join('/')}' : '';

      // Check if baseUrl is long enough to contain "acc://" + hash
      if (baseUrl.length <= 6) {
        return address; // Return as-is if baseUrl is too short
      }

      // Extract the hash part (everything after acc://)
      final hash = baseUrl.substring(6);

      if (hash.length <= 12) {
        return address; // Return as-is if hash is too short to truncate
      }

      // Create truncated version: first 6 + ... + last 6
      final truncatedHash = '${hash.substring(0, 6)}...${hash.substring(hash.length - 6)}';

      return 'acc://$truncatedHash$suffix';
    } catch (e) {
      // If any error occurs, return the original address
      debugPrint('Error formatting address "$address": $e');
      return address;
    }
  }
}

class NetworkType {
  static const String devnet = 'devnet';
  static const String testnet = 'testnet';
  static const String mainnet = 'mainnet';
}

class TransactionTypes {
  static const String createDataAccount = 'createDataAccount';
  static const String writeData = 'writeData';
  static const String createTokenAccount = 'createTokenAccount';
  static const String sendTokens = 'sendTokens';
  static const String createKeyPage = 'createKeyPage';
  static const String createKeyBook = 'createKeyBook';
  static const String addCredits = 'addCredits';
  static const String updateKey = 'updateKey';
}
