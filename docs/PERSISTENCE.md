# Data Persistence Extension Guide

This guide shows how to extend the existing data persistence in your Accumulate wallet. The core wallet already includes SQLite database and Flutter Secure Storage.

## Current Implementation

The wallet already includes persistent storage for:
- User accounts and wallet data (SQLite + DatabaseHelper)
- Transaction history and records (SQLite database)
- Secure key storage (Flutter Secure Storage)
- Application preferences (SQLite database)
- Identity and account management (SQLite database)

## Current Database Schema

The app uses SQLite with the following tables:

### Core Tables
- `wallet_accounts` - Account information and metadata
- `identities` - Accumulate Digital Identifiers (ADIs)
- `key_books` - Key management hierarchy
- `key_pages` - Key page definitions
- `keys` - Cryptographic keys (encrypted)
- `custom_tokens` - Custom token definitions
- `data_accounts` - Data account storage
- `transaction_records` - Transaction history
- `data_entries` - Data entries for accounts
- `price_data` - Price information for charts
- `account_balances` - Balance tracking
- `user_preferences` - Application settings

### Secure Storage
- Private keys (Flutter Secure Storage)
- Mnemonics and seeds (Flutter Secure Storage)
- Authentication tokens (Flutter Secure Storage)

## Extension Options

You can extend the existing storage with:
- Cloud backup integration
- Remote database synchronization
- Additional custom data models
- Enhanced encryption layers
- Cross-device data sync
- Export/import functionality

## Current Implementation Details

### SQLite Database (Already Implemented)

**Already included:** Transaction history, complex queries, offline functionality

```yaml
# Already in pubspec.yaml:
dependencies:
  sqflite: ^2.4.1
  path: ^1.9.0
  flutter_secure_storage: ^9.2.2
```

#### Implementation

```dart
// lib/data/database/app_database.dart
class AppDatabase {
  static Database? _database;
  static const String dbName = 'accumulate_wallet.db';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        hash TEXT NOT NULL,
        type TEXT NOT NULL,
        from_account TEXT NOT NULL,
        to_account TEXT,
        amount INTEGER,
        timestamp INTEGER NOT NULL,
        status TEXT NOT NULL,
        memo TEXT,
        raw_data TEXT
      )
    ''');

    // Account balances table
    await db.execute('''
      CREATE TABLE account_balances (
        account_url TEXT PRIMARY KEY,
        balance INTEGER NOT NULL,
        token_type TEXT NOT NULL,
        last_updated INTEGER NOT NULL
      )
    ''');

    // User settings table
    await db.execute('''
      CREATE TABLE user_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }
}
```

#### Data Access Objects (DAOs)

```dart
// lib/data/dao/transaction_dao.dart
class TransactionDao {
  static Future<Database> get _db async => await AppDatabase.database;

  static Future<void> insertTransaction(Transaction transaction) async {
    final db = await _db;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Transaction>> getTransactionsByAccount(String accountUrl) async {
    final db = await _db;
    final maps = await db.query(
      'transactions',
      where: 'from_account = ? OR to_account = ?',
      whereArgs: [accountUrl, accountUrl],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  static Future<List<Transaction>> getRecentTransactions({int limit = 50}) async {
    final db = await _db;
    final maps = await db.query(
      'transactions',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => Transaction.fromMap(map)).toList();
  }
}

// lib/data/dao/balance_dao.dart
class BalanceDao {
  static Future<Database> get _db async => await AppDatabase.database;

  static Future<void> updateBalance(AccountBalance balance) async {
    final db = await _db;
    await db.insert(
      'account_balances',
      balance.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<AccountBalance?> getBalance(String accountUrl) async {
    final db = await _db;
    final maps = await db.query(
      'account_balances',
      where: 'account_url = ?',
      whereArgs: [accountUrl],
    );

    if (maps.isEmpty) return null;
    return AccountBalance.fromMap(maps.first);
  }
}
```

### Option 2: Hive (Lightweight, Fast)

**Best for:** Simple data, fast access, smaller apps

```yaml
# pubspec.yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0
```

#### Implementation

```dart
// lib/data/hive/hive_setup.dart
class HiveSetup {
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(AccountBalanceAdapter());

    // Open boxes
    await Hive.openBox<Transaction>('transactions');
    await Hive.openBox<AccountBalance>('balances');
    await Hive.openBox<String>('settings');
  }
}

// lib/data/hive/transaction_service.dart
class HiveTransactionService {
  static Box<Transaction> get _box => Hive.box<Transaction>('transactions');

  static Future<void> saveTransaction(Transaction transaction) async {
    await _box.put(transaction.id, transaction);
  }

  static List<Transaction> getTransactionsByAccount(String accountUrl) {
    return _box.values
        .where((tx) => tx.fromAccount == accountUrl || tx.toAccount == accountUrl)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static List<Transaction> getRecentTransactions({int limit = 50}) {
    final transactions = _box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return transactions.take(limit).toList();
  }
}
```

### Option 3: Shared Preferences (Simple Settings)

**Best for:** User preferences, simple key-value data

```yaml
# pubspec.yaml
dependencies:
  shared_preferences: ^2.3.2
```

#### Implementation

