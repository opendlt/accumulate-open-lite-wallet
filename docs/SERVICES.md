# Services Implementation Guide

This guide shows how to extend the core wallet with additional services and background functionality that were excluded from the open-source version.

## Overview

The core wallet includes essential services for blockchain interaction, but you may want to add:
- Background transaction polling
- Push notifications
- Cloud synchronization
- Automated backups
- Multi-device support
- Analytics and crash reporting

## Included Services

### Core Services (Ready to Use)

```dart
// These services are included and functional:
TokenSenderService          // Send tokens with multi-sig support
SignatureCountService       // Query transaction signature status
```

### Core Architecture Services

```dart
// From lib/core/services/ - Ready to use:
AccumulateApiService        // Blockchain API integration
CoreIdentityService         // Identity and key management
CorePendingTxService        // Pending transaction discovery
NetworkService              // HTTP client abstraction
```

## Services You Need to Implement

### 1. Background Transaction Polling

Monitor blockchain for incoming transactions and signature requests.

```dart
// lib/services/background_polling_service.dart
class BackgroundPollingService {
  static const Duration _pollInterval = Duration(minutes: 5);
  Timer? _pollTimer;
  final CorePendingTxService _pendingTxService;

  BackgroundPollingService(this._pendingTxService);

  void startPolling() {
    stopPolling(); // Ensure no duplicate timers

    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      await _pollForUpdates();
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollForUpdates() async {
    try {
      // Get user's signing paths
      final signingPaths = await _getUserSigningPaths();

      // Check for pending transactions
      final response = await _pendingTxService.findAllPendingNeedingSignatureForUser(
        signingPaths: signingPaths,
        baseAdi: 'acc://user.acme', // Replace with actual user ADI
        userSignerUrl: 'acc://user.acme/book/1', // Replace with actual signer
      );

      if (response['pendingTransactions'].isNotEmpty) {
        await _handlePendingTransactions(response['pendingTransactions']);
      }

      // Check for new incoming transactions
      await _checkForIncomingTransactions();

    } catch (e) {
      debugPrint('Polling error: $e');
    }
  }

  Future<List<String>> _getUserSigningPaths() async {
    // Implement: Get user's signing paths from storage
    // This should return paths like ['acc://user.acme/book/1']
    return [];
  }

  Future<void> _handlePendingTransactions(List<dynamic> pendingTx) async {
    // Update UI state
    final pendingProvider = Provider.of<PendingTxProvider>(context, listen: false);
    pendingProvider.updatePendingTransactions(pendingTx);

    // Show notifications if appropriate
    await _showPendingTransactionNotification(pendingTx.length);
  }

  Future<void> _checkForIncomingTransactions() async {
    // Implementation: Check for new transactions to user's accounts
    // Compare with last known transaction history
  }
}
```

### 2. Push Notification Service

Handle push notifications for transaction updates.

```dart
// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  static Future<void> showPendingTransactionNotification(int count) async {
    const androidDetails = AndroidNotificationDetails(
      'pending_transactions',
      'Pending Transactions',
      channelDescription: 'Notifications for pending transactions requiring signatures',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      'Pending Signatures',
      'You have $count transaction${count != 1 ? 's' : ''} waiting for your signature',
      details,
    );
  }

  static Future<void> showTransactionReceived(String amount, String token) async {
    await _notifications.show(
      1,
      'Transaction Received',
      'You received $amount $token',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'incoming_transactions',
          'Incoming Transactions',
          channelDescription: 'Notifications for incoming transactions',
        ),
      ),
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to appropriate screen
    switch (response.id) {
      case 0: // Pending transactions
        // Navigate to pending transactions screen
        break;
      case 1: // Incoming transaction
        // Navigate to transaction history
        break;
    }
  }
}
```

### 3. Cloud Synchronization Service

Sync wallet data across devices (optional).

```dart
// lib/services/cloud_sync_service.dart
abstract class CloudSyncService {
  Future<void> uploadWalletData(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> downloadWalletData(String userId);
  Future<void> deleteWalletData(String userId);
}

// Example Firebase implementation
class FirebaseCloudSyncService implements CloudSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> uploadWalletData(Map<String, dynamic> data) async {
    final userId = data['userId'] as String;

    // Encrypt sensitive data before upload
    final encryptedData = await _encryptData(data);

    await _firestore
        .collection('wallet_backups')
        .doc(userId)
        .set(encryptedData);
  }

  @override
  Future<Map<String, dynamic>?> downloadWalletData(String userId) async {
    final doc = await _firestore
        .collection('wallet_backups')
        .doc(userId)
        .get();

    if (!doc.exists) return null;

    // Decrypt data after download
    return await _decryptData(doc.data()!);
  }

  @override
  Future<void> deleteWalletData(String userId) async {
    await _firestore
        .collection('wallet_backups')
        .doc(userId)
        .delete();
  }

  Future<Map<String, dynamic>> _encryptData(Map<String, dynamic> data) async {
    // Implement encryption - NEVER store private keys unencrypted
    // Consider using device-specific encryption keys
    return data; // Placeholder
  }

  Future<Map<String, dynamic>> _decryptData(Map<String, dynamic> data) async {
    // Implement decryption
    return data; // Placeholder
  }
}
```

