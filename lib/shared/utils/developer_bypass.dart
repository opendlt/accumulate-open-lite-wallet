import 'package:flutter/foundation.dart';
// Universal developer bypass helper for open-source wallet
// Allows developers to bypass blocking screens and authentication
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeveloperBypass {
  static const String _devModeKey = 'developer_mode_enabled';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Check if developer mode is currently enabled
  static Future<bool> isDeveloperModeEnabled() async {
    try {
      final value = await _storage.read(key: _devModeKey);
      final isEnabled = value == 'true';
      debugPrint('Developer Mode Check: $isEnabled (stored value: $value)');
      // Developer mode is OFF by default - only true if explicitly set
      return isEnabled;
    } catch (e) {
      debugPrint('Developer Mode Check: false (error: $e)');
      // Always return false if there's any error or no value stored
      return false;
    }
  }

  /// Enable or disable developer mode
  static Future<void> setDeveloperMode(bool enabled) async {
    try {
      await _storage.write(key: _devModeKey, value: enabled.toString());
    } catch (e) {
      debugPrint('Error setting developer mode: $e');
    }
  }

  /// Create a universal developer bypass widget
  /// Use this on any blocking screen to allow developers to proceed
  static Widget createBypassToggle({
    required String screenName,
    required VoidCallback onBypass,
    String? customMessage,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        return FutureBuilder<bool>(
          future: isDeveloperModeEnabled(),
          builder: (context, snapshot) {
            final bool isDeveloperMode = snapshot.data ?? false;

            return Card(
              color: Colors.amber.shade50,
              margin: const EdgeInsets.all(16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.developer_mode, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Developer Mode',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
                        Switch(
                          value: isDeveloperMode,
                          onChanged: (value) async {
                            await setDeveloperMode(value);
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      customMessage ??
                      'Bypass $screenName for development and testing. '
                      'This allows you to explore the wallet UI without '
                      'implementing full authentication or validation.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade700,
                      ),
                    ),
                    if (isDeveloperMode) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: onBypass,
                        icon: const Icon(Icons.skip_next),
                        label: Text('Bypass $screenName'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Show a developer bypass dialog
  static void showBypassDialog({
    required BuildContext context,
    required String screenName,
    required VoidCallback onBypass,
    String? customMessage,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.developer_mode, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            const Text('Developer Bypass'),
          ],
        ),
        content: Text(
          customMessage ??
          'Would you like to bypass $screenName? This is intended for '
          'development and testing purposes only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onBypass();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Bypass'),
          ),
        ],
      ),
    );
  }

  /// Simulate successful authentication for developer mode
  static Future<bool> simulateAuth() async {
    if (await isDeveloperModeEnabled()) {
      debugPrint('Developer mode: Simulating successful authentication');
      return true;
    }
    return false;
  }

  /// Simulate successful network call for developer mode
  static Future<Map<String, dynamic>> simulateNetworkCall({
    required String endpoint,
    Map<String, dynamic>? mockResponse,
  }) async {
    if (await isDeveloperModeEnabled()) {
      debugPrint('Developer mode: Simulating network call to $endpoint');
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate delay
      return mockResponse ?? {'success': true, 'data': 'mock_data'};
    }
    throw Exception('Network call not bypassed');
  }

  /// Simulate successful balance check for developer mode
  static Future<String> simulateBalance() async {
    if (await isDeveloperModeEnabled()) {
      debugPrint('Developer mode: Simulating account balance');
      return '1000.50 ACME';
    }
    return '0.00 ACME';
  }
}