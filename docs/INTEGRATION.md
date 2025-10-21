# Integration & Extension Guide

This guide provides comprehensive instructions for integrating external services, extending functionality, and customizing the Accumulate Open Lite Wallet for your specific use case.

## Table of Contents

- [Integration Overview](#integration-overview)
- [Authentication Integration](#authentication-integration)
- [Cloud Services Integration](#cloud-services-integration)
- [Push Notifications](#push-notifications)
- [Payment Processing](#payment-processing)
- [External APIs](#external-apis)
- [Custom Transaction Types](#custom-transaction-types)
- [Plugin Architecture](#plugin-architecture)
- [Third-Party Services](#third-party-services)
- [Enterprise Features](#enterprise-features)

## Integration Overview

### Architecture for Extensions

The wallet is designed with clear integration points that allow you to add functionality without modifying core business logic:

```
┌─────────────────────────────────────────────────────────────┐
│                    Integration Layer                        │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │   Auth Providers│ │  Cloud Services │ │  External APIs  ││
│  │   (OAuth, SAML, │ │  (AWS, Firebase,│ │  (KYC, Exchange,││
│  │    Custom)      │ │   Azure)        │ │   Analytics)    ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    Service Locator                         │
│            (Dependency Injection Container)                 │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    Core Business Logic                      │
│              (Blockchain, Crypto, Storage)                  │
└─────────────────────────────────────────────────────────────┘
```

### Extension Principles

1. **Service-Based**: Add new services via ServiceLocator
2. **Interface-Driven**: Use abstract interfaces for extensibility
3. **Configuration-Based**: Feature flags and configuration files
4. **Event-Driven**: Hooks and callbacks for custom logic
5. **Platform-Agnostic**: Core logic remains Flutter-independent

## Authentication Integration

### Custom Authentication Provider

The wallet includes placeholder authentication that you can replace with your own system.

#### 1. Create Authentication Service

```dart
// lib/core/services/auth/custom_auth_service.dart
abstract class AuthenticationService {
  Future<AuthResult> login(String email, String password);
  Future<AuthResult> register(String email, String password);
  Future<void> logout();
  Future<bool> isAuthenticated();
  Future<UserProfile?> getCurrentUser();
  Stream<AuthState> get authStateChanges;
}

class CustomAuthService implements AuthenticationService {
  final HttpClient _httpClient;
  final SecureStorage _secureStorage;

  CustomAuthService({
    required HttpClient httpClient,
    required SecureStorage secureStorage,
  }) : _httpClient = httpClient,
       _secureStorage = secureStorage;

  @override
  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await _httpClient.post(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response.success) {
        final token = response.data['token'];
        await _secureStorage.write('auth_token', token);
        return AuthResult.success(UserProfile.fromJson(response.data['user']));
      } else {
        return AuthResult.error(response.error);
      }
    } catch (e) {
      return AuthResult.error('Authentication failed: $e');
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read('auth_token');
    if (token == null) return false;

    // Validate token with your backend
    return await _validateToken(token);
  }

  // ... implement other methods
}
```

#### 2. Register with ServiceLocator

```dart
// lib/core/services/service_locator.dart
class ServiceLocator {
  late final AuthenticationService _authService;

  Future<void> initialize() async {
    // ... existing initialization

    // Add custom auth service
    _authService = CustomAuthService(
      httpClient: _networkService.httpClient,
      secureStorage: _secureStorage,
    );

    _isInitialized = true;
  }

  AuthenticationService get authService {
    _ensureInitialized();
    return _authService;
  }
}
```

#### 3. Update UI to Use Authentication

```dart
// lib/screens/auth/login_screen.dart
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    final authService = serviceLocator.authService;
    final result = await authService.login(
      _emailController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### OAuth Integration Examples

#### Google OAuth

```dart
// pubspec.yaml dependencies
dependencies:
  google_sign_in: ^6.1.5

// Implementation
class GoogleAuthService implements AuthenticationService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  @override
  Future<AuthResult> login(String email, String password) async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;

        // Send token to your backend for verification
        final result = await _verifyWithBackend(auth.idToken!);
        return result;
      }
      return AuthResult.error('Google sign-in cancelled');
    } catch (e) {
      return AuthResult.error('Google sign-in failed: $e');
    }
  }
}
```

#### Firebase Authentication

```dart
// pubspec.yaml dependencies
dependencies:
  firebase_auth: ^4.15.3
  firebase_core: ^2.24.2

// Implementation
class FirebaseAuthService implements AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<AuthResult> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return AuthResult.success(
          UserProfile.fromFirebaseUser(credential.user!),
        );
      }
      return AuthResult.error('Login failed');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(e.message ?? 'Authentication failed');
    }
  }

  @override
  Stream<AuthState> get authStateChanges {
    return _auth.authStateChanges().map((user) {
      if (user != null) {
        return AuthState.authenticated(UserProfile.fromFirebaseUser(user));
      } else {
        return AuthState.unauthenticated();
      }
    });
  }
}
```

## Cloud Services Integration

### AWS Integration

#### S3 Backup Service

```dart
// pubspec.yaml dependencies
dependencies:
  aws_s3_api: ^2.0.2

class S3BackupService {
  final S3 _s3;
  final String _bucketName;

  S3BackupService({
    required String accessKey,
    required String secretKey,
    required String region,
    required String bucketName,
  }) : _s3 = S3(
          region: region,
          credentials: AwsClientCredentials(
            accessKey: accessKey,
            secretKey: secretKey,
          ),
        ),
        _bucketName = bucketName;

  Future<bool> backupWalletData(String userId, Map<String, dynamic> data) async {
    try {
      final key = 'wallets/$userId/backup_${DateTime.now().millisecondsSinceEpoch}.json';

      await _s3.putObject(
        bucket: _bucketName,
        key: key,
        body: utf8.encode(json.encode(data)),
        contentType: 'application/json',
      );

      return true;
    } catch (e) {
      print('S3 backup failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> restoreWalletData(String userId) async {
    try {
      // List objects for user
      final result = await _s3.listObjectsV2(
        bucket: _bucketName,
        prefix: 'wallets/$userId/',
      );

      if (result.contents?.isEmpty ?? true) return null;

      // Get latest backup
      final latestObject = result.contents!
          .where((obj) => obj.key?.endsWith('.json') ?? false)
          .reduce((a, b) =>
              (a.lastModified?.isAfter(b.lastModified ?? DateTime(0)) ?? false) ? a : b);

      // Download and parse
      final response = await _s3.getObject(
        bucket: _bucketName,
        key: latestObject.key!,
      );

      final data = await response.body!.transform(utf8.decoder).join();
      return json.decode(data);
    } catch (e) {
      print('S3 restore failed: $e');
      return null;
    }
  }
}
```

#### Register Backup Service

```dart
// lib/core/services/service_locator.dart
class ServiceLocator {
  late final S3BackupService? _backupService;

  Future<void> initialize() async {
    // ... existing initialization

    // Add backup service if configured
    if (AppConfig.enableCloudBackup) {
      _backupService = S3BackupService(
        accessKey: AppConfig.awsAccessKey,
        secretKey: AppConfig.awsSecretKey,
        region: AppConfig.awsRegion,
        bucketName: AppConfig.s3BucketName,
      );
    }
  }

  S3BackupService? get backupService => _backupService;
}
```

### Firebase Integration

#### Firestore Database Sync

```dart
class FirestoreSync {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> syncAccountData(String userId, List<AccumulateAccount> accounts) async {
    final batch = _firestore.batch();

    for (final account in accounts) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('accounts')
          .doc(account.address);

      batch.set(docRef, account.toJson());
    }

    await batch.commit();
  }

  Stream<List<AccumulateAccount>> watchAccountData(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccumulateAccount.fromJson(doc.data()))
            .toList());
  }
}
```

## Push Notifications

### Firebase Cloud Messaging

#### Setup FCM

```dart
// pubspec.yaml dependencies
dependencies:
  firebase_messaging: ^14.7.9

class FCMNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      final token = await _messaging.getToken();
      print('FCM Token: $token');

      // Send token to your backend
      await _sendTokenToBackend(token);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');

    // Show local notification or update UI
    _showLocalNotification(message);
  }

  Future<void> _sendTokenToBackend(String? token) async {
    if (token != null) {
      final authService = serviceLocator.authService;
      final user = await authService.getCurrentUser();

      if (user != null) {
        await serviceLocator.networkService.post('/users/${user.id}/fcm-token', {
          'token': token,
        });
      }
    }
  }
}

