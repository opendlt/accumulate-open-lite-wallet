import 'package:flutter/foundation.dart';
// SQLite database helper for local wallet storage
import 'package:accumulate_lite_wallet/core/models/accumulate_requests.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../models/local_storage_models.dart' hide TransactionRecord;

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
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create wallet_accounts table (enhanced for Accumulate features)
    await db.execute('''
      CREATE TABLE wallet_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL UNIQUE,
        account_type TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        parent_identity_id INTEGER,
        token_url TEXT,
        key_book_id INTEGER,
        key_page_id INTEGER,
        metadata TEXT
      )
    ''');

    // Create identities table (ADI management)
    await db.execute('''
      CREATE TABLE identities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        url TEXT NOT NULL UNIQUE,
        key_book_count INTEGER DEFAULT 1,
        account_count INTEGER DEFAULT 0,
        sponsor_address TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        metadata TEXT
      )
    ''');

    // Create key_books table
    await db.execute('''
      CREATE TABLE key_books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        identity_id INTEGER,
        name TEXT NOT NULL,
        url TEXT NOT NULL UNIQUE,
        public_key_hash TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        metadata TEXT,
        FOREIGN KEY(identity_id) REFERENCES identities(id)
      )
    ''');

    // Create key_pages table
    await db.execute('''
      CREATE TABLE key_pages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key_book_id INTEGER,
        name TEXT NOT NULL,
        url TEXT NOT NULL UNIQUE,
        keys_required INTEGER DEFAULT 1,
        keys_required_of INTEGER DEFAULT 1,
        is_active INTEGER NOT NULL DEFAULT 1,
        metadata TEXT,
        FOREIGN KEY(key_book_id) REFERENCES key_books(id)
      )
    ''');

    // Create keys table
    await db.execute('''
      CREATE TABLE keys (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key_page_id INTEGER,
        nickname TEXT NOT NULL,
        public_key TEXT NOT NULL,
        private_key_encrypted TEXT NOT NULL,
        public_key_hash TEXT,
        is_default INTEGER DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        metadata TEXT,
        FOREIGN KEY(key_page_id) REFERENCES key_pages(id)
      )
    ''');

    // Create custom_tokens table
    await db.execute('''
      CREATE TABLE custom_tokens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        symbol TEXT NOT NULL,
        url TEXT NOT NULL UNIQUE,
        precision INTEGER DEFAULT 8,
        creator_identity_id INTEGER,
        metadata TEXT,
        FOREIGN KEY(creator_identity_id) REFERENCES identities(id)
      )
    ''');

    // Create data_accounts table
    await db.execute('''
      CREATE TABLE data_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        url TEXT NOT NULL UNIQUE,
        parent_identity_id INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        metadata TEXT,
        FOREIGN KEY(parent_identity_id) REFERENCES identities(id)
      )
    ''');

    // Create transaction_records table
    await db.execute('''
      CREATE TABLE transaction_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        direction TEXT NOT NULL,
        from_url TEXT,
        to_url TEXT,
        amount INTEGER,
        token_url TEXT,
        timestamp INTEGER,
        status TEXT,
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


    // Create data_entries table
    await db.execute('''
      CREATE TABLE data_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_hash TEXT,
        data_account_url TEXT NOT NULL,
        data TEXT NOT NULL,
        timestamp INTEGER,
        transaction_id TEXT,
        is_state INTEGER DEFAULT 0,
        metadata TEXT
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
    await db.execute('CREATE INDEX idx_accounts_parent_identity ON wallet_accounts(parent_identity_id)');
    await db.execute('CREATE INDEX idx_transactions_id ON transaction_records(transaction_id)');
    await db.execute('CREATE INDEX idx_transactions_from ON transaction_records(from_url)');
    await db.execute('CREATE INDEX idx_transactions_to ON transaction_records(to_url)');
    await db.execute('CREATE INDEX idx_transactions_type ON transaction_records(type)');
    await db.execute('CREATE INDEX idx_transactions_direction ON transaction_records(direction)');
    await db.execute('CREATE INDEX idx_transactions_timestamp ON transaction_records(timestamp)');
    await db.execute('CREATE INDEX idx_preferences_key ON user_preferences(key)');
    await db.execute('CREATE INDEX idx_price_data_date ON price_data(date)');
    await db.execute('CREATE INDEX idx_account_balances_address ON account_balances(account_address)');

    // Indexes for new Accumulate tables
    await db.execute('CREATE INDEX idx_identities_name ON identities(name)');
    await db.execute('CREATE INDEX idx_identities_url ON identities(url)');
    await db.execute('CREATE INDEX idx_keybooks_identity ON key_books(identity_id)');
    await db.execute('CREATE INDEX idx_keybooks_url ON key_books(url)');
    await db.execute('CREATE INDEX idx_keypages_keybook ON key_pages(key_book_id)');
    await db.execute('CREATE INDEX idx_keypages_url ON key_pages(url)');
    await db.execute('CREATE INDEX idx_keys_keypage ON keys(key_page_id)');
    await db.execute('CREATE INDEX idx_keys_public_key_hash ON keys(public_key_hash)');
    await db.execute('CREATE INDEX idx_custom_tokens_url ON custom_tokens(url)');
    await db.execute('CREATE INDEX idx_custom_tokens_creator ON custom_tokens(creator_identity_id)');
    await db.execute('CREATE INDEX idx_data_accounts_parent ON data_accounts(parent_identity_id)');
    await db.execute('CREATE INDEX idx_data_accounts_url ON data_accounts(url)');
    await db.execute('CREATE INDEX idx_data_entries_account ON data_entries(data_account_url)');
    await db.execute('CREATE INDEX idx_data_entries_hash ON data_entries(entry_hash)');
    await db.execute('CREATE INDEX idx_data_entries_timestamp ON data_entries(timestamp)');
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

    if (oldVersion < 3) {
      // Add Accumulate features in version 3

      // Add new columns to wallet_accounts
      await db.execute('ALTER TABLE wallet_accounts ADD COLUMN parent_identity_id INTEGER');
      await db.execute('ALTER TABLE wallet_accounts ADD COLUMN token_url TEXT');
      await db.execute('ALTER TABLE wallet_accounts ADD COLUMN key_book_id INTEGER');
      await db.execute('ALTER TABLE wallet_accounts ADD COLUMN key_page_id INTEGER');

      // Create identities table
      await db.execute('''
        CREATE TABLE identities (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          url TEXT NOT NULL UNIQUE,
          key_book_count INTEGER DEFAULT 1,
          account_count INTEGER DEFAULT 0,
          sponsor_address TEXT,
          is_active INTEGER NOT NULL DEFAULT 1,
          metadata TEXT
        )
      ''');

      // Create key_books table
      await db.execute('''
        CREATE TABLE key_books (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          identity_id INTEGER,
          name TEXT NOT NULL,
          url TEXT NOT NULL UNIQUE,
          public_key_hash TEXT,
          is_active INTEGER NOT NULL DEFAULT 1,
          metadata TEXT,
          FOREIGN KEY(identity_id) REFERENCES identities(id)
        )
      ''');

      // Create key_pages table
      await db.execute('''
        CREATE TABLE key_pages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key_book_id INTEGER,
          name TEXT NOT NULL,
          url TEXT NOT NULL UNIQUE,
          keys_required INTEGER DEFAULT 1,
          keys_required_of INTEGER DEFAULT 1,
          is_active INTEGER NOT NULL DEFAULT 1,
          metadata TEXT,
          FOREIGN KEY(key_book_id) REFERENCES key_books(id)
        )
      ''');

      // Create keys table
      await db.execute('''
        CREATE TABLE keys (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key_page_id INTEGER,
          nickname TEXT NOT NULL,
          public_key TEXT NOT NULL,
          private_key_encrypted TEXT NOT NULL,
          public_key_hash TEXT,
          is_default INTEGER DEFAULT 0,
          is_active INTEGER NOT NULL DEFAULT 1,
          metadata TEXT,
          FOREIGN KEY(key_page_id) REFERENCES key_pages(id)
        )
      ''');

      // Create custom_tokens table
      await db.execute('''
        CREATE TABLE custom_tokens (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          symbol TEXT NOT NULL,
          url TEXT NOT NULL UNIQUE,
          precision INTEGER DEFAULT 8,
          creator_identity_id INTEGER,
          metadata TEXT,
          FOREIGN KEY(creator_identity_id) REFERENCES identities(id)
        )
      ''');

      // Create data_accounts table
      await db.execute('''
        CREATE TABLE data_accounts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          url TEXT NOT NULL UNIQUE,
          parent_identity_id INTEGER,
          is_active INTEGER NOT NULL DEFAULT 1,
          metadata TEXT,
          FOREIGN KEY(parent_identity_id) REFERENCES identities(id)
        )
      ''');

      // Create new indexes
      await db.execute('CREATE INDEX idx_accounts_parent_identity ON wallet_accounts(parent_identity_id)');
      await db.execute('CREATE INDEX idx_identities_name ON identities(name)');
      await db.execute('CREATE INDEX idx_identities_url ON identities(url)');
      await db.execute('CREATE INDEX idx_keybooks_identity ON key_books(identity_id)');
      await db.execute('CREATE INDEX idx_keybooks_url ON key_books(url)');
      await db.execute('CREATE INDEX idx_keypages_keybook ON key_pages(key_book_id)');
      await db.execute('CREATE INDEX idx_keypages_url ON key_pages(url)');
      await db.execute('CREATE INDEX idx_keys_keypage ON keys(key_page_id)');
      await db.execute('CREATE INDEX idx_keys_public_key_hash ON keys(public_key_hash)');
      await db.execute('CREATE INDEX idx_custom_tokens_url ON custom_tokens(url)');
      await db.execute('CREATE INDEX idx_custom_tokens_creator ON custom_tokens(creator_identity_id)');
      await db.execute('CREATE INDEX idx_data_accounts_parent ON data_accounts(parent_identity_id)');
      await db.execute('CREATE INDEX idx_data_accounts_url ON data_accounts(url)');
    }

    if (oldVersion < 4) {
      // Update transaction records schema for Send/Receive operations

      // Drop existing transaction_records table and recreate with new schema
      await db.execute('DROP TABLE IF EXISTS transaction_records');

      // Create new transaction_records table
      await db.execute('''
        CREATE TABLE transaction_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transaction_id TEXT NOT NULL UNIQUE,
          type TEXT NOT NULL,
          direction TEXT NOT NULL,
          from_url TEXT,
          to_url TEXT,
          amount INTEGER,
          token_url TEXT,
          timestamp INTEGER,
          status TEXT,
          memo TEXT,
          metadata TEXT
        )
      ''');

      // Create indexes for new transaction table
      await db.execute('CREATE INDEX idx_transactions_id ON transaction_records(transaction_id)');
      await db.execute('CREATE INDEX idx_transactions_from ON transaction_records(from_url)');
      await db.execute('CREATE INDEX idx_transactions_to ON transaction_records(to_url)');
      await db.execute('CREATE INDEX idx_transactions_type ON transaction_records(type)');
      await db.execute('CREATE INDEX idx_transactions_direction ON transaction_records(direction)');
      await db.execute('CREATE INDEX idx_transactions_timestamp ON transaction_records(timestamp)');
    }

    if (oldVersion < 5) {
      // Add data entries support for Data screen operations

      // Create data_entries table
      await db.execute('''
        CREATE TABLE data_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entry_hash TEXT,
          data_account_url TEXT NOT NULL,
          data TEXT NOT NULL,
          timestamp INTEGER,
          transaction_id TEXT,
          is_state INTEGER DEFAULT 0,
          metadata TEXT
        )
      ''');

      // Create indexes for data entries table
      await db.execute('CREATE INDEX idx_data_entries_account ON data_entries(data_account_url)');
      await db.execute('CREATE INDEX idx_data_entries_hash ON data_entries(entry_hash)');
      await db.execute('CREATE INDEX idx_data_entries_timestamp ON data_entries(timestamp)');
    }

    if (oldVersion < 6) {
      // Fix wallet_accounts table to remove created_at/updated_at constraints
      // SQLite doesn't support DROP COLUMN, so we need to recreate the table

      // Create new table without timestamp columns
      await db.execute('''
        CREATE TABLE wallet_accounts_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          address TEXT NOT NULL UNIQUE,
          account_type TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          parent_identity_id INTEGER,
          token_url TEXT,
          key_book_id INTEGER,
          key_page_id INTEGER,
          metadata TEXT
        )
      ''');

      // Copy existing data (excluding timestamp columns)
      await db.execute('''
        INSERT INTO wallet_accounts_new (id, name, address, account_type, is_active, parent_identity_id, token_url, key_book_id, key_page_id, metadata)
        SELECT id, name, address, account_type, is_active, parent_identity_id, token_url, key_book_id, key_page_id, metadata
        FROM wallet_accounts
      ''');

      // Drop old table and rename new table
      await db.execute('DROP TABLE wallet_accounts');
      await db.execute('ALTER TABLE wallet_accounts_new RENAME TO wallet_accounts');

      // Recreate indexes for wallet_accounts
      await db.execute('CREATE INDEX idx_accounts_address ON wallet_accounts(address)');
      await db.execute('CREATE INDEX idx_accounts_type ON wallet_accounts(account_type)');
      await db.execute('CREATE INDEX idx_accounts_parent_identity ON wallet_accounts(parent_identity_id)');
    }

    if (oldVersion < 7) {
      // Fix custom_tokens table to remove any created_at/updated_at constraints
      // that might exist from older database versions

      // Create new custom_tokens table with correct schema
      await db.execute('''
        CREATE TABLE custom_tokens_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          symbol TEXT NOT NULL,
          url TEXT NOT NULL UNIQUE,
          precision INTEGER DEFAULT 8,
          creator_identity_id INTEGER,
          metadata TEXT,
          FOREIGN KEY(creator_identity_id) REFERENCES identities(id)
        )
      ''');

      // Copy existing data (excluding any timestamp columns)
      await db.execute('''
        INSERT INTO custom_tokens_new (id, name, symbol, url, precision, creator_identity_id, metadata)
        SELECT id, name, symbol, url, precision, creator_identity_id, metadata
        FROM custom_tokens
        WHERE 1=1
      ''');

      // Drop old table and rename new table
      await db.execute('DROP TABLE custom_tokens');
      await db.execute('ALTER TABLE custom_tokens_new RENAME TO custom_tokens');

      // Recreate indexes for custom_tokens
      await db.execute('CREATE INDEX idx_custom_tokens_url ON custom_tokens(url)');
      await db.execute('CREATE INDEX idx_custom_tokens_creator ON custom_tokens(creator_identity_id)');
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
      orderBy: 'id DESC',
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
      orderBy: 'id DESC',
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
      {'is_active': 0},
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
      query += ' WHERE from_url = ? OR to_url = ?';
      whereArgs = [address, address];
    }

    query += ' ORDER BY timestamp DESC LIMIT ? OFFSET ?';
    whereArgs.addAll([limit, offset]);

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, whereArgs);
    return List.generate(maps.length, (i) => TransactionRecord.fromMap(maps[i]));
  }

  Future<TransactionRecord?> getTransactionById(String transactionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaction_records',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return TransactionRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTransactionStatus(String transactionId, String status) async {
    final db = await database;
    return await db.update(
      'transaction_records',
      {'status': status},
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
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


  // ===== UTILITY METHODS =====

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('wallet_accounts');
      await txn.delete('transaction_records');
      await txn.delete('user_preferences');
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

  /// Get the latest ACME price for USD calculations
  Future<double> getLatestAcmePrice() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'price_data',
      where: 'token_symbol = ?',
      whereArgs: ['ACME'],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final priceData = PriceData.fromMap(maps.first);
      return priceData.price;
    }

    // Fallback to a default price if no data
    return 0.25; // Default ACME price
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
      // Update existing - exclude ID field to avoid datatype mismatch
      final updateMap = {
        'account_address': accountBalance.accountAddress,
        'account_name': accountBalance.accountName,
        'acme_balance': accountBalance.acmeBalance,
        'account_type': accountBalance.accountType,
        'updated_at': accountBalance.updatedAt.millisecondsSinceEpoch,
      };

      return await db.update(
        'account_balances',
        updateMap,
        where: 'account_address = ?',
        whereArgs: [accountBalance.accountAddress],
      );
    } else {
      // Insert new - exclude ID field since it's auto-increment
      final insertMap = {
        'account_address': accountBalance.accountAddress,
        'account_name': accountBalance.accountName,
        'acme_balance': accountBalance.acmeBalance,
        'account_type': accountBalance.accountType,
        'updated_at': accountBalance.updatedAt.millisecondsSinceEpoch,
      };

      return await db.insert('account_balances', insertMap);
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
    final priceData = await db.rawQuery('SELECT COUNT(*) as count FROM price_data');
    final accountBalances = await db.rawQuery('SELECT COUNT(*) as count FROM account_balances');

    return {
      'accounts': accounts.first['count'] as int,
      'transactions': transactions.first['count'] as int,
      'preferences': preferences.first['count'] as int,
      'priceData': priceData.first['count'] as int,
      'accountBalances': accountBalances.first['count'] as int,
    };
  }

  // ===== ACCUMULATE ENTITIES METHODS =====

  /// Insert identity
  Future<int> insertIdentity(AccumulateIdentity identity) async {
    final db = await database;
    return await db.insert('identities', identity.toMap());
  }

  /// Get all identities
  Future<List<AccumulateIdentity>> getAllIdentities() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'identities',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) => AccumulateIdentity.fromMap(maps[i]));
  }

  /// Insert key book
  Future<int> insertKeyBook(AccumulateKeyBook keyBook) async {
    final db = await database;
    return await db.insert('key_books', keyBook.toMap());
  }

  /// Get key books by identity
  Future<List<AccumulateKeyBook>> getKeyBooksByIdentity(int identityId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'key_books',
      where: 'identity_id = ? AND is_active = ?',
      whereArgs: [identityId, 1],
      orderBy: 'id ASC',
    );
    return List.generate(maps.length, (i) => AccumulateKeyBook.fromMap(maps[i]));
  }

  /// Insert key page
  Future<int> insertKeyPage(AccumulateKeyPage keyPage) async {
    final db = await database;
    return await db.insert('key_pages', keyPage.toMap());
  }

  /// Get key pages by key book
  Future<List<AccumulateKeyPage>> getKeyPagesByKeyBook(int keyBookId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'key_pages',
      where: 'key_book_id = ? AND is_active = ?',
      whereArgs: [keyBookId, 1],
      orderBy: 'id ASC',
    );
    return List.generate(maps.length, (i) => AccumulateKeyPage.fromMap(maps[i]));
  }

  /// Insert key
  Future<int> insertKey(AccumulateKey key) async {
    final db = await database;
    return await db.insert('keys', key.toMap());
  }

  /// Get keys by key page
  Future<List<AccumulateKey>> getKeysByKeyPage(int keyPageId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'keys',
      where: 'key_page_id = ? AND is_active = ?',
      whereArgs: [keyPageId, 1],
      orderBy: 'is_default DESC, id ASC',
    );
    return List.generate(maps.length, (i) => AccumulateKey.fromMap(maps[i]));
  }

  /// Insert custom token
  Future<int> insertCustomToken(AccumulateCustomToken token) async {
    final db = await database;
    return await db.insert('custom_tokens', token.toMap());
  }

  /// Get all custom tokens
  Future<List<AccumulateCustomToken>> getAllCustomTokens() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'custom_tokens',
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) => AccumulateCustomToken.fromMap(maps[i]));
  }

  /// Insert data account
  Future<int> insertDataAccount(AccumulateDataAccount dataAccount) async {
    final db = await database;
    return await db.insert('data_accounts', dataAccount.toMap());
  }

  /// Get all data accounts
  Future<List<AccumulateDataAccount>> getAllDataAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'data_accounts',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) => AccumulateDataAccount.fromMap(maps[i]));
  }

  // ===== DATA ENTRIES METHODS =====

  /// Insert data entry
  Future<int> insertDataEntry(DataEntry dataEntry) async {
    final db = await database;
    return await db.insert('data_entries', dataEntry.toMap());
  }

  /// Get data entries by data account URL
  Future<List<DataEntry>> getDataEntriesByAccount({
    required String dataAccountUrl,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'data_entries',
      where: 'data_account_url = ?',
      whereArgs: [dataAccountUrl],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => DataEntry.fromMap(map)).toList();
  }

  /// Get data entry by hash
  Future<DataEntry?> getDataEntryByHash(String entryHash) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'data_entries',
      where: 'entry_hash = ?',
      whereArgs: [entryHash],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return DataEntry.fromMap(maps.first);
    }
    return null;
  }

  /// Get recent data entries across all accounts
  Future<List<DataEntry>> getRecentDataEntries({
    int limit = 20,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'data_entries',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((map) => DataEntry.fromMap(map)).toList();
  }

  /// Count data entries for an account
  Future<int> getDataEntryCount(String dataAccountUrl) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM data_entries WHERE data_account_url = ?',
      [dataAccountUrl],
    );
    return result.first['count'] as int;
  }

  /// Search data entries by content
  Future<List<DataEntry>> searchDataEntries({
    String? query,
    String? dataAccountUrl,
    int limit = 50,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (query != null && query.isNotEmpty) {
      whereClause = 'data LIKE ?';
      whereArgs.add('%$query%');
    }

    if (dataAccountUrl != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += 'data_account_url = ?';
      whereArgs.add(dataAccountUrl);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'data_entries',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((map) => DataEntry.fromMap(map)).toList();
  }

  /// Delete data entries for an account (soft delete by removing from local cache)
  Future<int> deleteDataEntriesForAccount(String dataAccountUrl) async {
    final db = await database;
    return await db.delete(
      'data_entries',
      where: 'data_account_url = ?',
      whereArgs: [dataAccountUrl],
    );
  }

  /// Get data statistics
  Future<Map<String, int>> getDataStats() async {
    final db = await database;

    final totalEntries = await db.rawQuery(
      'SELECT COUNT(*) as count FROM data_entries',
    );

    final stateEntries = await db.rawQuery(
      'SELECT COUNT(*) as count FROM data_entries WHERE is_state = 1',
    );

    final scratchEntries = await db.rawQuery(
      'SELECT COUNT(*) as count FROM data_entries WHERE is_state = 0',
    );

    final uniqueAccounts = await db.rawQuery(
      'SELECT COUNT(DISTINCT data_account_url) as count FROM data_entries',
    );

    return {
      'totalEntries': totalEntries.first['count'] as int,
      'stateEntries': stateEntries.first['count'] as int,
      'scratchEntries': scratchEntries.first['count'] as int,
      'uniqueAccounts': uniqueAccounts.first['count'] as int,
    };
  }
}