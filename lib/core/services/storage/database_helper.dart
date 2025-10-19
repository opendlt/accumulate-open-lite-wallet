// SQLite database helper for local wallet storage
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../models/local_storage_models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, 'accumulate_wallet.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create wallet_accounts table
    await db.execute('''
      CREATE TABLE wallet_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL UNIQUE,
        account_type TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        metadata TEXT
      )
    ''');

    // Create transaction_records table
    await db.execute('''
      CREATE TABLE transaction_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tx_hash TEXT NOT NULL UNIQUE,
        from_address TEXT NOT NULL,
        to_address TEXT NOT NULL,
        amount TEXT NOT NULL,
        token_type TEXT NOT NULL,
        transaction_type TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        memo TEXT,
        metadata TEXT
      )
    ''');

    // Create user_preferences table
    await db.execute('''
      CREATE TABLE user_preferences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        value TEXT NOT NULL,
        value_type TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create address_book table
    await db.execute('''
      CREATE TABLE address_book (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create price_data table for line chart
    await db.execute('''
      CREATE TABLE price_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL,
        price REAL NOT NULL,
        token_symbol TEXT NOT NULL DEFAULT 'ACME'
      )
    ''');

    // Create account_balances table for pie chart
    await db.execute('''
      CREATE TABLE account_balances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_address TEXT NOT NULL,
        account_name TEXT NOT NULL,
        acme_balance REAL NOT NULL DEFAULT 0.0,
        account_type TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_accounts_address ON wallet_accounts(address)');
    await db.execute('CREATE INDEX idx_accounts_type ON wallet_accounts(account_type)');
    await db.execute('CREATE INDEX idx_transactions_hash ON transaction_records(tx_hash)');
    await db.execute('CREATE INDEX idx_transactions_from ON transaction_records(from_address)');
    await db.execute('CREATE INDEX idx_transactions_to ON transaction_records(to_address)');
    await db.execute('CREATE INDEX idx_transactions_timestamp ON transaction_records(timestamp)');
    await db.execute('CREATE INDEX idx_preferences_key ON user_preferences(key)');
    await db.execute('CREATE INDEX idx_addressbook_address ON address_book(address)');
    await db.execute('CREATE INDEX idx_price_data_date ON price_data(date)');
    await db.execute('CREATE INDEX idx_account_balances_address ON account_balances(account_address)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades here
    if (oldVersion < 2) {
      // Add chart data tables in version 2
      await db.execute('''
        CREATE TABLE price_data (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date INTEGER NOT NULL,
          price REAL NOT NULL,
          token_symbol TEXT NOT NULL DEFAULT 'ACME'
        )
      ''');

      await db.execute('''
        CREATE TABLE account_balances (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          account_address TEXT NOT NULL,
          account_name TEXT NOT NULL,
          acme_balance REAL NOT NULL DEFAULT 0.0,
          account_type TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      await db.execute('CREATE INDEX idx_price_data_date ON price_data(date)');
      await db.execute('CREATE INDEX idx_account_balances_address ON account_balances(account_address)');
    }
  }

  // ===== WALLET ACCOUNTS METHODS =====

  Future<int> insertAccount(WalletAccount account) async {
    final db = await database;
    return await db.insert('wallet_accounts', account.toMap());
  }

  Future<List<WalletAccount>> getAllAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'wallet_accounts',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => WalletAccount.fromMap(maps[i]));
  }

  Future<WalletAccount?> getAccountByAddress(String address) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'wallet_accounts',
      where: 'address = ? AND is_active = ?',
      whereArgs: [address, 1],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return WalletAccount.fromMap(maps.first);
    }
    return null;
  }

  Future<List<WalletAccount>> getAccountsByType(String accountType) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'wallet_accounts',
      where: 'account_type = ? AND is_active = ?',
      whereArgs: [accountType, 1],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => WalletAccount.fromMap(maps[i]));
  }

  Future<int> updateAccount(WalletAccount account) async {
    final db = await database;
    return await db.update(
      'wallet_accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(int accountId) async {
    final db = await database;
    return await db.update(
      'wallet_accounts',
      {'is_active': 0, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  // ===== TRANSACTION RECORDS METHODS =====

  Future<int> insertTransaction(TransactionRecord transaction) async {
    final db = await database;
    return await db.insert('transaction_records', transaction.toMap());
  }

  Future<List<TransactionRecord>> getTransactionHistory({
    String? address,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    String query = 'SELECT * FROM transaction_records';
    List<dynamic> whereArgs = [];

    if (address != null) {
      query += ' WHERE from_address = ? OR to_address = ?';
      whereArgs = [address, address];
    }

    query += ' ORDER BY timestamp DESC LIMIT ? OFFSET ?';
    whereArgs.addAll([limit, offset]);

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, whereArgs);
    return List.generate(maps.length, (i) => TransactionRecord.fromMap(maps[i]));
  }

  Future<TransactionRecord?> getTransactionByHash(String txHash) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaction_records',
      where: 'tx_hash = ?',
      whereArgs: [txHash],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return TransactionRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTransactionStatus(String txHash, String status) async {
    final db = await database;
    return await db.update(
      'transaction_records',
      {'status': status},
      where: 'tx_hash = ?',
      whereArgs: [txHash],
    );
  }

  // ===== USER PREFERENCES METHODS =====

  Future<int> setPreference(String key, dynamic value) async {
    final db = await database;
    String valueType;
    String valueString;

    if (value is bool) {
      valueType = 'bool';
      valueString = value.toString();
    } else if (value is int) {
      valueType = 'int';
      valueString = value.toString();
    } else if (value is double) {
      valueType = 'double';
      valueString = value.toString();
    } else {
      valueType = 'string';
      valueString = value.toString();
    }

    final preference = UserPreferences(
      key: key,
      value: valueString,
      valueType: valueType,
      updatedAt: DateTime.now(),
    );

    return await db.insert(
      'user_preferences',
      preference.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<T?> getPreference<T>(String key, {T? defaultValue}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_preferences',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (maps.isEmpty) return defaultValue;

    final preference = UserPreferences.fromMap(maps.first);

    switch (T) {
      case bool:
        return preference.boolValue as T;
      case int:
        return preference.intValue as T;
      case double:
        return preference.doubleValue as T;
      case String:
        return preference.stringValue as T;
      default:
        return preference.stringValue as T;
    }
  }

  Future<Map<String, dynamic>> getAllPreferences() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('user_preferences');

    Map<String, dynamic> preferences = {};
    for (var map in maps) {
      final preference = UserPreferences.fromMap(map);
      switch (preference.valueType) {
        case 'bool':
          preferences[preference.key] = preference.boolValue;
          break;
        case 'int':
          preferences[preference.key] = preference.intValue;
          break;
        case 'double':
          preferences[preference.key] = preference.doubleValue;
          break;
        default:
          preferences[preference.key] = preference.stringValue;
      }
    }
    return preferences;
  }

  // ===== ADDRESS BOOK METHODS =====

  Future<int> insertAddressBookEntry(AddressBookEntry entry) async {
    final db = await database;
    return await db.insert('address_book', entry.toMap());
  }

  Future<List<AddressBookEntry>> getAddressBook() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'address_book',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => AddressBookEntry.fromMap(maps[i]));
  }

  Future<List<AddressBookEntry>> getFavoriteAddresses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'address_book',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => AddressBookEntry.fromMap(maps[i]));
  }

  Future<int> updateAddressBookEntry(AddressBookEntry entry) async {
    final db = await database;
    return await db.update(
      'address_book',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteAddressBookEntry(int entryId) async {
    final db = await database;
    return await db.delete(
      'address_book',
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  // ===== UTILITY METHODS =====

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('wallet_accounts');
      await txn.delete('transaction_records');
      await txn.delete('user_preferences');
      await txn.delete('address_book');
      await txn.delete('price_data');
      await txn.delete('account_balances');
    });
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // ===== CHART DATA METHODS =====

  /// Insert price data for line chart
  Future<int> insertPriceData(PriceData priceData) async {
    final db = await database;
    return await db.insert('price_data', priceData.toMap());
  }

  /// Get price data for line chart (last 30 days by default)
  Future<List<PriceData>> getPriceData({int days = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final List<Map<String, dynamic>> maps = await db.query(
      'price_data',
      where: 'date >= ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
      orderBy: 'date ASC',
    );
    return List.generate(maps.length, (i) => PriceData.fromMap(maps[i]));
  }

  /// Insert or update account balance for pie chart
  Future<int> insertOrUpdateAccountBalance(AccountBalance accountBalance) async {
    final db = await database;

    // Check if account balance exists
    final existing = await db.query(
      'account_balances',
      where: 'account_address = ?',
      whereArgs: [accountBalance.accountAddress],
    );

    if (existing.isNotEmpty) {
      // Update existing
      return await db.update(
        'account_balances',
        accountBalance.toMap(),
        where: 'account_address = ?',
        whereArgs: [accountBalance.accountAddress],
      );
    } else {
      // Insert new
      return await db.insert('account_balances', accountBalance.toMap());
    }
  }

  /// Get all account balances for pie chart
  Future<List<AccountBalance>> getAccountBalances() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'account_balances',
      orderBy: 'acme_balance DESC',
    );
    return List.generate(maps.length, (i) => AccountBalance.fromMap(maps[i]));
  }

  /// Generate dummy price data for testing
  Future<void> generateDummyPriceData() async {
    final db = await database;

    // Clear existing price data
    await db.delete('price_data');

    // Generate 30 days of dummy price data
    final now = DateTime.now();
    double basePrice = 0.25; // Starting price for ACME

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));

      // Generate random price movement (-5% to +5%)
      final change = (DateTime.now().millisecond % 100 - 50) / 1000;
      basePrice = basePrice * (1 + change);
      basePrice = double.parse(basePrice.toStringAsFixed(4)); // Keep 4 decimal places

      final priceData = PriceData(
        date: date,
        price: basePrice,
        tokenSymbol: 'ACME',
      );

      await insertPriceData(priceData);
    }
  }

  /// Generate dummy account balance data for testing
  Future<void> generateDummyAccountBalances() async {
    final db = await database;

    // Clear existing account balances
    await db.delete('account_balances');

    // Generate dummy account balances
    final dummyAccounts = [
      AccountBalance(
        accountAddress: 'acc://demo.acme/lite-account-1',
        accountName: 'Main Lite Account',
        acmeBalance: 1250.75,
        accountType: 'lite_account',
        updatedAt: DateTime.now(),
      ),
      AccountBalance(
        accountAddress: 'acc://demo.acme/token-account-1',
        accountName: 'Trading Account',
        acmeBalance: 825.50,
        accountType: 'token_account',
        updatedAt: DateTime.now(),
      ),
      AccountBalance(
        accountAddress: 'acc://demo.acme/token-account-2',
        accountName: 'Savings Account',
        acmeBalance: 3450.25,
        accountType: 'token_account',
        updatedAt: DateTime.now(),
      ),
    ];

    for (final account in dummyAccounts) {
      await insertOrUpdateAccountBalance(account);
    }
  }

  // Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;

    final accounts = await db.rawQuery('SELECT COUNT(*) as count FROM wallet_accounts WHERE is_active = 1');
    final transactions = await db.rawQuery('SELECT COUNT(*) as count FROM transaction_records');
    final preferences = await db.rawQuery('SELECT COUNT(*) as count FROM user_preferences');
    final addressBook = await db.rawQuery('SELECT COUNT(*) as count FROM address_book');
    final priceData = await db.rawQuery('SELECT COUNT(*) as count FROM price_data');
    final accountBalances = await db.rawQuery('SELECT COUNT(*) as count FROM account_balances');

    return {
      'accounts': accounts.first['count'] as int,
      'transactions': transactions.first['count'] as int,
      'preferences': preferences.first['count'] as int,
      'addressBook': addressBook.first['count'] as int,
      'priceData': priceData.first['count'] as int,
      'accountBalances': accountBalances.first['count'] as int,
    };
  }
}