// Background message handler (top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
}
```

### Custom Notification Types

```dart
enum NotificationType {
  transactionReceived,
  transactionConfirmed,
  multiSigRequest,
  lowBalance,
  securityAlert,
}

class WalletNotification {
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  const WalletNotification({
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.timestamp,
  });

  static WalletNotification fromRemoteMessage(RemoteMessage message) {
    final typeStr = message.data['type'] ?? 'unknown';
    final type = NotificationType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => NotificationType.transactionReceived,
    );

    return WalletNotification(
      type: type,
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      data: message.data,
      timestamp: DateTime.now(),
    );
  }
}

class NotificationHandler {
  void handleNotification(WalletNotification notification) {
    switch (notification.type) {
      case NotificationType.transactionReceived:
        _handleTransactionNotification(notification);
        break;
      case NotificationType.multiSigRequest:
        _handleMultiSigNotification(notification);
        break;
      // ... handle other types
    }
  }

  void _handleTransactionNotification(WalletNotification notification) {
    final transactionHash = notification.data?['transactionHash'];
    if (transactionHash != null) {
      // Navigate to transaction details
      navigatorKey.currentState?.pushNamed(
        '/transaction-details',
        arguments: transactionHash,
      );
    }
  }
}
```

## Payment Processing

### Credit Card Integration (Stripe)

```dart
// pubspec.yaml dependencies
dependencies:
  stripe_payment: ^1.1.4

