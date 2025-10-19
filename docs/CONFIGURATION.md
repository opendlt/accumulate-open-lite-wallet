# Configuration Implementation Guide

This guide shows how to configure your Accumulate wallet for different environments, networks, and deployment scenarios.

## Overview

The wallet includes basic configuration in `lib/config/app_config.dart`, but you need to customize it for:
- Network selection (mainnet/testnet/custom)
- Environment-specific settings
- API endpoints and keys
- Feature flags and toggles
- Build-specific configurations

## Configuration Structure

### Current Configuration

```dart
// lib/config/app_config.dart - Basic setup included
class AppConfig {
  static const String defaultMainnetUrl = 'https://mainnet.accumulate.io';
  static const String defaultTestnetUrl = 'https://testnet.accumulate.io';
  static const String currentNetworkUrl = defaultMainnetUrl;

  static final ACMEClient acmeClient = ACMEClient(currentNetworkUrl);
  static final v3.ACMEClientV3 acmeClientV3 = v3.ACMEClientV3(currentNetworkUrl);
}
```

## Enhanced Configuration Implementation

### 1. Environment-Based Configuration

Create environment-specific configurations:

```dart
// lib/config/environments/environment.dart
abstract class Environment {
  String get name;
  String get accumulate_url;
  String get apiKey;
  bool get enableLogging;
  bool get enableAnalytics;
  Map<String, dynamic> get additionalConfig;
}

// lib/config/environments/production_environment.dart
class ProductionEnvironment implements Environment {
  @override
  String get name => 'production';

  @override
  String get accumulate_url => 'https://mainnet.accumulate.io';

  @override
  String get apiKey => const String.fromEnvironment('PROD_API_KEY', defaultValue: '');

  @override
  bool get enableLogging => false;

  @override
  bool get enableAnalytics => true;

  @override
  Map<String, dynamic> get additionalConfig => {
    'maxRetries': 3,
    'timeout': 30000,
    'enableCaching': true,
  };
}

// lib/config/environments/development_environment.dart
class DevelopmentEnvironment implements Environment {
  @override
  String get name => 'development';

  @override
  String get accumulate_url => 'https://testnet.accumulate.io';

  @override
  String get apiKey => const String.fromEnvironment('DEV_API_KEY', defaultValue: 'test_key');

  @override
  bool get enableLogging => true;

  @override
  bool get enableAnalytics => false;

  @override
  Map<String, dynamic> get additionalConfig => {
    'maxRetries': 1,
    'timeout': 10000,
    'enableCaching': false,
    'enableDebugFeatures': true,
  };
}
```

### 2. Configuration Manager

```dart
// lib/config/configuration_manager.dart
class ConfigurationManager {
  static Environment? _currentEnvironment;
  static Environment get environment => _currentEnvironment ?? _getDefaultEnvironment();

  static void initialize({Environment? customEnvironment}) {
    _currentEnvironment = customEnvironment ?? _getDefaultEnvironment();

    // Initialize API clients with current environment
    _initializeApiClients();

    // Apply configuration
    _applyConfiguration();
  }

  static Environment _getDefaultEnvironment() {
    const flavor = String.fromEnvironment('FLUTTER_FLAVOR', defaultValue: 'development');

    switch (flavor) {
      case 'production':
        return ProductionEnvironment();
      case 'staging':
        return StagingEnvironment();
      case 'development':
      default:
        return DevelopmentEnvironment();
    }
  }

  static void _initializeApiClients() {
    AppConfig.initializeWithEnvironment(environment);
  }

  static void _applyConfiguration() {
    // Configure logging
    if (environment.enableLogging) {
      _enableLogging();
    }

    // Apply timeout settings
    _configureNetworkTimeouts();
  }
}
```

### 3. Updated App Config

```dart
// lib/config/app_config.dart
class AppConfig {
  static late Environment _environment;
  static late ACMEClient _acmeClient;
  static late v3.ACMEClientV3 _acmeClientV3;

  // Getters
  static Environment get environment => _environment;
  static ACMEClient get acmeClient => _acmeClient;
  static v3.ACMEClientV3 get acmeClientV3 => _acmeClientV3;

  // Network management
  static String get currentNetworkUrl => _environment.accumulate_url;
  static String get networkName => _environment.name;

  // Initialize with environment
  static void initializeWithEnvironment(Environment environment) {
    _environment = environment;
    _acmeClient = ACMEClient(_environment.accumulate_url);
    _acmeClientV3 = v3.ACMEClientV3(_environment.accumulate_url);
  }

  // Network switching
  static Future<void> switchNetwork(String networkUrl) async {
    _acmeClient = ACMEClient(networkUrl);
    _acmeClientV3 = v3.ACMEClientV3(networkUrl);

    // Notify app of network change
    await _notifyNetworkChange(networkUrl);
  }

  // Custom endpoint validation
  static bool isValidEndpoint(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'https' || uri.scheme == 'http');
    } catch (e) {
      return false;
    }
  }
}
```