```dart
// lib/data/preferences/user_preferences.dart
class UserPreferences {
  static const String keyThemeMode = 'theme_mode';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyDefaultNetwork = 'default_network';

  static Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  // Theme settings
  static Future<void> setThemeMode(String mode) async {
    final prefs = await _prefs;
    await prefs.setString(keyThemeMode, mode);
  }

  static Future<String> getThemeMode() async {
    final prefs = await _prefs;
    return prefs.getString(keyThemeMode) ?? 'system';
  }

  // Network settings
  static Future<void> setDefaultNetwork(String network) async {
    final prefs = await _prefs;
    await prefs.setString(keyDefaultNetwork, network);
  }

  static Future<String> getDefaultNetwork() async {
    final prefs = await _prefs;
    return prefs.getString(keyDefaultNetwork) ?? 'mainnet';
  }
}
```

## Integration with Core Services

### Update Providers to Use Persistence

```dart
// lib/features/dashboard/logic/dashboard_provider.dart
class DashboardProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  Map<String, AccountBalance> _balances = {};
  bool _isLoading = false;

  // Getters...

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load from local storage first (fast)
      await _loadFromCache();

      // Then fetch fresh data from network
      await _fetchFreshData();
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromCache() async {
    // SQLite example
    _transactions = await TransactionDao.getRecentTransactions();

    // Or Hive example
    // _transactions = HiveTransactionService.getRecentTransactions();

    notifyListeners();
  }

  Future<void> _fetchFreshData() async {
    final serviceLocator = ServiceLocator();
    final apiService = serviceLocator.accumulateApiService;

    // Fetch fresh data from blockchain
    final freshBalance = await apiService.getAccountBalance(userAccountUrl);

    // Update cache
    await BalanceDao.updateBalance(freshBalance);
    // Or: await HiveBalanceService.saveBalance(freshBalance);

    _balances[userAccountUrl] = freshBalance;
    notifyListeners();
  }
}
```

### Cache Management

```dart
// lib/data/cache/cache_manager.dart
class CacheManager {
  static const Duration cacheExpiry = Duration(minutes: 5);

  static Future<bool> isCacheValid(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('cache_${key}_timestamp');

    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime) < cacheExpiry;
  }

  static Future<void> setCacheTimestamp(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cache_${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> clearCache() async {
    // Clear all cached data
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('cache_'));

    for (final key in keys) {
      await prefs.remove(key);
    }

    // Clear database tables if using SQLite
    final db = await AppDatabase.database;
    await db.delete('transactions');
    await db.delete('account_balances');
  }
}
```

## Data Models

Update your models to support serialization:

```dart
// lib/core/models/transaction.dart
class Transaction {
  final String id;
  final String hash;
  final String type;
  final String fromAccount;
  final String? toAccount;
  final int? amount;
  final DateTime timestamp;
  final String status;
  final String? memo;

  Transaction({
    required this.id,
    required this.hash,
    required this.type,
    required this.fromAccount,
    this.toAccount,
    this.amount,
    required this.timestamp,
    required this.status,
    this.memo,
  });

  // SQLite serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hash': hash,
      'type': type,
      'from_account': fromAccount,
      'to_account': toAccount,
      'amount': amount,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status,
      'memo': memo,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      hash: map['hash'],
      type: map['type'],
      fromAccount: map['from_account'],
      toAccount: map['to_account'],
      amount: map['amount'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      status: map['status'],
      memo: map['memo'],
    );
  }

  // Hive serialization (requires type adapter)
  factory Transaction.fromJson(Map<String, dynamic> json) => fromMap(json);
  Map<String, dynamic> toJson() => toMap();
}
```

## Offline Support

```dart
// lib/data/offline/offline_manager.dart
class OfflineManager {
  static Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static Future<void> syncWhenOnline() async {
    if (await isOnline()) {
      // Sync pending transactions
      await _syncPendingTransactions();

      // Update balances
      await _updateBalances();

      // Clear old cache
      await _cleanupOldData();
    }
  }

  static Future<void> _syncPendingTransactions() async {
    // Implementation depends on your chosen storage
  }
}
```

## Testing Your Persistence Layer

```dart
// test/data/transaction_dao_test.dart
void main() {
  group('TransactionDao', () {
    setUpAll(() async {
      await AppDatabase._initDatabase();
    });

    test('should insert and retrieve transaction', () async {
      final transaction = Transaction(
        id: 'test_123',
        hash: 'hash_456',
        type: 'sendTokens',
        fromAccount: 'acc://test.acme/tokens',
        timestamp: DateTime.now(),
        status: 'delivered',
      );

      await TransactionDao.insertTransaction(transaction);

      final retrieved = await TransactionDao.getTransactionsByAccount('acc://test.acme/tokens');

      expect(retrieved.length, 1);
      expect(retrieved.first.id, 'test_123');
    });
  });
}
```

## Recommendations

### For Most Wallets: SQLite + SharedPreferences
- SQLite for transaction history and complex data
- SharedPreferences for user settings
- Good balance of features and performance

### For Simple Wallets: Hive
- Fast and lightweight
- Good for simple data structures
- Easy to implement

### For Enterprise: Custom Backend
- Remote database with local caching
- Synchronization across devices
- Advanced backup and recovery

## Next Steps

1. Choose your storage solution based on needs
2. Implement the data access layer
3. Update providers to use persistence
4. Add offline support
5. Implement data synchronization
6. Add backup/restore functionality

The persistence layer you choose will determine how much offline functionality and data history your wallet can provide to users.