class StripePaymentService {
  static const String _publishableKey = 'pk_test_...';
  static const String _secretKey = 'sk_test_...'; // Server-side only

  Future<void> initialize() async {
    Stripe.publishableKey = _publishableKey;
    await Stripe.instance.applySettings();
  }

  Future<PaymentResult> purchaseCreditsWithCard({
    required double usdAmount,
    required String accountUrl,
  }) async {
    try {
      // Create payment intent on your backend
      final paymentIntent = await _createPaymentIntent(usdAmount);

      // Confirm payment with Stripe
      final result = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntent.clientSecret,
        data: PaymentMethodData(
          billingDetails: BillingDetails(
            // User billing information
          ),
        ),
      );

      if (result.status == PaymentIntentStatus.Succeeded) {
        // Convert USD to ACME and purchase credits
        final acmeAmount = await _convertUSDToACME(usdAmount);
        await _purchaseCreditsWithACME(accountUrl, acmeAmount);

        return PaymentResult.success();
      } else {
        return PaymentResult.error('Payment failed');
      }
    } catch (e) {
      return PaymentResult.error('Payment error: $e');
    }
  }

  Future<PaymentIntent> _createPaymentIntent(double amount) async {
    final response = await serviceLocator.networkService.post(
      '/create-payment-intent',
      {
        'amount': (amount * 100).round(), // Stripe uses cents
        'currency': 'usd',
      },
    );

    return PaymentIntent.fromJson(response.data);
  }
}
```

### Bank Transfer Integration

```dart
class ACHPaymentService {
  Future<PaymentResult> purchaseCreditsWithBankTransfer({
    required double usdAmount,
    required BankAccount bankAccount,
    required String accountUrl,
  }) async {
    try {
      // Initiate ACH transfer via your payment processor
      final transferResult = await _initiateACHTransfer(
        amount: usdAmount,
        bankAccount: bankAccount,
      );

      if (transferResult.success) {
        // Store pending purchase
        await _storePendingPurchase(
          transferId: transferResult.transferId!,
          usdAmount: usdAmount,
          accountUrl: accountUrl,
        );

        return PaymentResult.pending(transferResult.transferId!);
      } else {
        return PaymentResult.error(transferResult.error);
      }
    } catch (e) {
      return PaymentResult.error('Bank transfer failed: $e');
    }
  }