### 4. Runtime Configuration

```dart
// lib/config/runtime_config.dart
class RuntimeConfig {
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Network selection
  static Future<void> setSelectedNetwork(String networkUrl) async {
    await _prefs?.setString('selected_network', networkUrl);
    await AppConfig.switchNetwork(networkUrl);
  }

  static String getSelectedNetwork() {
    return _prefs?.getString('selected_network') ?? AppConfig.environment.accumulate_url;
  }

  // Feature flags
  static Future<void> setFeatureEnabled(String feature, bool enabled) async {
    await _prefs?.setBool('feature_$feature', enabled);
  }

  static bool isFeatureEnabled(String feature) {
    return _prefs?.getBool('feature_$feature') ?? false;
  }

  // User preferences
  static Future<void> setUserPreference(String key, dynamic value) async {
    if (value is String) {
      await _prefs?.setString('pref_$key', value);
    } else if (value is bool) {
      await _prefs?.setBool('pref_$key', value);
    } else if (value is int) {
      await _prefs?.setInt('pref_$key', value);
    }
  }

  static T? getUserPreference<T>(String key) {
    return _prefs?.get('pref_$key') as T?;
  }
}
```

## Build Configuration

### 1. Flutter Flavors

Create different flavors for different environments:

```dart
// android/app/build.gradle
android {
    // ...

    flavorDimensions "environment"

    productFlavors {
        development {
            dimension "environment"
            applicationIdSuffix ".dev"
            resValue "string", "app_name", "Accumulate Wallet (Dev)"
        }

        staging {
            dimension "environment"
            applicationIdSuffix ".staging"
            resValue "string", "app_name", "Accumulate Wallet (Staging)"
        }

        production {
            dimension "environment"
            resValue "string", "app_name", "Accumulate Wallet"
        }
    }
}
```

### 2. Environment Files

Create `.env` files for sensitive configuration:

```bash
# .env.development
FLUTTER_FLAVOR=development
ACCUMULATE_URL=https://testnet.accumulate.io
API_KEY=dev_api_key_here
ENABLE_LOGGING=true
ENABLE_ANALYTICS=false

# .env.production
FLUTTER_FLAVOR=production
ACCUMULATE_URL=https://mainnet.accumulate.io
API_KEY=prod_api_key_here
ENABLE_LOGGING=false
ENABLE_ANALYTICS=true
```

### 3. Build Scripts

```bash
#!/bin/bash
# scripts/build_dev.sh
flutter build apk --flavor development --dart-define-from-file=.env.development

# scripts/build_prod.sh
flutter build apk --flavor production --dart-define-from-file=.env.production
```

## Network Selection UI

### 1. Network Selection Screen

```dart
// lib/features/settings/presentation/network_selection_screen.dart
class NetworkSelectionScreen extends StatefulWidget {
  @override
  _NetworkSelectionScreenState createState() => _NetworkSelectionScreenState();
}

class _NetworkSelectionScreenState extends State<NetworkSelectionScreen> {
  String _selectedNetwork = '';
  final _customUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedNetwork = RuntimeConfig.getSelectedNetwork();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Network Selection')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Mainnet'),
            subtitle: Text('https://mainnet.accumulate.io'),
            leading: Radio<String>(
              value: 'https://mainnet.accumulate.io',
              groupValue: _selectedNetwork,
              onChanged: _onNetworkChanged,
            ),
          ),
          ListTile(
            title: Text('Testnet'),
            subtitle: Text('https://testnet.accumulate.io'),
            leading: Radio<String>(
              value: 'https://testnet.accumulate.io',
              groupValue: _selectedNetwork,
              onChanged: _onNetworkChanged,
            ),
          ),
          ExpansionTile(
            title: Text('Custom Network'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _customUrlController,
                      decoration: InputDecoration(
                        labelText: 'Custom URL',
                        hintText: 'https://your-node.example.com',
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _validateAndSetCustomNetwork,
                      child: Text('Use Custom Network'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onNetworkChanged(String? network) async {
    if (network != null) {
      setState(() => _selectedNetwork = network);
      await RuntimeConfig.setSelectedNetwork(network);

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network changed to ${_getNetworkName(network)}')),
      );
    }
  }

  void _validateAndSetCustomNetwork() async {
    final url = _customUrlController.text.trim();

    if (AppConfig.isValidEndpoint(url)) {
      await _testNetworkConnection(url);
    } else {
      _showError('Invalid URL format');
    }
  }

  Future<void> _testNetworkConnection(String url) async {
    try {
      // Test connection to custom network
      final testClient = ACMEClient(url);
      // Add test API call here

      await RuntimeConfig.setSelectedNetwork(url);
      setState(() => _selectedNetwork = url);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Custom network connected successfully')),
      );
    } catch (e) {
      _showError('Failed to connect to network: $e');
    }
  }
}
```

