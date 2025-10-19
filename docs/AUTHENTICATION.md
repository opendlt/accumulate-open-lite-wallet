# Authentication Implementation Guide

This guide shows how to implement user authentication and identity management for your Accumulate wallet.

## Overview

The core wallet provides the blockchain functionality, but you need to implement:
1. User registration and login
2. Mnemonic phrase generation and recovery
3. Key derivation and secure storage
4. Accumulate identity creation

## Required Components

### 1. User Authentication Flow

Create authentication screens to replace the placeholder:

```dart
// lib/features/auth/presentation/login_screen.dart
class LoginScreen extends StatefulWidget {
  // Implement your login UI
}

// lib/features/auth/presentation/register_screen.dart
class RegisterScreen extends StatefulWidget {
  // Implement user registration
}

// lib/features/auth/presentation/recovery_screen.dart
class RecoveryScreen extends StatefulWidget {
  // Implement account recovery with mnemonic
}
```

### 2. Identity Service

Implement identity generation and management:

```dart
// lib/features/auth/data/identity_service.dart
class IdentityService {
  // Generate mnemonic phrase
  Future<String> generateMnemonic() async {
    // Use bip39 package to generate 12/24 word mnemonic
    return generateMnemonic();
  }

  // Derive keys from mnemonic
  Future<UserKeys> deriveKeysFromMnemonic(String mnemonic) async {
    // Implement BIP32/BIP44 key derivation
    // Return public/private keypair
  }

  // Create Accumulate identity
  Future<String> createAccumulateIdentity(UserKeys keys) async {
    // Use AccumulateApiService to create identity on chain
    // Return identity URL (acc://username.acme)
  }
}
```

### 3. Secure Storage Implementation

Implement secure key storage:

```dart
// lib/features/auth/data/secure_storage_service.dart
class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Store encrypted private key
  Future<void> storePrivateKey(String userId, String privateKey) async {
    await _storage.write(key: "privateKey_$userId", value: privateKey);
  }

  // Store user identity data
  Future<void> storeUserIdentity(UserIdentity identity) async {
    await _storage.write(key: "userId", value: identity.userId);
    await _storage.write(key: "username", value: identity.username);
    await _storage.write(key: "publicKey", value: identity.publicKey);
  }

  // Retrieve stored data
  Future<UserIdentity?> getUserIdentity() async {
    final userId = await _storage.read(key: "userId");
    if (userId == null) return null;

    // Reconstruct UserIdentity from stored data
    return UserIdentity(/* ... */);
  }
}
```

## Implementation Steps

### Step 1: Create Authentication Provider

```dart
// lib/features/auth/logic/auth_provider.dart
class AuthProvider extends ChangeNotifier {
  UserIdentity? _currentUser;
  bool _isLoading = false;

  UserIdentity? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> register(String username, String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Generate mnemonic
      final mnemonic = await _identityService.generateMnemonic();

      // 2. Derive keys
      final keys = await _identityService.deriveKeysFromMnemonic(mnemonic);

      // 3. Create Accumulate identity
      final identityUrl = await _identityService.createAccumulateIdentity(keys);

      // 4. Store securely
      final identity = UserIdentity(
        userId: identityUrl,
        username: username,
        publicKey: keys.publicKey,
        // ...
      );

      await _storageService.storeUserIdentity(identity);
      await _storageService.storePrivateKey(identity.userId, keys.privateKey);

      _currentUser = identity;
      return true;
    } catch (e) {
      // Handle errors
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login() async {
    // Check if user exists and load identity
    _currentUser = await _storageService.getUserIdentity();
    notifyListeners();
    return _currentUser != null;
  }

  Future<void> logout() async {
    _currentUser = null;
    // Optionally clear stored data
    notifyListeners();
  }
}
```

### Step 2: Update Main App

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _initializeCoreServices();

  runApp(
    MultiProvider(
      providers: [
        // Add your auth provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Existing providers
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => TransactionsProvider()),
        ChangeNotifierProvider(create: (_) => PendingTxProvider()),
      ],
      child: const AccumulateLiteWalletApp(),
    ),
  );
}

class WalletEntryPoint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoading) {
          return const LoadingScreen();
        }

        if (!auth.isAuthenticated) {
          return const LoginScreen(); // Your implementation
        }

        return const HomeScreen();
      },
    );
  }
}
```

### Step 3: Create Authentication Screens

```dart
// lib/features/auth/presentation/login_screen.dart
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    // Try auto-login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().login();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your login UI
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RegisterScreen()),
              ),
              child: Text('Create New Wallet'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RecoveryScreen()),
              ),
              child: Text('Recover Wallet'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Key Considerations

### Security Best Practices

1. **Never store private keys in plain text**
2. **Use device-specific encryption when possible**
3. **Implement biometric authentication**
4. **Validate mnemonic phrases thoroughly**
5. **Use secure random number generation**

### User Experience

1. **Clear onboarding flow**
2. **Mnemonic backup verification**
3. **Recovery testing**
4. **Biometric unlock options**
5. **Clear error messages**

### Testing

```dart
// test/auth/auth_provider_test.dart
void main() {
  group('AuthProvider', () {
    test('should register new user', () async {
      final authProvider = AuthProvider();

      final result = await authProvider.register('testuser', 'test@example.com');

      expect(result, true);
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.currentUser?.username, 'testuser');
    });
  });
}
```

## Integration with Core Services

Once authentication is implemented, integrate with existing core services:

```dart
// The core services are already set up to work with authenticated users
final serviceLocator = ServiceLocator();
final identityService = serviceLocator.identityService;

// Use authenticated user's identity
final signer = await identityService.createSigner();
final pendingTx = await serviceLocator.pendingTxService.findAllPending(/*...*/);
```

## Next Steps

1. Implement the authentication screens
2. Add mnemonic generation and recovery
3. Set up secure storage
4. Test the complete flow
5. Add biometric authentication
6. Implement backup/restore functionality

## Example Implementations

### Mnemonic Generation

```dart
import 'package:bip39/bip39.dart' as bip39;

String generateMnemonic() {
  return bip39.generateMnemonic();
}

bool validateMnemonic(String mnemonic) {
  return bip39.validateMnemonic(mnemonic);
}
```

### Key Derivation

```dart
import 'package:web3dart/crypto.dart';

Future<UserKeys> deriveKeys(String mnemonic) async {
  final seed = bip39.mnemonicToSeed(mnemonic);
  // Implement BIP32/BIP44 derivation
  // Return keypair
}
```

This authentication system will provide a secure foundation for your Accumulate wallet while integrating seamlessly with the provided core functionality.