  // Webhook handler for ACH completion
  Future<void> handleACHWebhook(Map<String, dynamic> webhookData) async {
    final transferId = webhookData['transfer_id'];
    final status = webhookData['status'];

    if (status == 'completed') {
      final pendingPurchase = await _getPendingPurchase(transferId);
      if (pendingPurchase != null) {
        final acmeAmount = await _convertUSDToACME(pendingPurchase.usdAmount);
        await _purchaseCreditsWithACME(
          pendingPurchase.accountUrl,
          acmeAmount,
        );
        await _deletePendingPurchase(transferId);
      }
    }
  }
}
```

## External APIs

### KYC/AML Integration

```dart
abstract class KYCProvider {
  Future<KYCResult> verifyIdentity(UserProfile user, List<Document> documents);
  Future<KYCStatus> getVerificationStatus(String userId);
}

class JumioKYCService implements KYCProvider {
  final String _apiToken;
  final String _apiSecret;

  JumioKYCService({
    required String apiToken,
    required String apiSecret,
  }) : _apiToken = apiToken,
       _apiSecret = apiSecret;

  @override
  Future<KYCResult> verifyIdentity(UserProfile user, List<Document> documents) async {
    try {
      final response = await http.post(
        Uri.parse('https://netverify.com/api/netverify/v2/performNetverify'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_apiToken:$_apiSecret'))}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'customerInternalReference': user.id,
          'userReference': user.email,
          'reportingCriteria': 'VERIFY_IDENTITY',
          // ... other parameters
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return KYCResult.fromJson(data);
      } else {
        return KYCResult.error('KYC verification failed');
      }
    } catch (e) {
      return KYCResult.error('KYC service error: $e');
    }
  }
}

// Usage in wallet
class ComplianceService {
  final KYCProvider _kycProvider;

  ComplianceService(this._kycProvider);

  Future<bool> checkTransactionCompliance({
    required String fromAddress,
    required String toAddress,
    required double amount,
  }) async {
    // Check if users are KYC verified for large transactions
    if (amount > 1000) {
      final fromUserKYC = await _getUserKYCStatus(fromAddress);
      final toUserKYC = await _getUserKYCStatus(toAddress);

      if (!fromUserKYC.verified || !toUserKYC.verified) {
        throw ComplianceException('KYC verification required for transactions over \$1000');
      }
    }

    return true;
  }
}
```

### Exchange Rate APIs

```dart
class ExchangeRateService {
  static const String _coinGeckoAPI = 'https://api.coingecko.com/api/v3';

  Future<double> getACMEPrice() async {
    try {
      final response = await http.get(
        Uri.parse('$_coinGeckoAPI/simple/price?ids=accumulate&vs_currencies=usd'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['accumulate']['usd'].toDouble();
      } else {
        throw Exception('Failed to fetch ACME price');
      }
    } catch (e) {
      // Fallback to cached price
      return await _getCachedPrice();
    }
  }

  Future<Map<String, double>> getCurrencyRates() async {
    try {
      final response = await http.get(
        Uri.parse('$_coinGeckoAPI/exchange_rates'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        return rates.map((key, value) =>
            MapEntry(key, value['value'].toDouble()));
      }
    } catch (e) {
      print('Failed to fetch exchange rates: $e');
    }

    return {'usd': 1.0}; // Fallback
  }
}
```

## Custom Transaction Types

### Adding New Transaction Type

```dart
// 1. Define new transaction type
class CustomTransaction extends Transaction {
  final String customField;
  final Map<String, dynamic> customData;

  CustomTransaction({
    required super.header,
    required this.customField,
    required this.customData,
  });

  @override
  String get type => 'customTransaction';

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'customField': customField,
      'customData': customData,
    };
  }
}

// 2. Create custom service
class CustomTransactionService {
  final EnhancedAccumulateService _accumulateService;
  final KeyManagementService _keyService;

