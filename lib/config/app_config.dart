// lib/config/app_config.dart

import 'package:accumulate_api/accumulate_api.dart';
import 'package:accumulate_api/src/v3/acme_client.dart' as v3;

class AppConfig {
  // Network configuration - developers can modify these endpoints
  static const String defaultMainnetUrl = 'https://mainnet.accumulate.io';
  static const String defaultTestnetUrl = 'https://testnet.accumulate.io';

  // Current network (developers should make this configurable)
  static const String currentNetworkUrl = defaultMainnetUrl;

  // API clients - initialized with default endpoints
  static final ACMEClient acmeClient = ACMEClient(currentNetworkUrl);
  static final v3.ACMEClientV3 acmeClientV3 = v3.ACMEClientV3(currentNetworkUrl);

  // Application configuration
  static const String appName = 'Accumulate Lite Wallet';
  static const String appVersion = '1.0.0';

  // Feature flags (developers can extend these)
  static const bool enableTestFeatures = false;
  static const bool enableLogging = true;

  // Network endpoints that developers may want to customize
  static const Map<String, String> networkEndpoints = {
    'mainnet': defaultMainnetUrl,
    'testnet': defaultTestnetUrl,
    // Add custom endpoints here
  };

  // Initialize with custom network if needed
  static void initializeWithCustomNetwork(String networkUrl) {
    // Developers can implement custom network switching here
    // This would require reinitializing the API clients
  }
}

// DEVELOPER NOTE:
// This is a minimal configuration. For a production wallet, you should:
// 1. Make network selection dynamic (mainnet/testnet/custom)
// 2. Add environment-specific configurations
// 3. Implement secure configuration storage
// 4. Add custom endpoint validation
// 5. Consider configuration file loading (JSON/YAML)