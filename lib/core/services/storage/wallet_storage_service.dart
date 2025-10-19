// Unified wallet storage service combining SQLite and secure storage
import 'database_helper.dart';
import 'secure_keys_service.dart';
import '../../models/local_storage_models.dart';
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
    required String name,
    required String address,
    required String accountType,
    String? privateKey,
    String? publicKey,
    String? mnemonic,
    Uint8List? seed,
    Map<String, dynamic>? metadata,
  }) async {
    final now = DateTime.now();
    final account = WalletAccount(
      name: name,
      address: address,
      accountType: accountType,
      createdAt: now,
      updatedAt: now,
      metadata: metadata,
    );

    // Store account data in SQLite
    final accountId = await _dbHelper.insertAccount(account);
    final savedAccount = account.copyWith(id: accountId);

    // Store sensitive keys in secure storage
    if (privateKey != null) {
      await _secureKeys.storePrivateKey(address, privateKey);
    }
    if (publicKey != null) {
      await _secureKeys.storePublicKey(address, publicKey);
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
    required String amount,
    required String tokenType,
    required String transactionType,
    String status = 'pending',
    String? memo,
    Map<String, dynamic>? metadata,
  }) async {
    final transaction = TransactionRecord(
      txHash: txHash,
      fromAddress: fromAddress,
      toAddress: toAddress,
      amount: amount,
      tokenType: tokenType,
      transactionType: transactionType,
      timestamp: DateTime.now(),
      status: status,
      memo: memo,
      metadata: metadata,
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
    return await _dbHelper.getTransactionHistory(
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

  // ===== ADDRESS BOOK MANAGEMENT =====

  /// Add an entry to the address book
  Future<AddressBookEntry> addAddressBookEntry({
    required String name,
    required String address,
    String? notes,
    bool isFavorite = false,
  }) async {
    final now = DateTime.now();
    final entry = AddressBookEntry(
      name: name,
      address: address,
      notes: notes,
      createdAt: now,
      updatedAt: now,
      isFavorite: isFavorite,
    );

    final entryId = await _dbHelper.insertAddressBookEntry(entry);
    return entry.copyWith(id: entryId);
  }

  /// Get all address book entries
  Future<List<AddressBookEntry>> getAddressBook() async {
    return await _dbHelper.getAddressBook();
  }

  /// Get favorite addresses
  Future<List<AddressBookEntry>> getFavoriteAddresses() async {
    return await _dbHelper.getFavoriteAddresses();
  }

  /// Update an address book entry
  Future<void> updateAddressBookEntry(AddressBookEntry entry) async {
    final updatedEntry = entry.copyWith(updatedAt: DateTime.now());
    await _dbHelper.updateAddressBookEntry(updatedEntry);
  }

  /// Delete an address book entry
  Future<void> deleteAddressBookEntry(int entryId) async {
    await _dbHelper.deleteAddressBookEntry(entryId);
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
    final addressBook = await _dbHelper.getAddressBook();

    return {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'accounts': accounts.map((a) => a.toMap()).toList(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'preferences': preferences,
      'addressBook': addressBook.map((e) => e.toMap()).toList(),
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
      totalAddressBookEntries: dbStats['addressBook'] ?? 0,
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
  final int totalAddressBookEntries;
  final int storedPrivateKeys;
  final int storedPublicKeys;
  final int storedMnemonics;

  WalletStatistics({
    required this.totalAccounts,
    required this.totalTransactions,
    required this.totalPreferences,
    required this.totalAddressBookEntries,
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
extension WalletAccountExtensions on WalletAccount {
  WalletAccount copyWith({
    int? id,
    String? name,
    String? address,
    String? accountType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return WalletAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      accountType: accountType ?? this.accountType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }
}

extension AddressBookEntryExtensions on AddressBookEntry {
  AddressBookEntry copyWith({
    int? id,
    String? name,
    String? address,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
  }) {
    return AddressBookEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}