### 4. Analytics Service

Track app usage and performance (optional).

```dart
// lib/services/analytics_service.dart
abstract class AnalyticsService {
  Future<void> initialize();
  Future<void> trackEvent(String name, Map<String, dynamic> parameters);
  Future<void> setUserProperty(String name, String value);
  Future<void> recordError(dynamic error, StackTrace stackTrace);
}

class AppAnalyticsService implements AnalyticsService {
  @override
  Future<void> initialize() async {
    // Initialize your analytics service (Firebase Analytics, Mixpanel, etc.)
  }

  @override
  Future<void> trackEvent(String name, Map<String, dynamic> parameters) async {
    // Track user events for product insights
    debugPrint('Analytics: $name - $parameters');
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    // Set user properties for segmentation
  }

  @override
  Future<void> recordError(dynamic error, StackTrace stackTrace) async {
    // Record errors for debugging
    debugPrint('Error recorded: $error\n$stackTrace');
  }
}

// Usage throughout the app
class AnalyticsHelper {
  static final AnalyticsService _service = AppAnalyticsService();

  static Future<void> trackTransactionSent(String amount, String token) async {
    await _service.trackEvent('transaction_sent', {
      'amount': amount,
      'token': token,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> trackSignatureCompleted(String txType) async {
    await _service.trackEvent('signature_completed', {
      'transaction_type': txType,
    });
  }
}
```

### 5. Backup and Recovery Service

Automated wallet backups with user consent.

```dart
// lib/services/backup_service.dart
class BackupService {
  final CloudSyncService _cloudSync;
  final SecureStorageService _storage;

  BackupService(this._cloudSync, this._storage);

  Future<BackupResult> createBackup(String userId) async {
    try {
      // Gather wallet data (excluding private keys)
      final backupData = await _gatherBackupData(userId);

      // Upload to cloud storage
      await _cloudSync.uploadWalletData(backupData);

      // Record backup timestamp
      await _storage.setBackupTimestamp(DateTime.now());

      return BackupResult.success('Backup created successfully');
    } catch (e) {
      return BackupResult.error('Backup failed: $e');
    }
  }

  Future<BackupResult> restoreFromBackup(String userId) async {
    try {
      // Download backup data
      final backupData = await _cloudSync.downloadWalletData(userId);

      if (backupData == null) {
        return BackupResult.error('No backup found for this user');
      }

      // Restore wallet data
      await _restoreWalletData(backupData);

      return BackupResult.success('Wallet restored successfully');
    } catch (e) {
      return BackupResult.error('Restore failed: $e');
    }
  }

  Future<Map<String, dynamic>> _gatherBackupData(String userId) async {
    return {
      'userId': userId,
      'settings': await _storage.getUserSettings(),
      'addressBook': await _storage.getAddressBook(),
      'transactionHistory': await _storage.getTransactionHistory(),
      'customNetworks': await _storage.getCustomNetworks(),
      'timestamp': DateTime.now().toIso8601String(),
      // NEVER include private keys in backup
    };
  }

  Future<void> _restoreWalletData(Map<String, dynamic> data) async {
    // Restore settings
    await _storage.setUserSettings(data['settings']);

    // Restore address book
    await _storage.setAddressBook(data['addressBook']);

    // Restore transaction history cache
    await _storage.setTransactionHistory(data['transactionHistory']);
  }
}

class BackupResult {
  final bool success;
  final String message;

  BackupResult.success(this.message) : success = true;
  BackupResult.error(this.message) : success = false;
}
```

### 6. Network Health Monitor

Monitor blockchain network status and connectivity.

