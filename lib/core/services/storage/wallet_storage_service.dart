import 'package:flutter/foundation.dart';
// Unified wallet storage service combining SQLite and secure storage
import 'database_helper.dart';
import 'secure_keys_service.dart';
import '../../models/local_storage_models.dart' hide TransactionRecord;
import '../../models/accumulate_requests.dart' show TransactionRecord;
import 'dart:typed_data';

class WalletStorageService {
  static final WalletStorageService _instance = WalletStorageService._internal();
  factory WalletStorageService() => _instance;
  WalletStorageService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SecureKeysService _secureKeys = SecureKeysService();

  // ===== ACCOUNT MANAGEMENT =====

  /// Create a new wallet account with both public data and secure keys
  Future<WalletAccount> createAccount({
    required String address,
    required String accountType,
    String? privateKey,
    String? publicKey,
    String? mnemonic,
    Uint8List? seed,
    Map<String, dynamic>? metadata,
  }) async {
    final account = WalletAccount(
      address: address,
      accountType: accountType,
      metadata: metadata,
    );

    // Store account data in SQLite
    final accountId = await _dbHelper.insertAccount(account);
    final savedAccount = account.copyWith(id: accountId);

    // Store sensitive keys in secure storage
    debugPrint('Storing keys for address: $address');
    if (privateKey != null) {
      debugPrint('Storing private key...');
      await _secureKeys.storePrivateKey(address, privateKey);
      debugPrint(' Private key stored successfully');
    }
    if (publicKey != null) {
      debugPrint('Storing public key...');
      await _secureKeys.storePublicKey(address, publicKey);
      debugPrint('Public key stored successfully');
    }
    if (mnemonic != null) {
      await _secureKeys.storeMnemonic(address, mnemonic);
    }
    if (seed != null) {
      await _secureKeys.storeSeed(address, seed);
    }

    return savedAccount;
  }

  /// Get all wallet accounts with key availability info
  Future<List<WalletAccountInfo>> getAllAccountsWithKeyInfo() async {
    final accounts = await _dbHelper.getAllAccounts();
    final accountsWithKeyInfo = <WalletAccountInfo>[];

    for (final account in accounts) {
      final hasPrivateKey = await _secureKeys.hasPrivateKey(account.address);
      final hasMnemonic = await _secureKeys.hasMnemonic(account.address);

      accountsWithKeyInfo.add(WalletAccountInfo(
        account: account,
        hasPrivateKey: hasPrivateKey,
        hasMnemonic: hasMnemonic,
      ));
    }

    return accountsWithKeyInfo;
  }

  /// Get account with all associated key information
  Future<WalletAccountInfo?> getAccountWithKeys(String address) async {
    final account = await _dbHelper.getAccountByAddress(address);
    if (account == null) return null;

    final hasPrivateKey = await _secureKeys.hasPrivateKey(address);
    final hasMnemonic = await _secureKeys.hasMnemonic(address);
    final privateKey = hasPrivateKey ? await _secureKeys.getPrivateKey(address) : null;
    final publicKey = await _secureKeys.getPublicKey(address);

    return WalletAccountInfo(
      account: account,
      hasPrivateKey: hasPrivateKey,
      hasMnemonic: hasMnemonic,
      privateKey: privateKey,
      publicKey: publicKey,
    );
  }

  /// Delete an account and all associated keys
  Future<bool> deleteAccount(String address) async {
    try {
      // Delete from SQLite
      final account = await _dbHelper.getAccountByAddress(address);
      if (account?.id != null) {
        await _dbHelper.deleteAccount(account!.id!);
      }

      // Delete from secure storage
      await _secureKeys.deletePrivateKey(address);
      await _secureKeys.deletePublicKey(address);
      await _secureKeys.deleteMnemonic(address);
      await _secureKeys.deleteSeed(address);

      return true;
    } catch (e) {
      return false;
    }
  }

  // ===== TRANSACTION MANAGEMENT =====

  /// Record a new transaction
  Future<TransactionRecord> recordTransaction({
    required String txHash,
    required String fromAddress,
    required String toAddress,
    required int amount,
    required String tokenType,
    required String transactionType,
    String status = 'pending',
    String? memo,
    Map<String, dynamic>? metadata,
  }) async {
    final transaction = TransactionRecord(
      transactionId: txHash,
      type: transactionType,
      direction: fromAddress == toAddress ? 'Internal' : 'Outgoing',
      fromUrl: fromAddress,
      toUrl: toAddress,
      amount: amount,
      tokenUrl: tokenType,
      timestamp: DateTime.now(),
      status: status,
      memo: memo,
    );

    await _dbHelper.insertTransaction(transaction);
    return transaction;
  }

  /// Get transaction history for an address or all transactions
  Future<List<TransactionRecord>> getTransactionHistory({
    String? address,
    int limit = 50,
    int offset = 0,
  }) async {
    return _dbHelper.getTransactionHistory(
      address: address,
      limit: limit,
      offset: offset,
    );
  }

  /// Update transaction status (e.g., from pending to confirmed)
  Future<void> updateTransactionStatus(String txHash, String status) async {
    await _dbHelper.updateTransactionStatus(txHash, status);
  }

  // ===== PREFERENCES MANAGEMENT =====

  /// Set a user preference
  Future<void> setPreference(String key, dynamic value) async {
    await _dbHelper.setPreference(key, value);
  }

  /// Get a user preference with type safety
  Future<T?> getPreference<T>(String key, {T? defaultValue}) async {
    return await _dbHelper.getPreference<T>(key, defaultValue: defaultValue);
  }