### 2. Settings Integration

```dart
// lib/features/settings/logic/settings_provider.dart
class SettingsProvider extends ChangeNotifier {
  String _currentNetwork = '';
  bool _isDarkMode = false;
  bool _biometricEnabled = false;

  // Getters
  String get currentNetwork => _currentNetwork;
  bool get isDarkMode => _isDarkMode;
  bool get biometricEnabled => _biometricEnabled;

  Future<void> loadSettings() async {
    _currentNetwork = RuntimeConfig.getSelectedNetwork();
    _isDarkMode = RuntimeConfig.getUserPreference<bool>('dark_mode') ?? false;
    _biometricEnabled = RuntimeConfig.getUserPreference<bool>('biometric_enabled') ?? false;

    notifyListeners();
  }

  Future<void> updateNetwork(String networkUrl) async {
    await RuntimeConfig.setSelectedNetwork(networkUrl);
    _currentNetwork = networkUrl;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await RuntimeConfig.setUserPreference('dark_mode', _isDarkMode);
    notifyListeners();
  }
}
```

## Security Configuration

### 1. API Key Management

```dart
// lib/config/security_config.dart
class SecurityConfig {
  // Never hardcode API keys
  static String get apiKey => const String.fromEnvironment('API_KEY', defaultValue: '');

  // Pin/certificate validation
  static bool get enableCertificatePinning =>
      const bool.fromEnvironment('ENABLE_CERT_PINNING', defaultValue: true);

  // Request signing
  static bool get enableRequestSigning =>
      const bool.fromEnvironment('ENABLE_REQUEST_SIGNING', defaultValue: false);

  // Timeout configurations
  static Duration get connectionTimeout =>
      const Duration(seconds: 30);

  static Duration get requestTimeout =>
      const Duration(seconds: 60);
}
```

### 2. Certificate Pinning (Optional)

```dart
// lib/config/network_security.dart
class NetworkSecurity {
  static SecurityContext get securityContext {
    final context = SecurityContext.defaultContext;

    if (SecurityConfig.enableCertificatePinning) {
      // Add certificate pinning implementation
      _addCertificatePins(context);
    }

    return context;
  }

  static void _addCertificatePins(SecurityContext context) {
    // Implementation depends on your security requirements
  }
}
```

## Initialization

### 1. Update Main App

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize configuration first
  await RuntimeConfig.initialize();
  ConfigurationManager.initialize();

  // Initialize core services with configuration
  _initializeCoreServices();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
        // ... other providers
      ],
      child: const AccumulateLiteWalletApp(),
    ),
  );
}
```

### 2. Configuration Testing

```dart
// test/config/configuration_test.dart
void main() {
  group('Configuration', () {
    test('should load development environment by default', () {
      ConfigurationManager.initialize();

      expect(ConfigurationManager.environment, isA<DevelopmentEnvironment>());
      expect(ConfigurationManager.environment.enableLogging, true);
    });

    test('should validate network endpoints', () {
      expect(AppConfig.isValidEndpoint('https://mainnet.accumulate.io'), true);
      expect(AppConfig.isValidEndpoint('invalid-url'), false);
    });
  });
}
```

## Best Practices

### 1. Security
- Never commit API keys or secrets
- Use environment variables for sensitive data
- Validate all user-provided endpoints
- Implement proper certificate validation

### 2. Flexibility
- Make network selection user-configurable
- Support custom endpoints for enterprise users
- Provide feature flags for gradual rollouts
- Allow runtime configuration updates

### 3. Testing
- Test all configuration environments
- Validate network switching functionality
- Mock configuration for unit tests
- Test configuration persistence

## Next Steps

1. Choose your configuration strategy
2. Implement environment-specific settings
3. Add network selection UI
4. Set up build flavors
5. Configure security settings
6. Test across all environments

This configuration system will allow your wallet to work across different environments and provide users with flexibility in network selection.