```dart
// lib/services/network_health_service.dart
class NetworkHealthService {
  static const Duration _checkInterval = Duration(minutes: 2);
  Timer? _healthTimer;

  NetworkHealthStatus _status = NetworkHealthStatus.unknown;
  final List<VoidCallback> _listeners = [];

  NetworkHealthStatus get status => _status;

  void startMonitoring() {
    stopMonitoring();

    _healthTimer = Timer.periodic(_checkInterval, (_) async {
      await _checkNetworkHealth();
    });

    // Initial check
    _checkNetworkHealth();
  }

  void stopMonitoring() {
    _healthTimer?.cancel();
    _healthTimer = null;
  }

  void addListener(VoidCallback callback) {
    _listeners.add(callback);
  }

  void removeListener(VoidCallback callback) {
    _listeners.remove(callback);
  }

  Future<void> _checkNetworkHealth() async {
    try {
      final client = AppConfig.acmeClient;

      // Simple health check - query a known endpoint
      final startTime = DateTime.now();
      await client.queryUrl(AccURL('acc://ACME'));
      final responseTime = DateTime.now().difference(startTime);

      // Determine health based on response time
      if (responseTime.inMilliseconds < 1000) {
        _updateStatus(NetworkHealthStatus.excellent);
      } else if (responseTime.inMilliseconds < 3000) {
        _updateStatus(NetworkHealthStatus.good);
      } else {
        _updateStatus(NetworkHealthStatus.slow);
      }

    } catch (e) {
      _updateStatus(NetworkHealthStatus.offline);
    }
  }

  void _updateStatus(NetworkHealthStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;

      // Notify listeners
      for (final listener in _listeners) {
        listener();
      }
    }
  }
}

enum NetworkHealthStatus {
  unknown,
  excellent,
  good,
  slow,
  offline,
}
```

## Service Integration

### 1. Service Locator Pattern

Integrate new services with the existing service locator:

```dart
// lib/core/di/service_locator.dart - Extension
extension ServiceLocatorExtensions on ServiceLocator {
  void initializeAdditionalServices() {
    // Background services
    registerSingleton<BackgroundPollingService>(
      BackgroundPollingService(pendingTxService),
    );

    // Notification service
    registerSingleton<NotificationService>(
      NotificationService(),
    );

    // Cloud sync (if implemented)
    registerSingleton<CloudSyncService>(
      FirebaseCloudSyncService(),
    );

    // Analytics (if implemented)
    registerSingleton<AnalyticsService>(
      AppAnalyticsService(),
    );

    // Network health
    registerSingleton<NetworkHealthService>(
      NetworkHealthService(),
    );
  }
}
```

### 2. Lifecycle Management

Manage services through the app lifecycle:

```dart
// lib/services/service_manager.dart
class ServiceManager {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialize notification service
    await NotificationService.initialize();

    // Initialize analytics
    await ServiceLocator().get<AnalyticsService>().initialize();

    // Start background services
    ServiceLocator().get<BackgroundPollingService>().startPolling();
    ServiceLocator().get<NetworkHealthService>().startMonitoring();

    _initialized = true;
  }

  static void dispose() {
    if (!_initialized) return;

    // Stop background services
    ServiceLocator().get<BackgroundPollingService>().stopPolling();
    ServiceLocator().get<NetworkHealthService>().stopMonitoring();

    _initialized = false;
  }

  static void pauseServices() {
    // Pause services when app goes to background
    ServiceLocator().get<BackgroundPollingService>().stopPolling();
  }

  static void resumeServices() {
    // Resume services when app comes to foreground
    ServiceLocator().get<BackgroundPollingService>().startPolling();
  }
}
```

### 3. Update Main App

```dart
// lib/main.dart - Updated
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services
  _initializeCoreServices();

  // Initialize additional services
  ServiceLocator().initializeAdditionalServices();
  await ServiceManager.initialize();

  runApp(MyApp());
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ServiceManager.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        ServiceManager.resumeServices();
        break;
      case AppLifecycleState.paused:
        ServiceManager.pauseServices();
        break;
      default:
        break;
    }
  }
}
```

## Testing Services

```dart
// test/services/background_polling_service_test.dart
void main() {
  group('BackgroundPollingService', () {
    late BackgroundPollingService service;
    late MockPendingTxService mockPendingTxService;

    setUp(() {
      mockPendingTxService = MockPendingTxService();
      service = BackgroundPollingService(mockPendingTxService);
    });

    test('should start and stop polling', () {
      service.startPolling();
      expect(service.isPolling, true);

      service.stopPolling();
      expect(service.isPolling, false);
    });
  });
}
```

## Security Considerations

1. **Never sync private keys** - Only sync public data and settings
2. **Encrypt all cloud data** - Use device-specific encryption
3. **Validate all remote data** - Don't trust restored data blindly
4. **Rate limit API calls** - Respect network endpoints
5. **Handle offline gracefully** - Cache data for offline access

## Performance Tips

1. **Batch API calls** - Reduce network requests
2. **Use background isolates** - For heavy processing
3. **Cache aggressively** - Minimize redundant requests
4. **Lazy load services** - Initialize only when needed
5. **Monitor memory usage** - Dispose resources properly

## Next Steps

1. Choose which services you need
2. Implement basic versions first
3. Add comprehensive error handling
4. Test thoroughly in different network conditions
5. Monitor performance and resource usage
6. Add user controls for service preferences

These services will enhance your wallet with professional-grade features while maintaining the clean architecture provided by the core implementation.