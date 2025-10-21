import 'package:flutter/foundation.dart';
// Example of how to use the new core architecture
// This demonstrates the clean separation and testability of the core layer

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../di/service_locator.dart';
import '../adapters/flutter_secure_storage_adapter.dart';
import '../models/user_identity.dart';

class CoreUsageExample {
  static void demonstrateUsage() async {
    // Initialize the core services with Flutter adapter
    // This would typically be done once in main.dart
    _initializeCoreServices();

    // Now all business logic can be accessed through clean interfaces
    await _demonstrateIdentityManagement();
    await _demonstratePendingTransactions();
    await _demonstrateUserRepository();
  }

  static void _initializeCoreServices() {
    final serviceLocator = ServiceLocator();

    // Create Flutter-specific adapter
    const flutterStorage = FlutterSecureStorage();
    final storageAdapter = FlutterSecureStorageAdapter(flutterStorage);

    // Initialize all core services
    serviceLocator.initializeCoreServices(storageAdapter);
  }

  static Future<void> _demonstrateIdentityManagement() async {
    final serviceLocator = ServiceLocator();
    final identityService = serviceLocator.identityService;

    // Generate new identity
    final identity = await identityService.generateIdentity(
      'user123',
      'testuser',
      'testuser@accu2.io',
    );

    debugPrint('Generated identity: ${identity.username}');

    // Retrieve stored identity
    final storedIdentity = await identityService.getStoredIdentity();
    debugPrint('Retrieved identity: ${storedIdentity?.username}');

    // Create signer for transactions
    final signer = await identityService.createSigner();
    debugPrint('Signer available: ${signer != null}');

    // Validate integrity
    final isValid = await identityService.validateStoredIdentity();
    debugPrint('Identity valid: $isValid');
  }

  static Future<void> _demonstratePendingTransactions() async {
    final serviceLocator = ServiceLocator();
    final pendingTxService = serviceLocator.pendingTxService;

    // Check pending transactions for user paths
    final signingPaths = [
      'acc://testuser.acme/book/1',
      'acc://testuser.acme/book/2',
    ];

    final response =
        await pendingTxService.findAllPendingNeedingSignatureForUser(
      signingPaths: signingPaths,
      baseAdi: 'acc://testuser.acme',
      userSignerUrl: 'acc://testuser.acme/book/1',
    );

    debugPrint('Total pending transactions: ${response.count}');
    debugPrint('Paths with pending: ${response.bySigningPath.length}');

    // Flatten for UI display
    final flatList = pendingTxService.flatten(response);
    debugPrint('Flat list size: ${flatList.length}');

    // Check if user has any pending
    final hasPending =
        await pendingTxService.hasPendingTransactions(signingPaths);
    debugPrint('Has pending transactions: $hasPending');
  }

  static Future<void> _demonstrateUserRepository() async {
    final serviceLocator = ServiceLocator();
    final userRepo = serviceLocator.userRepository;

    // Save user data
    final user = UserIdentity(
      userId: 'user123',
      username: 'testuser',
      publicKey: 'abcd1234...',
      publicKeyHash: 'hash1234...',
      email: 'testuser@accu2.io',
    );

    await userRepo.saveUser(user);
    debugPrint('User saved');

    // Load user data
    final loadedUser = await userRepo.loadUser();
    debugPrint('Loaded user: ${loadedUser?.username}');

    // Check if user exists
    final hasUser = await userRepo.hasUser();
    debugPrint('User exists: $hasUser');

    // Manage settings
    await userRepo.saveUserSettings({'addTxMemosEnabled': true});
    final settings = await userRepo.getUserSettings();
    debugPrint('Settings: $settings');
  }
}

/// This is how you would integrate the core services in existing widgets
/// without changing the existing code structure
class CoreIntegrationHelper {
  static Future<bool> checkPendingTransactionsForUser(String username) async {
    final serviceLocator = ServiceLocator();
    final pendingTxService = serviceLocator.pendingTxService;

    final signingPaths = ['acc://$username.acme/book/1'];
    return await pendingTxService.hasPendingTransactions(signingPaths);
  }

  static Future<UserIdentity?> getCurrentUser() async {
    final serviceLocator = ServiceLocator();
    final userRepo = serviceLocator.userRepository;

    return await userRepo.loadUser();
  }

  static Future<void> saveUserSettings(Map<String, dynamic> settings) async {
    final serviceLocator = ServiceLocator();
    final userRepo = serviceLocator.userRepository;

    await userRepo.saveUserSettings(settings);
  }
}