  CustomTransactionService({
    required EnhancedAccumulateService accumulateService,
    required KeyManagementService keyService,
  }) : _accumulateService = accumulateService,
       _keyService = keyService;

  Future<TransactionResult> submitCustomTransaction({
    required String fromAccount,
    required String customField,
    required Map<String, dynamic> customData,
    required String signerKeyPageUrl,
  }) async {
    try {
      // Create transaction
      final transaction = CustomTransaction(
        header: TransactionHeader(
          principal: fromAccount,
          // ... other header fields
        ),
        customField: customField,
        customData: customData,
      );

      // Sign transaction
      final signer = await _keyService.createADISigner(signerKeyPageUrl);
      if (signer == null) {
        return TransactionResult.error('Failed to create signer');
      }

      final signedTx = await transaction.sign(signer);

      // Submit to network
      final result = await _accumulateService.submitTransaction(signedTx);

      return TransactionResult.success(result.transactionHash);
    } catch (e) {
      return TransactionResult.error('Custom transaction failed: $e');
    }
  }
}

// 3. Register with ServiceLocator
class ServiceLocator {
  late final CustomTransactionService _customTransactionService;

  Future<void> initialize() async {
    // ... existing initialization

    _customTransactionService = CustomTransactionService(
      accumulateService: _enhancedAccumulateService,
      keyService: _keyManagementService,
    );
  }

  CustomTransactionService get customTransactionService {
    _ensureInitialized();
    return _customTransactionService;
  }
}
```

## Plugin Architecture

### Plugin Interface

```dart
abstract class WalletPlugin {
  String get name;
  String get version;
  List<String> get dependencies;

  Future<void> initialize(ServiceLocator serviceLocator);
  Future<void> dispose();

  // UI integration points
  List<Widget>? getDashboardWidgets();
  List<PopupMenuEntry>? getMenuItems();
  Widget? getSettingsPage();

  // Service integration points
  Future<void> onTransactionSubmitted(Transaction transaction);
  Future<void> onAccountCreated(AccumulateAccount account);
}

// Example plugin implementation
class AnalyticsPlugin implements WalletPlugin {
  @override
  String get name => 'Analytics Plugin';

  @override
  String get version => '1.0.0';

  @override
  List<String> get dependencies => ['firebase_analytics'];

  late FirebaseAnalytics _analytics;

  @override
  Future<void> initialize(ServiceLocator serviceLocator) async {
    _analytics = FirebaseAnalytics.instance;
    await _analytics.logAppOpen();
  }

  @override
  Future<void> onTransactionSubmitted(Transaction transaction) async {
    await _analytics.logEvent(
      name: 'transaction_submitted',
      parameters: {
        'transaction_type': transaction.type,
        'amount': transaction.amount?.toString(),
      },
    );
  }

  @override
  List<Widget>? getDashboardWidgets() {
    return [
      Card(
        child: ListTile(
          title: Text('Analytics'),
          subtitle: Text('View wallet usage statistics'),
          onTap: () => _showAnalyticsDashboard(),
        ),
      ),
    ];
  }
}

// Plugin manager
class PluginManager {
  final List<WalletPlugin> _plugins = [];

  void registerPlugin(WalletPlugin plugin) {
    _plugins.add(plugin);
  }

  Future<void> initializeAll(ServiceLocator serviceLocator) async {
    for (final plugin in _plugins) {
      try {
        await plugin.initialize(serviceLocator);
        print('Initialized plugin: ${plugin.name}');
      } catch (e) {
        print('Failed to initialize plugin ${plugin.name}: $e');
      }
    }
  }

