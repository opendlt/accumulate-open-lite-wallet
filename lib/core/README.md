# Core Architecture - Ready to Use ✅

This directory contains the pure business logic of the wallet, completely separated from Flutter framework dependencies. **All components in this directory are ready to use without modification.**

## Directory Structure

```
core/
├── adapters/           # Flutter-specific implementations of core interfaces
├── constants/          # Application constants and enums
├── di/                # Dependency injection setup
├── examples/          # Usage examples and integration helpers
├── models/            # Pure data models
├── repositories/      # Data access layer abstractions
├── services/          # Business logic services
│   ├── auth/         # Authentication business logic
│   ├── blockchain/   # Accumulate blockchain interactions
│   ├── identity/     # Identity management
│   ├── networking/   # HTTP networking
│   ├── pending_tx/   # Pending transaction logic
│   └── storage/      # Storage interfaces
└── utils/             # Pure utility functions
```

## Key Design Principles

### 1. **Zero Flutter Dependencies**
All core code is pure Dart with no Flutter imports. This enables:
- Unit testing without Flutter test environment
- Potential code sharing with server/CLI applications
- Better separation of concerns

### 2. **Interface-Based Design**
Core services depend on abstractions (interfaces) rather than concrete implementations:
- `SecureStorageInterface` - abstracted from Flutter's secure storage
- `NetworkService` - generic HTTP client wrapper
- Adapter pattern bridges core interfaces with Flutter implementations

### 3. **Dependency Injection**
The `ServiceLocator` manages all service dependencies:
- Clean initialization in main.dart
- Easy mocking for tests
- Loose coupling between components

## Models

### UserIdentity
Represents user identity and cryptographic keys:
```dart
final identity = UserIdentity(
  userId: 'user123',
  username: 'testuser',
  publicKey: 'abcd...',
  publicKeyHash: 'hash...',
  email: 'testuser@accu2.io',
);
```

### PendingTransaction
Represents blockchain transactions awaiting signatures:
```dart
final tx = PendingTransaction(
  txId: 'tx123',
  hash: 'hash456',
  type: 'sendTokens',
);
```

### AccountBalance
Represents token account balances:
```dart
final balance = AccountBalance(
  accountUrl: 'acc://user.acme/tokens',
  balance: 100.0,
  tokenType: 'ACME',
  lastUpdated: DateTime.now(),
);
```

## Services

### CoreIdentityService
Manages user identity and cryptographic operations:
```dart
final identity = await identityService.generateIdentity(
  'user123', 'testuser', 'testuser@accu2.io'
);
final signer = await identityService.createSigner();
```

### CorePendingTxService
Handles pending transaction discovery and management:
```dart
final response = await pendingTxService.findAllPendingNeedingSignatureForUser(
  signingPaths: ['acc://user.acme/book/1'],
  baseAdi: 'acc://user.acme',
  userSignerUrl: 'acc://user.acme/book/1',
);
```

### AccumulateApiService
Low-level Accumulate blockchain API interactions:
```dart
final balance = await apiService.getAccountBalance('acc://user.acme/tokens');
final result = await apiService.submitTransaction(txData);
```

## Integration with Existing Code

### Phase 1: Parallel Development
The core architecture runs alongside existing code without modifications:

```dart
// Initialize once in main.dart
void main() {
  // ... existing Flutter setup

  // Initialize core services
  final serviceLocator = ServiceLocator();
  final storageAdapter = FlutterSecureStorageAdapter(FlutterSecureStorage());
  serviceLocator.initializeCoreServices(storageAdapter);

  runApp(MyApp());
}

// Use in existing widgets
class ExistingWidget extends StatelessWidget {
  Future<void> checkPending() async {
    final serviceLocator = ServiceLocator();
    final hasPending = await serviceLocator.pendingTxService
        .hasPendingTransactions(['acc://user.acme/book/1']);
    // ... handle result
  }
}
```

### Phase 2: Gradual Migration
Existing services can be gradually replaced:

1. Keep existing widget code unchanged
2. Replace service calls with core service equivalents
3. Test each replacement thoroughly
4. Remove old code only after validation

## Testing Benefits

Core services are easily unit testable:

```dart
class MockStorage implements SecureStorageInterface {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;
  // ... other methods
}

void main() {
  test('identity service generates valid identity', () async {
    final mockStorage = MockStorage();
    final identityService = CoreIdentityService(mockStorage);

    final identity = await identityService.generateIdentity(
      'test', 'testuser', 'test@accu2.io'
    );

    expect(identity.username, 'testuser');
    expect(identity.publicKey.length, 64); // 32 bytes = 64 hex chars
  });
}
```

## What's Included ✅

### Models
- `UserIdentity` - User identity and cryptographic keys
- `PendingTransaction` - Blockchain transactions awaiting signatures
- `AccountBalance` - Token account balances

### Services
- `AccumulateApiService` - Low-level blockchain API interactions
- `CoreIdentityService` - Identity and cryptographic operations
- `CorePendingTxService` - Pending transaction discovery
- `NetworkService` - HTTP client abstraction

### Adapters
- `FlutterSecureStorageAdapter` - Secure storage interface implementation

### Utilities
- Pure Dart utility functions
- Constants and enums
- Dependency injection setup

## Extension Points

While this core is complete, you may want to extend it with:

1. **Additional Storage Adapters** - For different storage backends
2. **Custom Network Services** - For specialized HTTP handling
3. **Enhanced Identity Services** - For advanced key management
4. **Additional Models** - For app-specific data structures

## Security Notes

- All cryptographic operations are handled securely
- Private keys are managed through the secure storage adapter
- Network communications use HTTPS by default
- Input validation is performed at service boundaries

This core provides a solid, production-ready foundation for your Accumulate wallet.