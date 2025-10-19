# Configuration - Network and App Settings

This directory contains configuration files for network endpoints, feature flags, and application settings. **Some files are ready to use, others need your customization.**

## What's Included ✅

### AppConfig (`app_config.dart`)
**Ready to Use** - Basic network configuration with sensible defaults

**Features:**
- Mainnet and testnet endpoint configuration
- Accumulate API client initialization
- Network switching capabilities
- Endpoint validation

**Usage:**
```dart
// Get current API clients
final apiClient = AppConfig.acmeClient;
final apiClientV3 = AppConfig.acmeClientV3;

// Get current network
final networkUrl = AppConfig.currentNetworkUrl;

// Switch networks
await AppConfig.switchNetwork('https://testnet.accumulate.io');
```

### FeatureFlags (`feature_flags.dart`)
**Ready to Use** - Feature toggle system

**Usage:**
```dart
if (FeatureFlags.isEnabled('new_transaction_ui')) {
  // Show new UI
} else {
  // Show legacy UI
}
```

### AcmeSupplyFetcher (`acme_supply_fetcher.dart`)
**Ready to Use** - Fetch ACME token supply data

## What Needs Customization ⚠️

### Network Configuration
The basic configuration uses hardcoded endpoints. For production, you should:

```dart
// Current configuration (basic)
static const String currentNetworkUrl = defaultMainnetUrl;

// Recommended: Make it dynamic
static String get currentNetworkUrl =>
    RuntimeConfig.getSelectedNetwork() ?? defaultMainnetUrl;
```

### Environment-Specific Settings
Add environment-specific configurations:

```dart
// lib/config/environments/production_config.dart
class ProductionConfig {
  static const String apiUrl = 'https://mainnet.accumulate.io';
  static const bool enableLogging = false;
  static const bool enableAnalytics = true;
}

// lib/config/environments/development_config.dart
class DevelopmentConfig {
  static const String apiUrl = 'https://testnet.accumulate.io';
  static const bool enableLogging = true;
  static const bool enableAnalytics = false;
}
```

## Required Implementations

### 1. Runtime Configuration
Implement user-configurable network selection:

```dart
// lib/config/runtime_config.dart
class RuntimeConfig {
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String? getSelectedNetwork() {
    return _prefs?.getString('selected_network');
  }

  static Future<void> setSelectedNetwork(String networkUrl) async {
    await _prefs?.setString('selected_network', networkUrl);
    await AppConfig.switchNetwork(networkUrl);
  }
}
```

### 2. Build Configuration
Set up different configurations for debug/release builds:

```dart
// lib/config/build_config.dart
class BuildConfig {
  static const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;
  static const String flavor = String.fromEnvironment('FLUTTER_FLAVOR', defaultValue: 'development');

  static bool get isProduction => flavor == 'production';
  static bool get isDevelopment => flavor == 'development';

  static String get defaultNetwork {
    switch (flavor) {
      case 'production':
        return 'https://mainnet.accumulate.io';
      case 'development':
      default:
        return 'https://testnet.accumulate.io';
    }
  }
}
```

### 3. Security Configuration
Add API key management and security settings:

```dart
// lib/config/security_config.dart
class SecurityConfig {
  // Never hardcode API keys - use environment variables
  static String get apiKey =>
      const String.fromEnvironment('API_KEY', defaultValue: '');

  static bool get enableCertificatePinning =>
      const bool.fromEnvironment('ENABLE_CERT_PINNING', defaultValue: true);

  static Duration get networkTimeout =>
      const Duration(seconds: 30);
}
```

## Configuration UI

### Network Selection Screen
Create a UI for users to select networks:

```dart
// lib/features/settings/presentation/network_selection_screen.dart
class NetworkSelectionScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Network Selection')),
      body: ListView(
        children: [
          RadioListTile<String>(
            title: Text('Mainnet'),
            subtitle: Text('https://mainnet.accumulate.io'),
            value: 'https://mainnet.accumulate.io',
            groupValue: _selectedNetwork,
            onChanged: _onNetworkChanged,
          ),
          RadioListTile<String>(
            title: Text('Testnet'),
            subtitle: Text('https://testnet.accumulate.io'),
            value: 'https://testnet.accumulate.io',
            groupValue: _selectedNetwork,
            onChanged: _onNetworkChanged,
          ),
          // Add custom network input
        ],
      ),
    );
  }
}
```

## Environment Variables

### Development Setup
Create `.env` files for different environments:

```bash
# .env.development
FLUTTER_FLAVOR=development
ACCUMULATE_URL=https://testnet.accumulate.io
ENABLE_LOGGING=true

# .env.production
FLUTTER_FLAVOR=production
ACCUMULATE_URL=https://mainnet.accumulate.io
ENABLE_LOGGING=false
```

### Build Scripts
```bash
# Build for development
flutter build apk --dart-define-from-file=.env.development

# Build for production
flutter build apk --dart-define-from-file=.env.production
```

## Configuration Testing

### Unit Tests
```dart
void main() {
  group('AppConfig', () {
    test('should validate network endpoints', () {
      expect(AppConfig.isValidEndpoint('https://mainnet.accumulate.io'), true);
      expect(AppConfig.isValidEndpoint('invalid-url'), false);
    });

    test('should switch networks correctly', () async {
      final newNetwork = 'https://testnet.accumulate.io';
      await AppConfig.switchNetwork(newNetwork);

      expect(AppConfig.currentNetworkUrl, newNetwork);
    });
  });
}
```

### Integration Tests
```dart
void main() {
  testWidgets('network selection updates configuration', (tester) async {
    await tester.pumpWidget(MyApp());

    // Navigate to network selection
    await tester.tap(find.text('Settings'));
    await tester.tap(find.text('Network'));

    // Select testnet
    await tester.tap(find.text('Testnet'));

    // Verify configuration updated
    expect(AppConfig.currentNetworkUrl, contains('testnet'));
  });
}
```

## Security Best Practices

### 1. API Key Management
- Never commit API keys to version control
- Use environment variables or secure key management
- Rotate keys regularly for production

### 2. Network Security
- Always use HTTPS endpoints
- Implement certificate pinning for production
- Validate all user-provided endpoints

### 3. Configuration Validation
- Validate network URLs before using them
- Sanitize user inputs
- Provide fallback configurations

## Migration Path

### From Basic to Advanced Configuration

1. **Start with included basic configuration**
2. **Add runtime network selection**
3. **Implement environment-specific configs**
4. **Add security configurations**
5. **Create configuration UI**
6. **Add comprehensive testing**

## Next Steps

1. **Customize Network Settings** - Add your preferred endpoints
2. **Implement User Preferences** - Allow runtime configuration changes
3. **Add Environment Configs** - Separate development/production settings
4. **Security Hardening** - Add API key management and validation
5. **Create Settings UI** - User-friendly configuration interface

The configuration system provides a flexible foundation that can grow from simple hardcoded values to a sophisticated, user-configurable system.