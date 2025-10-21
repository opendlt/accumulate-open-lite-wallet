# API Reference

This document provides comprehensive reference documentation for all core services, models, and APIs in the Accumulate Open Lite Wallet.

## Table of Contents

- [Service Locator](#service-locator)
- [Core Services](#core-services)
  - [Key Management Service](#key-management-service)
  - [Identity Management Service](#identity-management-service)
  - [Token Management Service](#token-management-service)
  - [Transaction Service](#transaction-service)
  - [Data Service](#data-service)
  - [Balance Aggregation Service](#balance-aggregation-service)
  - [Enhanced Accumulate Service](#enhanced-accumulate-service)
- [Storage Services](#storage-services)
- [Data Models](#data-models)
- [Constants & Configuration](#constants--configuration)

## Service Locator

### ServiceLocator

**Purpose**: Centralized dependency injection for all business logic services.

**Location**: `lib/core/services/service_locator.dart`

#### Usage

```dart
// Initialize services (call once at app startup)
await serviceLocator.initialize();

// Access services throughout the app
final keyService = serviceLocator.keyManagementService;
final identityService = serviceLocator.identityManagementService;
```

#### Methods

```dart
class ServiceLocator {
  /// Initialize all services - call once at app startup
  Future<void> initialize() async

  /// Clean up resources - call on app shutdown
  Future<void> dispose() async

  /// Reset all services - useful for logout
  Future<void> reset() async

  // Service Getters
  DatabaseHelper get databaseHelper
  NetworkService get networkService
  KeyManagementService get keyManagementService
  IdentityManagementService get identityManagementService
  TokenManagementService get tokenManagementService
  TransactionService get transactionService
  DataService get dataService
  PurchaseCreditsService get purchaseCreditsService
  FaucetService get faucetService
  AccumulateApiService get accumulateApiService
  EnhancedAccumulateService get enhancedAccumulateService
}
```

---

## Core Services

### Key Management Service

**Purpose**: Cryptographic key generation, storage, and management for all account types.

**Location**: `lib/core/services/crypto/key_management_service.dart`

#### Key Features
- Ed25519 key pair generation
- Secure key storage and encryption
- Lite account and ADI key management
- Multi-signature support

#### Methods

```dart
class KeyManagementService {
  /// Generate a new Ed25519 key pair
  Future<KeyPairData> generateKeyPair() async

  /// Create a lite identity signer from an address
  Future<LiteIdentity?> createLiteIdentitySigner(String address) async

  /// Create an ADI signer from a key page URL
  Future<TxSigner?> createADISigner(String keyPageUrl) async

  /// Store a lite account private key
  Future<void> storeLiteAccountKey(String address, String privateKeyHex) async

  /// Store a private key securely
  Future<void> storePrivateKey(String keyId, String privateKeyHex) async

  /// Encrypt a private key with passphrase
  Future<String> encryptPrivateKey(String privateKeyHex, String passphrase) async

  /// Generate a mnemonic seed phrase
  Future<String> generateMnemonic() async

  /// Import a key from mnemonic
  Future<KeyPairData> importFromMnemonic(String mnemonic) async

  /// Validate private key format
  bool isValidPrivateKey(String privateKeyHex)

  /// Set master passphrase for encryption
  Future<void> setMasterPassphrase(String passphrase) async

  /// Check if master passphrase is set
  Future<bool> hasMasterPassphrase() async

  /// Clear all stored keys (for logout/reset)
  Future<void> clearAllKeys() async

  /// Get private key bytes for a given address
  Future<Uint8List?> getPrivateKeyBytes(String address) async

  /// Get public key bytes for a given address
  Future<Uint8List?> getPublicKeyBytes(String address) async

  /// Debug method to check what keys exist for an account
  Future<Map<String, bool>> debugAccountKeys(String accountAddress) async
}
```

#### Data Models

```dart
class KeyPairData {
  final String publicKey;      // Hex-encoded public key
  final String privateKey;     // Hex-encoded private key
  final String publicKeyHash;  // Hex-encoded public key hash
}
```

### Identity Management Service

**Purpose**: ADI (Accumulate Digital Identity) creation and management.

**Location**: `lib/core/services/identity/identity_management_service.dart`

#### Key Features
- ADI identity creation
- Key book and key page management
- Multi-signature configuration
- Identity hierarchy management

#### Methods

```dart
class IdentityManagementService {
  /// Create a new ADI identity
  Future<IdentityCreationResult> createIdentity({
    required String identityName,
    required String keyBookName,
    required String keyPageName,
    required String publicKey,
    String? sponsorIdentity,
  }) async

  /// Get all managed identities
  Future<List<AccumulateIdentity>> getAllIdentities() async

  /// Get identity by URL
  Future<AccumulateIdentity?> getIdentityByUrl(String identityUrl) async

  /// Create additional key book for identity
  Future<KeyBookCreationResult> createKeyBook({
    required String identityUrl,
    required String keyBookName,
    required String signerKeyPageUrl,
  }) async

  /// Create key page in key book
  Future<KeyPageCreationResult> createKeyPage({
    required String keyBookUrl,
    required String keyPageName,
    required String publicKey,
    required String signerKeyPageUrl,
  }) async

  /// Get key books for identity
  Future<List<AccumulateKeyBook>> getKeyBooksForIdentity(int identityId) async

  /// Get key pages for key book
  Future<List<AccumulateKeyPage>> getKeyPagesForKeyBook(int keyBookId) async

  /// Update identity metadata
  Future<void> updateIdentityMetadata({
    required String identityUrl,
    Map<String, dynamic>? metadata,
  }) async
}
```

#### Results Models

```dart
class IdentityCreationResult {
  final bool success;
  final String? identityUrl;
  final String? keyBookUrl;
  final String? keyPageUrl;
  final String? transactionHash;
  final String? error;
}

class KeyBookCreationResult {
  final bool success;
  final String? keyBookUrl;
  final String? transactionHash;
  final String? error;
}

class KeyPageCreationResult {
  final bool success;
  final String? keyPageUrl;
  final String? transactionHash;
  final String? error;
}
```

### Token Management Service

**Purpose**: Token account creation and management for both lite and ADI accounts.

**Location**: `lib/core/services/token/token_management_service.dart`

#### Key Features
- Lite token account creation
- ADI token account creation
- Account metadata management
- Token transfer preparation

#### Methods

```dart
class TokenManagementService {
  /// Create a new lite token account
  Future<LiteAccountCreationResult> createLiteAccount({
    String? customKeyId,
  }) async

  /// Create ADI token account
  Future<TokenAccountCreationResult> createADITokenAccount({
    required String identityUrl,
    required String accountName,
    required String tokenUrl,
    required String signerKeyPageUrl,
    String? managerId,
  }) async

  /// Get account balance
  Future<double> getAccountBalance(String accountUrl) async

  /// Prepare token transfer transaction
  Future<TransferPreparation> prepareTokenTransfer({
    required String fromAccount,
    required String toAccount,
    required double amount,
    String? memo,
  }) async

  /// Get all managed token accounts
  Future<List<AccumulateAccount>> getAllTokenAccounts() async

  /// Get lite accounts
  Future<List<AccumulateAccount>> getLiteAccounts() async

  /// Get ADI token accounts
  Future<List<AccumulateAccount>> getADITokenAccounts() async

  /// Import existing account by URL
  Future<ImportAccountResult> importAccount(String accountUrl) async
}
```

### Transaction Service

**Purpose**: Comprehensive transaction building, signing, and submission.

**Location**: `lib/core/services/transaction/transaction_service.dart`

#### Key Features
- Multi-signature transaction support
- Various transaction types (send tokens, create accounts, etc.)
- Transaction status tracking
- Fee calculation and management

#### Methods

```dart
class TransactionService {
  /// Send tokens between accounts
  Future<TransactionResult> sendTokens({
    required String fromAccount,
    required String toAccount,
    required double amount,
    String? memo,
    String? signerKeyPageUrl,
  }) async

  /// Create data account
  Future<TransactionResult> createDataAccount({
    required String identityUrl,
    required String accountName,
    required String signerKeyPageUrl,
    String? managerId,
  }) async

  /// Write data to account
  Future<TransactionResult> writeData({
    required String dataAccountUrl,
    required Uint8List data,
    required String signerKeyPageUrl,
    String? contentType,
  }) async

  /// Purchase credits for account
  Future<TransactionResult> purchaseCredits({
    required String recipientUrl,
    required String payerAccountUrl,
    required double acmeAmount,
    required String signerKeyPageUrl,
  }) async

  /// Get transaction history for account
  Future<List<TransactionRecord>> getTransactionHistory(String accountUrl) async

  /// Get transaction status
  Future<TransactionStatus> getTransactionStatus(String transactionHash) async

  /// Get pending transactions requiring signature
  Future<List<PendingTransaction>> getPendingTransactions() async

  /// Sign pending transaction
  Future<SignatureResult> signTransaction({
    required String transactionHash,
    required String signerKeyPageUrl,
  }) async
}
```

### Data Service

**Purpose**: Accumulate data account management and data operations.

**Location**: `lib/core/services/data/data_service.dart`

#### Key Features
- Data account creation
- Data writing and retrieval
- Data validation and encoding
- Entry history management

#### Methods

```dart
class DataService {
  /// Create new data account
  Future<DataAccountCreationResult> createDataAccount({
    required String identityUrl,
    required String accountName,
    required String signerKeyPageUrl,
    String? managerId,
  }) async

  /// Write data to account
  Future<DataWriteResult> writeData({
    required String dataAccountUrl,
    required Uint8List data,
    required String signerKeyPageUrl,
    String? contentType,
    String? description,
  }) async

  /// Read data from account
  Future<DataReadResult> readData({
    required String dataAccountUrl,
    int? entryIndex,
  }) async

  /// Get all data entries for account
  Future<List<DataEntry>> getDataEntries(String dataAccountUrl) async

  /// Get data account information
  Future<DataAccountInfo> getDataAccountInfo(String dataAccountUrl) async

  /// Get managed data accounts
  Future<List<AccumulateAccount>> getDataAccounts() async

  /// Validate data before writing
  bool validateData(Uint8List data, {int? maxSize})

  /// Estimate data write cost
  Future<CostEstimate> estimateDataWriteCost({
    required String dataAccountUrl,
    required Uint8List data,
  }) async
}
```

### Balance Aggregation Service

**Purpose**: Real-time balance queries and aggregation across all accounts.

**Location**: `lib/core/services/balance/balance_aggregation_service.dart`

#### Key Features
- Multi-account balance aggregation
- Real-time RPC queries
- Rate limiting and caching
- USD value calculation

#### Methods

```dart
class BalanceAggregationService {
  /// Get total wallet balance across all accounts
  Future<BalanceAggregationResult> getTotalWalletBalance() async

  /// Get cached wallet balance (fast)
  Future<BalanceAggregationResult> getCachedWalletBalance() async

  /// Refresh balances in background
  Future<void> refreshBalancesInBackground() async

  /// Get balance summary for UI display
  Future<WalletBalanceSummary> getBalanceSummary() async
}
```

#### Data Models

```dart
class BalanceAggregationResult {
  final double totalBalance;
  final List<AccountBalanceData> accountBalances;
  final List<String> errors;
  final DateTime lastUpdated;
}

class WalletBalanceSummary {
  final double totalBalance;
  final double totalUsdValue;
  final double latestAcmePrice;
  final int accountCount;
  final List<AccountBalancePercentage> accountBalances;
  final DateTime lastUpdated;
  final bool hasErrors;
}

class AccountBalanceData {
  final String accountAddress;
  final String accountName;
  final double acmeBalance;
  final String accountType;
  final DateTime updatedAt;
}
```

### Enhanced Accumulate Service

**Purpose**: High-level Accumulate blockchain operations and API abstraction.

**Location**: `lib/core/services/blockchain/enhanced_accumulate_service.dart`

#### Key Features
- Blockchain query operations
- Transaction submission
- Network status monitoring
- Error handling and retry logic

#### Methods

```dart
class EnhancedAccumulateService {
  /// Query account information
  Future<AccountQueryResult> queryAccount(String accountUrl) async

  /// Submit transaction to network
  Future<SubmissionResult> submitTransaction(Transaction transaction) async

  /// Query transaction status
  Future<TransactionStatusResult> queryTransaction(String transactionHash) async

  /// Get network status
  Future<NetworkStatus> getNetworkStatus() async

  /// Query directory for account discovery
  Future<DirectoryResult> queryDirectory({
    required String directoryUrl,
    int? start,
    int? count,
  }) async

  /// Get account metrics
  Future<AccountMetrics> getAccountMetrics(String accountUrl) async

  /// Estimate transaction fees
  Future<FeeEstimate> estimateTransactionFee(Transaction transaction) async

  /// Validate account URL format
  bool isValidAccountUrl(String url)

  /// Parse account URL components
  AccountUrlComponents parseAccountUrl(String url)
}
```

---

## Storage Services

### Database Helper

**Purpose**: SQLite database operations and schema management.

**Location**: `lib/core/services/storage/database_helper.dart`

#### Key Features
- SQLite schema management
- Account and transaction persistence
- Balance caching
- Price data storage

#### Methods

```dart
class DatabaseHelper {
  /// Get database instance
  Future<Database> get database async

  /// Insert or update account
  Future<int> insertOrUpdateAccount(AccumulateAccount account) async

  /// Get all accounts
  Future<List<AccumulateAccount>> getAllAccounts() async

  /// Get accounts by type
  Future<List<AccumulateAccount>> getAccountsByType(String accountType) async

  /// Insert transaction record
  Future<int> insertTransactionRecord(TransactionRecord transaction) async

  /// Get transaction history
  Future<List<TransactionRecord>> getTransactionHistory({
    String? accountAddress,
    int? limit,
  }) async

  /// Insert or update account balance
  Future<int> insertOrUpdateAccountBalance(AccountBalance accountBalance) async

  /// Get account balances
  Future<List<AccountBalance>> getAccountBalances() async

  /// Insert price data
  Future<int> insertPriceData(PriceData priceData) async

  /// Get price data
  Future<List<PriceData>> getPriceData({int days = 30}) async

  /// Get latest ACME price
  Future<double> getLatestAcmePrice() async

  /// Clear all data (for reset)
  Future<void> clearAllData() async

  /// Close database connection
  Future<void> close() async
}
```

### Secure Keys Service

**Purpose**: Encrypted key storage using platform secure storage.

**Location**: `lib/core/services/storage/secure_keys_service.dart`

#### Methods

```dart
class SecureKeysService {
  /// Store private key securely
  Future<void> storePrivateKey(String address, String privateKeyHex) async

  /// Retrieve private key
  Future<String?> getPrivateKey(String address) async

  /// Check if private key exists
  Future<bool> hasPrivateKey(String address) async

  /// Store derived key
  Future<void> storeDerivatedKey(String keyId, String keyName, String value) async

  /// Get derived key
  Future<String?> getDerivedKey(String keyId, String keyName) async

  /// Clear all secure data
  Future<void> clearAllSecureData() async

  /// Delete specific key
  Future<void> deleteKey(String address) async
}
```

---

## Data Models

### Core Account Models

#### AccumulateAccount

**Location**: `lib/core/models/local_storage_models.dart`

```dart
class AccumulateAccount {
  final int? id;
  final String address;
  final String name;
  final String accountType;      // 'lite_account', 'token_account', 'identity', etc.
  final String? parentIdentity;  // For ADI accounts
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
}
```

#### AccumulateIdentity

```dart
class AccumulateIdentity {
  final int? id;
  final String url;
  final String name;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
}
```

#### TransactionRecord

```dart
class TransactionRecord {
  final int? id;
  final String transactionHash;
  final String transactionType;
  final String? fromAccount;
  final String? toAccount;
  final double? amount;
  final String? memo;
  final String status;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final DateTime createdAt;
}
```

### Blockchain Models

#### KeyPairData

```dart
class KeyPairData {
  final String publicKey;
  final String privateKey;
  final String publicKeyHash;
}
```

#### TransactionResult

```dart
class TransactionResult {
  final bool success;
  final String? transactionHash;
  final String? error;
  final Map<String, dynamic>? metadata;
}
```

---

## Constants & Configuration

### AppConstants

**Location**: `lib/core/constants/app_constants.dart`

```dart
class AppConstants {
  // Network URLs
  static const String defaultAccumulateDevnetUrl = 'http://10.0.2.2:26660/v2';

  // Faucet addresses
  static const String devnetFaucetAddress = 'acc://a21555da824d14f3f066214657a44e6a1a347dad3052a23a/ACME';
  static const String testnetFaucetAddress = 'acc://faucet.testnet/ACME';

  // Polling intervals
  static const Duration defaultPendingTxPollingInterval = Duration(seconds: 45);
  static const Duration badgeRefreshInterval = Duration(minutes: 30);

  // Token types
  static const String acmeTokenType = 'ACME';

  // Account types
  static const String defaultBookPath = '/book/1';

  // Storage keys
  static const String userIdKey = 'userId';
  static const String addTxMemosKey = 'add_tx_memos';

  /// Format lite account address for display
  static String formatLiteAccountAddress(String address);
}
```

### TransactionTypes

```dart
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
```

---

## Error Handling

### Standard Error Types

All services follow consistent error handling patterns:

```dart
// Result wrapper for operations that can fail
class Result<T> {
  final T? data;
  final String? error;
  final bool success;

  Result.success(this.data) : error = null, success = true;
  Result.error(this.error) : data = null, success = false;
}

// Common error types
class WalletException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  WalletException(this.message, {this.code, this.details});
}
```

### Error Categories

- **NetworkException**: Blockchain API communication errors
- **CryptographicException**: Key generation or signing errors
- **ValidationException**: Input validation failures
- **StorageException**: Database or secure storage errors
- **TransactionException**: Transaction building or submission errors

---

## Usage Examples

### Complete Wallet Operation

```dart
// Initialize services
await serviceLocator.initialize();

// Create lite account
final tokenService = serviceLocator.tokenManagementService;
final result = await tokenService.createLiteAccount();

if (result.success) {
  print('Created account: ${result.accountUrl}');

  // Send tokens
  final transactionService = serviceLocator.transactionService;
  final sendResult = await transactionService.sendTokens(
    fromAccount: result.accountUrl!,
    toAccount: 'acc://recipient-address/ACME',
    amount: 10.0,
    memo: 'Test transfer',
  );

  if (sendResult.success) {
    print('Transaction submitted: ${sendResult.transactionHash}');
  }
}
```

### Multi-Signature Workflow

```dart
// Create ADI identity first
final identityService = serviceLocator.identityManagementService;
final identityResult = await identityService.createIdentity(
  identityName: 'my-identity',
  keyBookName: 'main-book',
  keyPageName: 'main-page',
  publicKey: await keyService.generateKeyPair().then((kp) => kp.publicKey),
);

// Sign a transaction requiring multiple signatures
final signingService = TransactionSigningService();
final signResult = await signingService.signTransaction(
  transactionHash: 'abc123...',
  signerKeyPageUrl: 'acc://my-identity.acme/book/main-book/main-page',
);
```

---

This API reference provides comprehensive documentation for all core functionality. For implementation examples and integration patterns, see the [Integration Guide](INTEGRATION.md).