  /// Get all user preferences
  Future<Map<String, dynamic>> getAllPreferences() async {
    return await _dbHelper.getAllPreferences();
  }

  // Common wallet preferences
  Future<void> setDeveloperModeEnabled(bool enabled) async {
    await setPreference('developer_mode_enabled', enabled);
  }

  Future<bool> isDeveloperModeEnabled() async {
    return await getPreference<bool>('developer_mode_enabled', defaultValue: false) ?? false;
  }

  Future<void> setDefaultNetwork(String network) async {
    await setPreference('default_network', network);
  }

  Future<String> getDefaultNetwork() async {
    return await getPreference<String>('default_network', defaultValue: 'mainnet') ?? 'mainnet';
  }

  Future<void> setBiometricAuthEnabled(bool enabled) async {
    await setPreference('biometric_auth_enabled', enabled);
    await _secureKeys.setBiometricEnabled(enabled);
  }

  Future<bool> isBiometricAuthEnabled() async {
    return await getPreference<bool>('biometric_auth_enabled', defaultValue: false) ?? false;
  }


  // ===== AUTHENTICATION MANAGEMENT =====

  /// Set up PIN authentication
  Future<void> setupPin(String pin) async {
    await _secureKeys.storePin(pin);
    await setPreference('pin_auth_enabled', true);
  }

  /// Verify PIN authentication
  Future<bool> verifyPin(String pin) async {
    return await _secureKeys.verifyPin(pin);
  }

  /// Check if PIN is set up
  Future<bool> hasPinSetup() async {
    return await _secureKeys.hasPin();
  }

  /// Remove PIN authentication
  Future<void> removePin() async {
    await _secureKeys.deletePin();
    await setPreference('pin_auth_enabled', false);
  }

  // ===== BACKUP AND RECOVERY =====

  /// Export wallet data for backup (excluding sensitive keys)
  Future<Map<String, dynamic>> exportWalletData() async {
    final accounts = await _dbHelper.getAllAccounts();
    final transactions = await _dbHelper.getTransactionHistory(limit: 1000);
    final preferences = await _dbHelper.getAllPreferences();

    return {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'accounts': accounts.map((a) => a.toMap()).toList(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'preferences': preferences,
    };
  }

  /// Export encrypted backup including keys
  Future<String?> exportEncryptedBackup(String password) async {
    return await _secureKeys.exportEncryptedBackup(password);
  }

  /// Import encrypted backup
  Future<bool> importEncryptedBackup(String encryptedBackup, String password) async {
    return await _secureKeys.importEncryptedBackup(encryptedBackup, password);
  }

  // ===== UTILITY METHODS =====

  /// Get comprehensive wallet statistics
  Future<WalletStatistics> getWalletStatistics() async {
    final dbStats = await _dbHelper.getDatabaseStats();
    final keyStats = await _secureKeys.getKeyStatistics();

    return WalletStatistics(
      totalAccounts: dbStats['accounts'] ?? 0,
      totalTransactions: dbStats['transactions'] ?? 0,
      totalPreferences: dbStats['preferences'] ?? 0,
      storedPrivateKeys: keyStats['privateKeys'] ?? 0,
      storedPublicKeys: keyStats['publicKeys'] ?? 0,
      storedMnemonics: keyStats['mnemonics'] ?? 0,
    );
  }

  /// Check if storage systems are working properly
  Future<StorageHealthCheck> checkStorageHealth() async {
    final sqliteWorking = await _testSQLiteConnection();
    final secureStorageWorking = await _secureKeys.isSecureStorageAvailable();

    return StorageHealthCheck(
      sqliteWorking: sqliteWorking,
      secureStorageWorking: secureStorageWorking,
      isHealthy: sqliteWorking && secureStorageWorking,
    );
  }

  Future<bool> _testSQLiteConnection() async {
    try {
      await _dbHelper.getDatabaseStats();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear all wallet data (use with caution!)
  Future<void> clearAllWalletData() async {
    await _dbHelper.clearAllData();
    await _secureKeys.clearAllSecureData();
  }

  /// Initialize storage (call this at app startup)
  Future<void> initializeStorage() async {
    // Ensure database is initialized
    await _dbHelper.database;

    // Set default preferences if not set
    final isDeveloperMode = await getPreference<bool>('developer_mode_enabled');
    if (isDeveloperMode == null) {
      await setDeveloperModeEnabled(false);
    }

    final defaultNetwork = await getPreference<String>('default_network');
    if (defaultNetwork == null) {
      await setDefaultNetwork('mainnet');
    }
  }
}

// ===== HELPER CLASSES =====

class WalletAccountInfo {
  final WalletAccount account;
  final bool hasPrivateKey;
  final bool hasMnemonic;
  final String? privateKey;
  final String? publicKey;

  WalletAccountInfo({
    required this.account,
    required this.hasPrivateKey,
    required this.hasMnemonic,
    this.privateKey,
    this.publicKey,
  });
}

class WalletStatistics {
  final int totalAccounts;
  final int totalTransactions;
  final int totalPreferences;
  final int storedPrivateKeys;
  final int storedPublicKeys;
  final int storedMnemonics;

  WalletStatistics({
    required this.totalAccounts,
    required this.totalTransactions,
    required this.totalPreferences,
    required this.storedPrivateKeys,
    required this.storedPublicKeys,
    required this.storedMnemonics,
  });
}

class StorageHealthCheck {
  final bool sqliteWorking;
  final bool secureStorageWorking;
  final bool isHealthy;

  StorageHealthCheck({
    required this.sqliteWorking,
    required this.secureStorageWorking,
    required this.isHealthy,
  });
}

// Extension methods for the existing models