  List<Widget> getAllDashboardWidgets() {
    final widgets = <Widget>[];
    for (final plugin in _plugins) {
      final pluginWidgets = plugin.getDashboardWidgets();
      if (pluginWidgets != null) {
        widgets.addAll(pluginWidgets);
      }
    }
    return widgets;
  }
}
```

## Third-Party Services

### Analytics Integration

```dart
class AnalyticsService {
  late FirebaseAnalytics _firebaseAnalytics;
  late MixpanelAnalytics _mixpanel;

  Future<void> initialize() async {
    _firebaseAnalytics = FirebaseAnalytics.instance;
    _mixpanel = MixpanelAnalytics('YOUR_MIXPANEL_TOKEN');
  }

  void trackTransaction({
    required String type,
    required double amount,
    required String fromAccount,
    required String toAccount,
  }) {
    final properties = {
      'transaction_type': type,
      'amount': amount,
      'from_account_type': _getAccountType(fromAccount),
      'to_account_type': _getAccountType(toAccount),
    };

    _firebaseAnalytics.logEvent(
      name: 'transaction',
      parameters: properties,
    );

    _mixpanel.track('Transaction', properties);
  }

  void trackUserAction(String action, Map<String, dynamic> properties) {
    _firebaseAnalytics.logEvent(
      name: action,
      parameters: properties,
    );

    _mixpanel.track(action, properties);
  }
}
```

### Crash Reporting

```dart
// pubspec.yaml dependencies
dependencies:
  firebase_crashlytics: ^3.4.8

class CrashReportingService {
  Future<void> initialize() async {
    // Initialize Crashlytics
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    // Set up Dart error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  void recordError(dynamic error, StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) {
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  void setUserIdentifier(String userId) {
    FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }

  void setCustomKey(String key, String value) {
    FirebaseCrashlytics.instance.setCustomKey(key, value);
  }
}
```

## Enterprise Features

### Multi-User Support

```dart
class MultiUserService {
  final AuthenticationService _authService;
  final DatabaseHelper _dbHelper;

  MultiUserService({
    required AuthenticationService authService,
    required DatabaseHelper dbHelper,
  }) : _authService = authService,
       _dbHelper = dbHelper;

  Future<void> switchUser(String userId) async {
    // Save current user data
    await _saveCurrentUserSession();

    // Load new user data
    await _loadUserSession(userId);

    // Notify UI of user change
    _userChangeController.add(userId);
  }

  Future<List<UserSession>> getAllUserSessions() async {
    return await _dbHelper.getAllUserSessions();
  }

  Future<void> addUserSession(UserProfile user) async {
    final session = UserSession(
      userId: user.id,
      email: user.email,
      lastAccessed: DateTime.now(),
    );

    await _dbHelper.insertUserSession(session);
  }
}
```

### Role-Based Access Control

```dart
enum UserRole {
  admin,
  manager,
  user,
  viewer,
}

class RBACService {
  final Map<UserRole, Set<String>> _permissions = {
    UserRole.admin: {
      'create_account',
      'delete_account',
      'send_transaction',
      'view_all_accounts',
      'manage_users',
    },
    UserRole.manager: {
      'create_account',
      'send_transaction',
      'view_all_accounts',
    },
    UserRole.user: {
      'send_transaction',
      'view_own_accounts',
    },
    UserRole.viewer: {
      'view_own_accounts',
    },
  };

  bool hasPermission(UserRole role, String permission) {
    return _permissions[role]?.contains(permission) ?? false;
  }

  Future<bool> canPerformAction(String userId, String action) async {
    final user = await _getUserProfile(userId);
    return hasPermission(user.role, action);
  }
}
```

---

This integration guide provides comprehensive patterns for extending the wallet with external services, custom functionality, and enterprise features. The modular architecture ensures that additions don't compromise the core blockchain functionality while enabling rich customization possibilities.