// Clean main.dart for Accumulate Lite Wallet - Open Source Core
import 'dart:convert';
import 'dart:typed_data';
import 'package:accumulate_lite_wallet/core/models/local_storage_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Core architecture imports
import 'core/services/service_locator.dart';
import 'core/adapters/flutter_secure_storage_adapter.dart';

// Theme and utilities
import 'shared/themes/app_theme.dart';
import 'shared/utils/developer_bypass.dart';
import 'core/constants/app_constants.dart';

// Storage services
import 'core/services/storage/wallet_storage_service.dart';
import 'core/services/storage/database_helper.dart';
import 'core/services/accumulate_service_facade.dart';
import 'core/services/credits/credit_service.dart';
import 'core/services/balance/balance_aggregation_service.dart';

// Blockchain services
import 'core/services/blockchain/enhanced_accumulate_service.dart';
import 'core/services/crypto/key_management_service.dart';
import 'core/services/transaction/transaction_signing_service.dart';
import 'core/models/accumulate_requests.dart' as accumulate_requests;
import 'package:accumulate_api/accumulate_api.dart';
import 'package:convert/convert.dart';

// Chart widget
import 'widgets/chart_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start the app immediately with a loading screen
  runApp(const AccumulateLiteWalletApp());
}

Future<void> _initializeCoreServices() async {
  try {
    final serviceLocator = ServiceLocator();
    const flutterStorage = FlutterSecureStorage();
    final storageAdapter = FlutterSecureStorageAdapter(flutterStorage);

    // Initialize services synchronously (they are lightweight)
    await serviceLocator.initialize();

    // Initialize wallet storage asynchronously
    final WalletStorageService storageService = WalletStorageService();
    await storageService.initializeStorage();

    debugPrint('Core services and storage initialized successfully');
  } catch (e) {
    debugPrint('Error initializing services: $e');
  }
}

class AccumulateLiteWalletApp extends StatelessWidget {
  const AccumulateLiteWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Accumulate Lite Wallet',
      theme: AppTheme.lightTheme,
      home: const WalletEntryPoint(),
    );
  }
}

/// Entry point for the wallet - developers need to implement authentication
class WalletEntryPoint extends StatefulWidget {
  const WalletEntryPoint({super.key});

  @override
  State<WalletEntryPoint> createState() => _WalletEntryPointState();
}

class _WalletEntryPointState extends State<WalletEntryPoint> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isLoading = true;
  bool _hasUser = false;
  bool _developerMode = false;
  bool _servicesInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize core services first
      await _initializeCoreServices();

      // Then check user status
      await _checkUserStatus();

      setState(() {
        _servicesInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing app: $e');
      setState(() {
        _isLoading = false;
        _servicesInitialized = false;
      });
    }
  }

  Future<void> _checkUserStatus() async {
    try {
      // Check if developer mode is enabled first (cache the result)
      final isDeveloperMode = await DeveloperBypass.isDeveloperModeEnabled();

      // Check if user exists
      final userId = await _secureStorage.read(key: "userId");

      setState(() {
        _hasUser = (userId != null && userId.isNotEmpty) || isDeveloperMode;
        _developerMode = isDeveloperMode;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error checking user status: $e');
      setState(() {
        _hasUser = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_servicesInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing Accumulate Lite Wallet...'),
              SizedBox(height: 8),
              Text(
                'Setting up services and storage',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasUser && !_developerMode) {
      // DEVELOPER TODO: Implement your authentication flow here
      return const DeveloperAuthenticationPlaceholder();
    }

    // User exists OR developer mode enabled, show main wallet interface
    return const BasicWalletInterface();
  }
}

/// Placeholder screen for developers to implement authentication
class DeveloperAuthenticationPlaceholder extends StatelessWidget {
  const DeveloperAuthenticationPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accumulate Open Lite Mobile Wallet'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 32),
            const Text(
              'Welcome to Accumulate Lite Wallet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'This is the open-source core wallet.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEVELOPER TODO:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Implement user authentication\n'
                      '• Add identity generation (mnemonic/keys)\n'
                      '• Create account setup flow\n'
                      '• Connect to your preferred backend\n'
                      '\n'
                      'See docs/ folder for implementation guides.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Core Services Ready:\n'
              '• Blockchain API integration\n'
              '• SQLite database persistence\n'
              '• Flutter Secure Storage\n'
              '• Service dependency injection\n'
              '• Network configuration\n'
              '• Transaction signing & submission\n'
              '• Account & wallet management',
              style: TextStyle(fontSize: 14, color: Colors.green),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Universal developer bypass widget
            DeveloperBypass.createBypassToggle(
              screenName: 'Authentication',
              onBypass: () {
                // Refresh the parent widget to bypass authentication
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const AccumulateLiteWalletApp(),
                  ),
                );
              },
              customMessage: 'Enable developer mode to bypass authentication and '
                  'explore the wallet interface without implementing full auth flow.',
            ),
          ],
        ),
      ),
    );
  }
}

/// Main wallet interface with proper navigation structure
class BasicWalletInterface extends StatefulWidget {
  const BasicWalletInterface({super.key});

  @override
  State<BasicWalletInterface> createState() => _BasicWalletInterfaceState();
}

class _BasicWalletInterfaceState extends State<BasicWalletInterface> {
  int _currentIndex = 0;
  String _selectedNetwork = 'Devnet';

  final List<Widget> _screens = [
    const _HomeScreen(),
    const _CreateScreen(),
    const _SendReceiveScreen(),
    const _DataScreen(),
    const _CreditsScreen(),
    const _SignScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Accumulate Open Lite Wallet'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (String value) {
              switch (value) {
                case 'developer_mode':
                  _showDeveloperMode();
                  break;
                case 'network_endpoint':
                  _showNetworkEndpointModal();
                  break;
                case 'faucet':
                  _showFaucetModal();
                  break;
                case 'reset':
                  _showResetDialog();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'developer_mode',
                child: ListTile(
                  leading: Icon(Icons.developer_mode),
                  title: Text('Developer Mode'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'network_endpoint',
                child: ListTile(
                  leading: Icon(Icons.network_check),
                  title: Text('Network Endpoint'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'faucet',
                child: ListTile(
                  leading: Icon(Icons.water_drop),
                  title: Text('Faucet'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'reset',
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red),
                  title: Text('Reset Wallets and Data', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle),
              label: 'Create',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz),
              label: 'Send/Receive',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storage),
              label: 'Data',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance),
              label: 'Credits',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit),
              label: 'Sign',
            ),
          ],
        ),
      ),
    );
  }

  void _showDeveloperMode() {
    DeveloperBypass.showBypassDialog(
      context: context,
      screenName: 'Main Navigation',
      onBypass: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Developer mode active - All features unlocked'),
            backgroundColor: Colors.amber,
          ),
        );
      },
      customMessage: 'Developer mode is active. All wallet features are available for testing.',
    );
  }

  void _showNetworkEndpointModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String tempSelectedNetwork = _selectedNetwork;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Network Endpoint'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Mainnet'),
                    subtitle: const Text('https://mainnet.accumulatenetwork.io/'),
                    value: 'Mainnet',
                    groupValue: tempSelectedNetwork,
                    onChanged: (String? value) {
                      setState(() {
                        tempSelectedNetwork = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Testnet'),
                    subtitle: const Text('https://testnet.accumulatenetwork.io/'),
                    value: 'Testnet',
                    groupValue: tempSelectedNetwork,
                    onChanged: (String? value) {
                      setState(() {
                        tempSelectedNetwork = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Devnet'),
                    subtitle: const Text('10.0.2.2:26660/v2'),
                    value: 'Devnet',
                    groupValue: tempSelectedNetwork,
                    onChanged: (String? value) {
                      setState(() {
                        tempSelectedNetwork = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    this.setState(() {
                      _selectedNetwork = tempSelectedNetwork;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Network switched to $_selectedNetwork'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFaucetModal() async {
    final WalletStorageService storageService = WalletStorageService();
    final accounts = await storageService.getAllAccountsWithKeyInfo();

    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No accounts found. Create an account first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String? selectedAccountAddress;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Faucet'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Select account to receive test tokens:'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedAccountAddress,
                      hint: const Text('Select Token Account'),
                      isExpanded: true,
                      items: accounts
                          .where((accountInfo) =>
                            accountInfo.account.accountType == 'lite_account' ||
                            accountInfo.account.accountType == 'adi_token_account' ||
                            accountInfo.account.address.endsWith('/ACME'))
                          .map((accountInfo) {
                        return DropdownMenuItem<String>(
                          value: accountInfo.account.address,
                          child: Text(
                            '${accountInfo.account.name} (${AppConstants.formatLiteAccountAddress(accountInfo.account.address)})',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedAccountAddress = value;
                      });
                    },
                  ),
                ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedAccountAddress != null ? () async {
                    // Capture the parent context before closing dialog
                    final parentContext = this.context;

                    // Close dialog first
                    Navigator.of(context).pop();

                    // Show loading indicator on parent scaffold
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Requesting test tokens...'),
                          ],
                        ),
                        backgroundColor: Colors.blue,
                        duration: Duration(seconds: 10),
                      ),
                    );

                    try {
                      debugPrint('Starting faucet request for: $selectedAccountAddress');

                      // Convert to token account address format for faucet
                      String tokenAccountAddress = selectedAccountAddress!;
                      if (!tokenAccountAddress.endsWith('/ACME')) {
                        tokenAccountAddress = '$tokenAccountAddress/ACME';
                      }
                      debugPrint('Using token account address for faucet: $tokenAccountAddress');

                      final facade = AccumulateServiceFacade();
                      await facade.initialize();

                      debugPrint('Calling facade.requestFaucetTokens...');
                      final response = await facade.requestFaucetTokens(
                        accountUrl: tokenAccountAddress,
                        memo: 'Faucet test tokens',
                      );

                      debugPrint('Faucet response: $response');
                      ScaffoldMessenger.of(parentContext).hideCurrentSnackBar();

                      if (response.success) {
                        final accountName = accounts.firstWhere((a) => a.account.address == selectedAccountAddress).account.name;
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                            content: Text('Test tokens successfully added to $accountName!\nTransaction ID: ${response.transactionId}'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                            content: Text('Failed to add test tokens: ${response.error}'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Faucet error: $e');
                      ScaffoldMessenger.of(parentContext).hideCurrentSnackBar();
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text('Error requesting tokens: ${e.toString()}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  } : null,
                  child: const Text('Add Test Tokens'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade700),
              const SizedBox(width: 8),
              const Text('DANGER ZONE'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reset All Wallets and Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This action will PERMANENTLY delete:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• All wallet accounts and keys'),
              const Text('• All transaction history'),
              const Text('• All identities (ADIs)'),
              const Text('• All key books and key pages'),
              const Text('• All data entries'),
              const Text('• All stored metadata'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This action CANNOT be undone!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close current dialog
                await _performWalletReset();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('RESET EVERYTHING'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performWalletReset() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Resetting all wallet data...'),
              Text('Please wait, this may take a moment.'),
            ],
          ),
        );
      },
    );

    try {
      // Initialize services
      final storageService = WalletStorageService();

      // Reset all data
      await storageService.clearAllWalletData();

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text('All wallet data has been reset successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );

      // Note: UI will refresh automatically when user navigates to other screens
      // since they will reload data from the now-empty database

    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Error resetting wallet data: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }
}

class _DemoFeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _DemoFeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

// Actual wallet screens with developer bypass functionality

/// Home screen - Landing page with wallet overview
class _HomeScreen extends StatefulWidget {
  const _HomeScreen();

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  final WalletStorageService _storageService = WalletStorageService();
  final BalanceAggregationService _balanceService = BalanceAggregationService();
  List<WalletAccountInfo> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccountsOptimized();
    // Trigger balance refresh in background to get real balances
    _balanceService.refreshBalancesInBackground();
  }

  Future<void> _loadAccountsOptimized() async {
    try {
      // Load accounts without expensive key checks first for instant UI
      final dbHelper = DatabaseHelper();
      final basicAccounts = await dbHelper.getAllAccounts();

      // Filter and show basic account info immediately
      final filteredBasic = basicAccounts.where((account) {
        final accountType = account.accountType;
        return accountType == 'lite_account' ||
               accountType == 'token_account' ||
               accountType == 'data_account';
      }).toList();

      // Show basic accounts immediately
      if (mounted) {
        setState(() {
          _accounts = filteredBasic.map((account) => WalletAccountInfo(
            account: account,
            hasPrivateKey: false, // Will be updated later
            hasMnemonic: false,   // Will be updated later
          )).toList();
          _isLoading = false;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Get account balance using ACMEClient query
  Future<String> _getAccountBalance(String accountAddress) async {
    try {
      // Always try to get balance for token accounts - the query will determine if it has a balance
      // This handles both lite accounts ending with /ACME and ADI token accounts

      final client = ACMEClient(AppConstants.defaultAccumulateDevnetUrl);
      final response = await client.queryUrl(accountAddress);

      if (response['result'] != null && response['result']['data'] != null) {
        final balance = response['result']['data']['balance'];
        // Convert from raw balance (1e8) to ACME units, default to 0 if null
        final rawBalance = int.tryParse(balance?.toString() ?? '0') ?? 0;
        final acmeBalance = rawBalance / 100000000; // 1e8
        return '${acmeBalance.toStringAsFixed(2)} ACME';
      }
      return '0.00 ACME';
    } catch (e) {
      return '0.00 ACME';
    }
  }


  /// Copy single account address to clipboard
  Future<void> _copyToClipboard(String address) async {
    try {
      await Clipboard.setData(ClipboardData(text: address));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to copy address'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Account Balance Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Account Balance',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          _balanceService.refreshBalancesInBackground();
                          setState(() {}); // Trigger rebuild
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<WalletBalanceSummary>(
                    future: _balanceService.getBalanceSummary(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final summary = snapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${summary.totalBalance.toStringAsFixed(2)} ACME',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '≈ \$${summary.totalUsdValue.toStringAsFixed(2)} USD',
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            if (summary.accountCount > 0)
                              Text(
                                'Across ${summary.accountCount} account${summary.accountCount == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        );
                      }
                      return const Text(
                        'Loading...',
                        style: TextStyle(fontSize: 24),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ACME Price Chart
          const ChartWidget(),
          const SizedBox(height: 16),

          // Accounts Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Accounts',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: _loadAccountsOptimized,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_accounts.isEmpty)
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.account_balance_wallet, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'No accounts created yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            'Use the Create tab to add your first account',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: _accounts.map((accountInfo) {
                        final account = accountInfo.account;
                        final typeLabel = _getAccountTypeLabel(account.accountType);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Icon(_getAccountTypeIcon(account.accountType)),
                            ),
                            title: Text(AppConstants.formatLiteAccountAddress(account.address)),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(typeLabel),
                                // Show balance for token accounts (lite and ADI)
                                if (account.accountType == 'lite_account' ||
                                    account.accountType == 'token_account' ||
                                    account.address.endsWith('/ACME'))
                                  FutureBuilder<String>(
                                    future: _getAccountBalance(account.address),
                                    builder: (context, snapshot) {
                                      final balance = snapshot.data ?? 'Loading...';
                                      if (balance.isNotEmpty && balance != 'Loading...') {
                                        return Text(
                                          balance,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _copyToClipboard(account.address),
                                  icon: const Icon(Icons.copy, size: 16),
                                  tooltip: 'Copy address',
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (accountInfo.hasPrivateKey)
                                      const Icon(Icons.key, size: 16, color: Colors.green),
                                    if (accountInfo.hasMnemonic)
                                      const Icon(Icons.security, size: 16, color: Colors.blue),
                                  ],
                                ),
                              ],
                            ),
                            isThreeLine: false,
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAccountTypeLabel(String accountType) {
    switch (accountType) {
      case 'lite_account':
        return 'Lite Account';
      case 'adi':
        return 'ADI';
      case 'token_account':
        return 'Token Account';
      case 'data_account':
        return 'Data Account';
      default:
        return 'Unknown';
    }
  }

  IconData _getAccountTypeIcon(String accountType) {
    switch (accountType) {
      case 'lite_account':
        return Icons.account_balance_wallet;
      case 'adi':
        return Icons.account_tree;
      case 'token_account':
        return Icons.token;
      case 'data_account':
        return Icons.storage;
      default:
        return Icons.help;
    }
  }
}


class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          if (amount.isNotEmpty)
            Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}

/// Create screen for creating different account types
class _CreateScreen extends StatefulWidget {
  const _CreateScreen();

  @override
  State<_CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<_CreateScreen> {
  String? _selectedAccountType;
  final _nameController = TextEditingController();
  final _adiNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _delegateKeyBookController = TextEditingController();
  final _authorityController = TextEditingController();
  String? _selectedAdi;
  String? _selectedKeyBook;
  String? _selectedKeyPage;
  String? _selectedCreditPayer;
  String? _selectedTokenIssuer;
  String? _selectedTokenAccount;
  String? _selectedAction;
  String? _selectedKeyHashOrDelegate;
  String? _selectedAuthAction;
  bool _canCreate = false;
  bool _isLoading = false;

  List<String> _adiList = [];
  List<String> _keyBookList = [];
  List<String> _keyPageList = [];
  List<String> _creditPayerList = [];
  Map<String, WalletAccount> _creditPayerAccounts = {};
  Map<String, WalletAccount> _adiAccounts = {};
  List<String> _tokenIssuerList = [];
  List<String> _tokenAccountList = [];

  // Lazy loading state tracking
  bool _adiLoaded = false;
  bool _keyBookLoaded = false;
  bool _keyPageLoaded = false;
  bool _creditPayerLoaded = false;
  bool _tokenIssuerLoaded = false;
  bool _tokenAccountLoaded = false;

  // Loading state for individual dropdowns
  bool _adiLoading = false;
  bool _keyBookLoading = false;
  bool _keyPageLoading = false;
  bool _creditPayerLoading = false;
  bool _tokenIssuerLoading = false;
  bool _tokenAccountLoading = false;

  final List<Map<String, String>> _accountTypes = [
    {
      'value': 'lite_account',
      'label': 'Lite Account',
      'description': 'Simple account for basic transactions'
    },
    {
      'value': 'adi',
      'label': 'ADI (Accumulate Digital Identifier)',
      'description': 'Full identity with subdirectories and advanced features'
    },
    {
      'value': 'token_account',
      'label': 'Token Account',
      'description': 'Account specifically for token management'
    },
    {
      'value': 'data_account',
      'label': 'Data Account',
      'description': 'Account for storing and managing data entries'
    },
    {
      'value': 'add_keybook',
      'label': 'Add KeyBook',
      'description': 'Create a new keybook for managing multiple keys'
    },
    {
      'value': 'add_keypage',
      'label': 'Add KeyPage',
      'description': 'Add a new keypage to existing keybook'
    },
    {
      'value': 'custom_token',
      'label': 'Custom Token',
      'description': 'Create a new custom token on the network'
    },
  ];

  @override
  void initState() {
    super.initState();
    // Load critical data immediately for better UX
    _loadCreditPayerData();
  }

  // Lazy loading methods for each dropdown type
  Future<void> _loadAdiData() async {
    if (_adiLoaded || _adiLoading) return;

    setState(() => _adiLoading = true);

    try {
      debugPrint('CREATE SCREEN: Loading ADI data...');
      final storageService = WalletStorageService();
      final accountsWithInfo = await storageService.getAllAccountsWithKeyInfo();
      final accounts = accountsWithInfo.map((info) => info.account).toList();

      // Find ADI accounts from SQLite
      final adiAccounts = accounts.where((acc) => acc.accountType == 'adi').toList();
      debugPrint('CREATE SCREEN: Found ${adiAccounts.length} ADI accounts');

      _adiList = [];
      _adiAccounts = <String, WalletAccount>{};

      for (final account in adiAccounts) {
        final adiName = account.metadata?['adi_name'] ?? account.address;
        debugPrint('   + Adding ADI: $adiName (${account.address})');
        _adiList.add(adiName);
        _adiAccounts[adiName] = account;
      }

      // Fallback to demo data if no ADI accounts found
      if (_adiList.isEmpty) {
        debugPrint('No ADI accounts found, using demo data');
        _adiList = ['demo-adi-1', 'demo-adi-2', 'demo-adi-3'];
      }

      _adiLoaded = true;
      debugPrint('CREATE SCREEN: ADI loading complete. Found ${_adiList.length} ADIs');
    } catch (e) {
      debugPrint('Error loading ADI data: $e');
      _adiList = ['demo-adi-1'];
    } finally {
      if (mounted) setState(() => _adiLoading = false);
    }
  }

  Future<void> _loadKeyBookData() async {
    if (_keyBookLoaded || _keyBookLoading) return;

    setState(() => _keyBookLoading = true);

    try {
      debugPrint('CREATE SCREEN: Loading Key Book data...');
      _keyBookList = [];

      if (_selectedAdi != null && _adiAccounts.containsKey(_selectedAdi!)) {
        // Get the selected ADI account
        final adiAccount = _adiAccounts[_selectedAdi!]!;
        final adiAddress = adiAccount.address;

        // For ADI, the key book URL is typically {adi_url}/book
        final keyBookUrl = '$adiAddress/book';
        debugPrint('CREATE SCREEN: Adding key book for $_selectedAdi: $keyBookUrl');
        _keyBookList.add(keyBookUrl);
      } else {
        debugPrint('No ADI selected or ADI not found, using demo data');
        _keyBookList = ['demo-keybook-1', 'demo-keybook-2'];
      }

      _keyBookLoaded = true;
      debugPrint('CREATE SCREEN: Key Book loading complete. Found ${_keyBookList.length} key books');
    } catch (e) {
      debugPrint('Error loading KeyBook data: $e');
      _keyBookList = ['demo-keybook-1'];
    } finally {
      if (mounted) setState(() => _keyBookLoading = false);
    }
  }

  Future<void> _loadKeyPageData() async {
    if (_keyPageLoaded || _keyPageLoading) return;

    setState(() => _keyPageLoading = true);

    try {
      debugPrint('CREATE SCREEN: Loading Key Page data...');
      final storageService = WalletStorageService();
      final accountsWithInfo = await storageService.getAllAccountsWithKeyInfo();
      final accounts = accountsWithInfo.map((info) => info.account).toList();

      _keyPageList = [];

      if (_selectedKeyBook != null) {
        // Filter key pages by the selected key book
        debugPrint('Filtering key pages for key book: $_selectedKeyBook');

        final keyPageAccounts = accounts.where((acc) =>
          acc.accountType == 'key_page' &&
          acc.address.startsWith(_selectedKeyBook!) // Key pages should start with the key book URL
        ).toList();

        debugPrint('CREATE SCREEN: Found ${keyPageAccounts.length} key pages for selected key book');

        for (final account in keyPageAccounts) {
          final keyPageName = account.metadata?['account_label'] ?? account.address;
          debugPrint('   + Adding key page: $keyPageName (${account.address})');
          _keyPageList.add(account.address); // Use the full address as value
        }

        // If no key pages found for the selected key book, generate the expected key page URL
        if (_keyPageList.isEmpty && _selectedKeyBook!.endsWith('/book')) {
          final expectedKeyPageUrl = '$_selectedKeyBook/1';
          debugPrint('No key pages found, adding expected key page URL: $expectedKeyPageUrl');
          _keyPageList.add(expectedKeyPageUrl);
        }
      } else {
        debugPrint('No key book selected, showing all key pages');
        final keyPageAccounts = accounts.where((acc) => acc.accountType == 'key_page').toList();

        for (final account in keyPageAccounts) {
          final keyPageName = account.metadata?['account_label'] ?? account.address;
          _keyPageList.add(account.address);
        }
      }

      // Fallback to demo data if no key pages found
      if (_keyPageList.isEmpty) {
        debugPrint('No key pages found, using demo data');
        _keyPageList = ['demo-keypage-1', 'demo-keypage-2', 'demo-keypage-3'];
      }

      _keyPageLoaded = true;
      debugPrint('CREATE SCREEN: Key Page loading complete. Found ${_keyPageList.length} key pages');
    } catch (e) {
      debugPrint('Error loading KeyPage data: $e');
      _keyPageList = ['demo-keypage-1'];
    } finally {
      if (mounted) setState(() => _keyPageLoading = false);
    }
  }

  Future<void> _loadCreditPayerData() async {
    if (_creditPayerLoaded || _creditPayerLoading) return;

    setState(() => _creditPayerLoading = true);

    try {
      debugPrint('CREATE SCREEN: Loading Credit Payer data...');
      final storageService = WalletStorageService();
      final accountsWithInfo = await storageService.getAllAccountsWithKeyInfo();
      final accounts = accountsWithInfo.map((info) => info.account).toList();

      debugPrint('CREATE SCREEN: Found ${accounts.length} total accounts in database');
      for (final account in accounts) {
        debugPrint('   - ${account.address} (${account.accountType})');
      }

      final creditPayers = <String>[];
      final creditPayerAccounts = <String, WalletAccount>{};

      // Add lite identities (base addresses without /ACME) that can pay for credits
      final liteIdentities = accounts
          .where((acc) => acc.accountType == 'lite_identity');
      debugPrint('CREATE SCREEN: Found ${liteIdentities.length} lite identities');
      for (final account in liteIdentities) {
        debugPrint('   + Adding lite identity: ${account.address}');
        creditPayers.add(account.address);
        creditPayerAccounts[account.address] = account;
      }

      // Add key pages that can sign and pay for transactions
      final keyPages = accounts
          .where((acc) => acc.accountType?.contains('key') == true || acc.address.contains('/book/'));
      debugPrint('CREATE SCREEN: Found ${keyPages.length} key pages');
      for (final account in keyPages) {
        debugPrint('   + Adding key page: ${account.address}');
        creditPayers.add(account.address);
        creditPayerAccounts[account.address] = account;
      }

      _creditPayerList = creditPayers.isNotEmpty
          ? creditPayers
          : ['demo-lite-account-1', 'demo-lite-account-2'];
      _creditPayerAccounts = creditPayerAccounts;
      _creditPayerLoaded = true;

      debugPrint('CREATE SCREEN: Credit Payer loading complete. Found ${_creditPayerList.length} credit payers');
      if (_creditPayerList.isNotEmpty) {
        debugPrint('   First credit payer: ${_creditPayerList.first}');
      }
    } catch (e) {
      debugPrint('CREATE SCREEN: Error loading Credit Payer data: $e');
      _creditPayerList = ['demo-lite-account-1', 'demo-lite-account-2'];
    } finally {
      if (mounted) setState(() => _creditPayerLoading = false);
    }
  }

  // DEBUG: Method to check credit payer data loading
  void _debugCreditPayerData() async {
    debugPrint('Debug: Credit Payer data check for Create screen');
    debugPrint('   - Loaded: $_creditPayerLoaded');
    debugPrint('   - Loading: $_creditPayerLoading');
    debugPrint('   - List size: ${_creditPayerList.length}');
    debugPrint('   - Accounts size: ${_creditPayerAccounts.length}');

    if (_creditPayerList.isNotEmpty) {
      debugPrint('   - First item: ${_creditPayerList.first}');
    }

    // Force reload for testing
    _creditPayerLoaded = false;
    _creditPayerLoading = false;
    await _loadCreditPayerData();
  }

  Future<void> _loadTokenIssuerData() async {
    if (_tokenIssuerLoaded || _tokenIssuerLoading) return;

    setState(() => _tokenIssuerLoading = true);

    try {
      debugPrint('CREATE SCREEN: Loading Token Issuer data...');
      final storageService = WalletStorageService();
      final accountsWithInfo = await storageService.getAllAccountsWithKeyInfo();
      final accounts = accountsWithInfo.map((info) => info.account).toList();

      // Find custom token accounts that can issue tokens
      final tokenIssuerAccounts = accounts.where((acc) =>
        acc.accountType == 'custom_token' ||
        acc.accountType == 'token_account'
      ).toList();
      debugPrint('CREATE SCREEN: Found ${tokenIssuerAccounts.length} token issuer accounts');

      _tokenIssuerList = [];
      for (final account in tokenIssuerAccounts) {
        final issuerName = account.metadata?['account_label'] ?? account.name ?? account.address;
        debugPrint('   + Adding token issuer: $issuerName (${account.address})');
        _tokenIssuerList.add(account.address); // Use the full address as value
      }

      // Fallback to demo data if no token issuers found
      if (_tokenIssuerList.isEmpty) {
        debugPrint('No token issuers found, using demo data');
        _tokenIssuerList = ['demo-token-issuer-1', 'demo-token-issuer-2'];
      }

      _tokenIssuerLoaded = true;
      debugPrint('CREATE SCREEN: Token Issuer loading complete. Found ${_tokenIssuerList.length} token issuers');
    } catch (e) {
      debugPrint('Error loading Token Issuer data: $e');
      _tokenIssuerList = ['demo-token-issuer-1'];
    } finally {
      if (mounted) setState(() => _tokenIssuerLoading = false);
    }
  }

  Future<void> _loadTokenAccountData() async {
    if (_tokenAccountLoaded || _tokenAccountLoading) return;

    setState(() => _tokenAccountLoading = true);

    try {
      final storageService = WalletStorageService();
      final accountsWithInfo = await storageService.getAllAccountsWithKeyInfo();
      final accounts = accountsWithInfo.map((info) => info.account).toList();

      final tokenAccounts = accounts
          .where((acc) => acc.accountType == 'token_account')
          .map((acc) => acc.name)
          .toList();

      _tokenAccountList = tokenAccounts.isNotEmpty
          ? tokenAccounts
          : ['demo-token-account-1', 'demo-token-account-2'];
      _tokenAccountLoaded = true;
    } catch (e) {
      debugPrint('Error loading Token Account data: $e');
      _tokenAccountList = ['demo-token-account-1', 'demo-token-account-2'];
    } finally {
      if (mounted) setState(() => _tokenAccountLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New Account',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Choose the type of account you want to create on the Accumulate network.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Account Type Dropdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedAccountType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select account type',
                    ),
                    items: _accountTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type['value'],
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: type['label']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              TextSpan(
                                text: '\n${type['description']!}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAccountType = value;
                        // Reset all dynamic fields when account type changes
                        _nameController.clear();
                        _adiNameController.clear();
                        _amountController.clear();
                        _delegateKeyBookController.clear();
                        _authorityController.clear();
                        _selectedAdi = null;
                        _selectedKeyBook = null;
                        _selectedKeyPage = null;
                        _selectedCreditPayer = null;
                        _selectedTokenIssuer = null;
                        _selectedTokenAccount = null;
                        _selectedAction = null;
                        _selectedKeyHashOrDelegate = null;
                        _selectedAuthAction = null;
                        _checkCanCreate();

                        // Auto-load data when account types are selected
                        switch (value) {
                          case 'token_account':
                          case 'data_account':
                          case 'custom_token':
                          case 'add_keybook':
                          case 'add_keypage':
                            debugPrint('Auto-loading dropdowns for account type: $value');
                            _loadAdiData();
                            _loadCreditPayerData();
                            break;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dynamic Fields based on account type
          if (_selectedAccountType != null) ..._buildDynamicFields(),

          if (!_canCreate) ...[
            const Card(
              color: Colors.blue,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.account_tree, color: Colors.white, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Account Creation Blocked',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Account creation requires network connection and identity validation.',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            DeveloperBypass.createBypassToggle(
              screenName: 'Account Creation',
              onBypass: () {
                setState(() {
                  _canCreate = true;
                });
              },
              customMessage: 'Bypass account creation validation for development. '
                  'This simulates successful account creation on the network.',
            ),
          ] else
            ..._buildActionButtons(),
        ],
        ),
      ),
    );
  }

  List<Widget> _buildDynamicFields() {
    if (_selectedAccountType == null) return [];

    switch (_selectedAccountType!) {
      case 'lite_account':
        return [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lite Account Creation',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No additional fields required. The API will generate the address automatically.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ];

      case 'adi':
        return [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ADI Name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _adiNameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter ADI identity name',
                    ),
                    onChanged: (_) => _checkCanCreate(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCreditPayerDropdown(),
          const SizedBox(height: 16),
        ];

      case 'token_account':
      case 'data_account':
        return [
          _buildAdiDropdown(),
          const SizedBox(height: 16),
          _buildKeyBookDropdown(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter account name',
                    ),
                    onChanged: (_) => _checkCanCreate(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCreditPayerDropdown(),
          const SizedBox(height: 16),
        ];

      case 'custom_token':
        return [
          _buildAdiDropdown(),
          const SizedBox(height: 16),
          _buildKeyBookDropdown(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Token Symbol',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter token symbol',
                    ),
                    onChanged: (_) => _checkCanCreate(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCreditPayerDropdown(),
          const SizedBox(height: 16),
        ];

      case 'add_keybook':
        return [
          _buildAdiDropdown(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Key Book Name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter key book name (e.g., "book2", "security-keys")',
                    ),
                    onChanged: (_) => _checkCanCreate(),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The system will automatically append the next available number if needed.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCreditPayerDropdown(),
          const SizedBox(height: 16),
        ];

      case 'add_keypage':
        return [
          _buildAdiDropdown(),
          const SizedBox(height: 16),
          _buildKeyBookDropdown(),
          const SizedBox(height: 16),
          _buildCreditPayerDropdown(),
          const SizedBox(height: 16),
        ];

      case 'update_keypage':
        return [
          _buildAdiDropdown(),
          const SizedBox(height: 16),
          _buildKeyBookDropdown(),
          const SizedBox(height: 16),
          _buildKeyPageDropdown(),
          const SizedBox(height: 16),
          _buildActionDropdown(),
          const SizedBox(height: 16),
          _buildKeyHashOrDelegateDropdown(),
          const SizedBox(height: 16),
          if (_selectedKeyHashOrDelegate == 'delegate') ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delegate KeyBook',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _delegateKeyBookController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter delegate keyBook',
                      ),
                      onChanged: (_) => _checkCanCreate(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildCreditPayerDropdown(),
          const SizedBox(height: 16),
        ];

      case 'update_authority':
        return [
          _buildAdiDropdown(),
          const SizedBox(height: 16),
          _buildAuthActionDropdown(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Authority',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _authorityController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter keyBook URL',
                    ),
                    onChanged: (_) => _checkCanCreate(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCreditPayerDropdown(),
          const SizedBox(height: 16),
        ];

      default:
        return [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter account name',
                    ),
                    onChanged: (_) => _checkCanCreate(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCreditPayerDropdown(),
          const SizedBox(height: 16),
        ];
    }
  }

  Widget _buildAdiDropdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'ADI',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_adiLoading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedAdi,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select ADI',
              ),
              items: _adiLoading
                  ? []
                  : _adiList.map((adi) {
                      return DropdownMenuItem<String>(
                        value: adi,
                        child: Text(adi),
                      );
                    }).toList(),
              onTap: () {
                if (!_adiLoaded && !_adiLoading) {
                  _loadAdiData();
                }
              },
              onChanged: (value) {
                setState(() {
                  _selectedAdi = value;
                  _selectedKeyBook = null; // Reset key book selection
                  _checkCanCreate();

                  // Reload key book data when ADI changes
                  if (value != null) {
                    debugPrint('ADI changed to: $value, reloading Key Book data...');
                    _keyBookLoaded = false; // Force reload
                    _loadKeyBookData();
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyBookDropdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Key Book',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_keyBookLoading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedKeyBook,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select Key Book',
              ),
              items: _keyBookLoading
                  ? []
                  : _keyBookList.map((keyBook) {
                      return DropdownMenuItem<String>(
                        value: keyBook,
                        child: Text(keyBook),
                      );
                    }).toList(),
              onTap: () {
                if (!_keyBookLoaded && !_keyBookLoading) {
                  _loadKeyBookData();
                }
              },
              onChanged: (value) {
                setState(() {
                  _selectedKeyBook = value;
                  _selectedKeyPage = null; // Reset key page selection
                  _checkCanCreate();

                  // Reload key page data when key book changes
                  if (value != null) {
                    debugPrint('Key Book changed to: $value, reloading Key Page data...');
                    _keyPageLoaded = false; // Force reload
                    _loadKeyPageData();
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyPageDropdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Key Page',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_keyPageLoading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedKeyPage,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select Key Page',
              ),
              items: _keyPageLoading
                  ? []
                  : _keyPageList.map((keyPage) {
                      return DropdownMenuItem<String>(
                        value: keyPage,
                        child: Text(keyPage),
                      );
                    }).toList(),
              onTap: () {
                if (!_keyPageLoaded && !_keyPageLoading) {
                  _loadKeyPageData();
                }
              },
              onChanged: (value) {
                setState(() {
                  _selectedKeyPage = value;
                  _checkCanCreate();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditPayerDropdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Credit Payer',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${_creditPayerList.length} items)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (_creditPayerLoading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: () {
                    debugPrint('Manual reload button pressed');
                    _debugCreditPayerData();
                  },
                  child: const Text('Debug', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCreditPayer,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select Credit Payer',
              ),
              isExpanded: true,
              items: _creditPayerLoading
                  ? []
                  : _creditPayerList.map((payer) {
                      final account = _creditPayerAccounts[payer];
                      String displayName;
                      if (account != null) {
                        // Show account name and formatted address
                        displayName = '${account.name} (${AppConstants.formatLiteAccountAddress(payer)})';
                      } else {
                        // Fallback for demo accounts
                        displayName = payer;
                      }
                      return DropdownMenuItem<String>(
                        value: payer,
                        child: Text(
                          displayName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCreditPayer = value;
                  _checkCanCreate();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenIssuerDropdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Token Issuer',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_tokenIssuerLoading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedTokenIssuer,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select Token Issuer',
              ),
              items: _tokenIssuerLoading
                  ? []
                  : _tokenIssuerList.map((issuer) {
                      return DropdownMenuItem<String>(
                        value: issuer,
                        child: Text(issuer),
                      );
                    }).toList(),
              onTap: () {
                if (!_tokenIssuerLoaded && !_tokenIssuerLoading) {
                  _loadTokenIssuerData();
                }
              },
              onChanged: (value) {
                setState(() {
                  _selectedTokenIssuer = value;
                  _checkCanCreate();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenAccountDropdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Token Account',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_tokenAccountLoading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedTokenAccount,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select Token Account',
              ),
              items: _tokenAccountLoading
                  ? []
                  : _tokenAccountList.map((account) {
                      return DropdownMenuItem<String>(
                        value: account,
                        child: Text(account),
                      );
                    }).toList(),
              onTap: () {
                if (!_tokenAccountLoaded && !_tokenAccountLoading) {
                  _loadTokenAccountData();
                }
              },
              onChanged: (value) {
                setState(() {
                  _selectedTokenAccount = value;
                  _checkCanCreate();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionDropdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Action',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedAction,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select Action',
              ),
              items: ['update', 'add', 'remove'].map((action) {
                return DropdownMenuItem<String>(
                  value: action,
                  child: Text(action.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAction = value;
                  _checkCanCreate();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyHashOrDelegateDropdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KeyHash or Delegate',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedKeyHashOrDelegate,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select KeyHash or Delegate',
              ),
              items: ['keyhash', 'delegate'].map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedKeyHashOrDelegate = value;
                  if (value != 'delegate') {
                    _delegateKeyBookController.clear();
                  }
                  _checkCanCreate();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthActionDropdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Authority Action',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedAuthAction,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select Action',
              ),
              items: ['add', 'enable', 'disable'].map((action) {
                return DropdownMenuItem<String>(
                  value: action,
                  child: Text(action.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAuthAction = value;
                  _checkCanCreate();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    if (_selectedAccountType == null) return [];

    switch (_selectedAccountType!) {

      default:
        return [
          ElevatedButton.icon(
            onPressed: () => _performAction('create'),
            icon: const Icon(Icons.add_circle),
            label: const Text('Create'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ];
    }
  }

  Future<void> _createLiteAccount(String action, Map<String, String> accountType, WalletStorageService storageService) async {
    try {
      debugPrint('Starting lite account creation...');

      // Initialize services
      final keyService = KeyManagementService();
      final accumulateService = EnhancedAccumulateService(keyService: keyService);

      // For lite accounts, we can generate keys locally and create without blockchain transaction
      // since lite accounts are derived from public keys
      debugPrint('Generating key pair...');
      final keyPair = await keyService.generateKeyPair();

      // Create LiteIdentity to get the address
      final privateKeyBytes = Uint8List.fromList(hex.decode(keyPair.privateKey));
      final ed25519Signer = Ed25519KeypairSigner.fromKeyRaw(privateKeyBytes);
      final liteIdentity = LiteIdentity(ed25519Signer);
      final baseAddress = liteIdentity.url.toString();
      final address = '$baseAddress/ACME';  // Create lite token account address

      debugPrint('Generated lite token account address: $address');
      debugPrint('Base lite identity address: $baseAddress');
      debugPrint('Public key: ${keyPair.publicKey}');
      debugPrint('Public key hash: ${keyPair.publicKeyHash}');

      // Store the account locally
      // IMPORTANT: Store private key with base lite identity address (without /ACME)
      // because that's what the signer lookup uses
      await storageService.createAccount(
        address: address,  // SQLite stores the full token account address
        accountType: 'lite_account',
        privateKey: keyPair.privateKey,
        publicKey: keyPair.publicKey,
        metadata: {
          'created_by': 'generated_locally',
          'account_label': accountType['label'],
          'action': action,
          'public_key_hash': keyPair.publicKeyHash,
          'base_lite_identity': baseAddress,  // Store base address for credits
        },
      );

      // Also store the private key with the base address for signer lookup
      debugPrint('Storing private key for signer with base address: $baseAddress');
      await storageService.createAccount(
        address: baseAddress,  // Store with base lite identity for signer lookup
        accountType: 'lite_identity',
        privateKey: keyPair.privateKey,
        publicKey: keyPair.publicKey,
        metadata: {
          'created_by': 'generated_locally',
          'account_label': '${accountType['label']} (Base Identity)',
          'action': action,
          'public_key_hash': keyPair.publicKeyHash,
          'is_base_identity': true,
          'token_account': address,  // Reference to the token account
        },
      );

      debugPrint('Lite account created successfully: $address');
    } catch (e) {
      debugPrint('Error creating lite account: $e');
      throw e;
    }
  }

  Future<void> _createAdi(String action, Map<String, String> accountType, WalletStorageService storageService) async {
    try {
      debugPrint('Starting ADI creation...');

      // Validate required inputs
      if (_adiNameController.text.isEmpty) {
        throw Exception('ADI name is required');
      }
      if (_selectedCreditPayer == null) {
        throw Exception('Credit payer is required');
      }

      final adiName = _adiNameController.text.trim();
      debugPrint('ADI Name: $adiName');
      debugPrint('Credit Payer: $_selectedCreditPayer');

      // Initialize services
      final keyService = KeyManagementService();
      final accumulateService = EnhancedAccumulateService(keyService: keyService);
      final client = ACMEClient(accumulateService.baseUrl);

      // Generate ADI keypair
      debugPrint('Generating ADI keypair...');
      final adiKeyPair = await keyService.generateKeyPair();
      final adiPrivateKeyBytes = Uint8List.fromList(hex.decode(adiKeyPair.privateKey));
      final adiSigner = Ed25519KeypairSigner.fromKeyRaw(adiPrivateKeyBytes);

      // Create lite identity signer for the credit payer
      debugPrint('Creating signer for credit payer: $_selectedCreditPayer');
      final payerSigner = await _createPayerSigner(keyService, _selectedCreditPayer!);
      if (payerSigner == null) {
        throw Exception('Unable to create signer for credit payer: $_selectedCreditPayer');
      }

      // Construct ADI URLs
      final identityUrl = "acc://$adiName.acme";
      final bookUrl = "$identityUrl/book";
      final keyPageUrl = "$identityUrl/book/1";

      debugPrint('Identity URL: $identityUrl');
      debugPrint('Key Book URL: $bookUrl');
      debugPrint('Key Page URL: $keyPageUrl');

      // Create CreateIdentityParam
      final createIdentityParam = CreateIdentityParam();
      createIdentityParam.url = identityUrl;
      createIdentityParam.keyBookUrl = bookUrl;
      createIdentityParam.keyHash = adiSigner.publicKeyHash();

      debugPrint('Creating ADI on blockchain...');
      debugPrint('Sending createIdentity transaction...');

      // Execute the createIdentity transaction
      final response = await client.createIdentity(
        payerSigner.url.toString(),
        createIdentityParam,
        payerSigner,
      );

      debugPrint('Create ADI response: $response');

      // Parse the response
      final result = response['result'];
      if (result == null) {
        final errorMsg = response['error']?['message'] ?? 'Unknown error creating ADI';
        throw Exception('ADI creation failed: $errorMsg');
      }

      final txId = result['txid'];
      if (txId == null) {
        throw Exception('No transaction ID returned from ADI creation');
      }

      debugPrint('ADI creation transaction submitted: $txId');

      // Store the ADI information locally
      debugPrint('Storing ADI information locally...');
      await storageService.createAccount(
        address: identityUrl,
        accountType: 'adi',
        metadata: {
          'created_by': 'blockchain_transaction',
          'account_label': accountType['label'],
          'action': action,
          'adi_name': adiName,
          'identity_url': identityUrl,
          'key_book_url': bookUrl,
          'key_page_url': keyPageUrl,
          'transaction_id': txId.toString(),
          'credit_payer': _selectedCreditPayer,
          'creation_timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Store the ADI key page information
      await storageService.createAccount(
        address: keyPageUrl,
        accountType: 'key_page',
        privateKey: adiKeyPair.privateKey,
        publicKey: adiKeyPair.publicKey,
        metadata: {
          'created_by': 'blockchain_transaction',
          'account_label': '$adiName Key Page 1',
          'action': action,
          'adi_identity': identityUrl,
          'key_page_url': keyPageUrl,
          'key_book_url': bookUrl,
          'public_key_hash': adiKeyPair.publicKeyHash,
          'transaction_id': txId.toString(),
          'is_key_page': true,
        },
      );

      debugPrint('ADI created successfully: $identityUrl');
      debugPrint('Key page created: $keyPageUrl');
      debugPrint('Transaction ID: $txId');

      // Wait a moment for transaction to propagate
      await Future.delayed(const Duration(seconds: 2));

      // Query transaction status
      try {
        debugPrint('Checking transaction status...');
        final txStatus = await client.queryTx(txId.toString());
        final status = txStatus['result']?['status'];
        debugPrint('Transaction status: $status');
      } catch (e) {
        debugPrint('Could not query transaction status: $e');
      }

    } catch (e) {
      debugPrint('Error creating ADI: $e');
      throw e;
    }
  }

  Future<void> _createDataAccount(String action, Map<String, String> accountType, WalletStorageService storageService) async {
    try {
      debugPrint('Starting data account creation...');

      // Validate required inputs
      if (_selectedAdi == null) {
        throw Exception('ADI is required for data account creation');
      }
      if (_selectedKeyBook == null) {
        throw Exception('Key Book is required for data account creation');
      }
      if (_nameController.text.isEmpty) {
        throw Exception('Account name is required for data account creation');
      }
      if (_selectedCreditPayer == null) {
        throw Exception('Credit payer is required');
      }

      final dataAccountName = _nameController.text.trim();
      debugPrint('Data Account Name: $dataAccountName');
      debugPrint('Selected ADI: $_selectedAdi');
      debugPrint('Selected Key Book: $_selectedKeyBook');
      debugPrint('Credit Payer: $_selectedCreditPayer');

      // Get the ADI account information
      final adiAccount = _adiAccounts[_selectedAdi!];
      if (adiAccount == null) {
        throw Exception('Selected ADI not found in accounts');
      }

      final identityUrl = adiAccount.address; // e.g., acc://testtesttest1.acme
      final keyPageUrl = '$_selectedKeyBook/1'; // e.g., acc://testtesttest1.acme/book/1
      final dataAccountUrl = '$identityUrl/$dataAccountName'; // e.g., acc://testtesttest1.acme/data1

      debugPrint('Identity URL: $identityUrl');
      debugPrint('Key Page URL: $keyPageUrl');
      debugPrint('Data Account URL: $dataAccountUrl');

      // Initialize services
      final keyService = KeyManagementService();
      final accumulateService = EnhancedAccumulateService(keyService: keyService);
      final client = ACMEClient(accumulateService.baseUrl);

      // Get the ADI signer (need the private key from the key page)
      debugPrint('Creating ADI signer for key page: $keyPageUrl');

      // Debug: Check what accounts exist in storage
      debugPrint('DEBUG: Checking all accounts in storage...');
      final allAccountsWithInfo = await storageService.getAllAccountsWithKeyInfo();
      for (final accountInfo in allAccountsWithInfo) {
        final account = accountInfo.account;
        debugPrint('   Account: ${account.address} (${account.accountType}) - HasPrivateKey: ${accountInfo.hasPrivateKey}');
      }

      // Debug: Check secure storage directly for the key page
      debugPrint('DEBUG: Checking secure storage for key page...');
      await keyService.debugAccountKeys(keyPageUrl);

      // Also check if the key exists in the database tables
      debugPrint('DEBUG: Checking database for key page entry...');
      final keyPageAccount = allAccountsWithInfo.firstWhere(
        (info) => info.account.address == keyPageUrl,
        orElse: () => throw Exception('Key page not found in database: $keyPageUrl'),
      );
      debugPrint('   Found key page in database: ${keyPageAccount.account.address}');
      debugPrint('   Metadata: ${keyPageAccount.account.metadata}');

      final adiSigner = await keyService.createADISigner(keyPageUrl);
      if (adiSigner == null) {
        throw Exception('Unable to create ADI signer for key page: $keyPageUrl - Check logs above for key storage details');
      }

      debugPrint('ADI signer created successfully for key page: $keyPageUrl');

      // Create data account parameters
      final dataAccountParams = CreateDataAccountParam();
      dataAccountParams.url = dataAccountUrl;

      debugPrint('Creating data account on blockchain...');
      debugPrint('Sending createDataAccount transaction...');

      // Execute the createDataAccount transaction
      final response = await client.createDataAccount(
        identityUrl,
        dataAccountParams,
        adiSigner,
      );

      debugPrint('Create data account response: $response');

      // Parse the response
      final result = response['result'];
      if (result == null) {
        final errorMsg = response['error']?['message'] ?? 'Unknown error creating data account';
        throw Exception('Data account creation failed: $errorMsg');
      }

      final txId = result['txid'];
      if (txId == null) {
        throw Exception('No transaction ID returned from data account creation');
      }

      debugPrint('Data account creation transaction submitted: $txId');

      // Store the data account information locally
      debugPrint('Storing data account information locally...');
      await storageService.createAccount(
        address: dataAccountUrl,
        accountType: 'data_account',
        metadata: {
          'created_by': 'blockchain_transaction',
          'account_label': accountType['label'],
          'action': action,
          'data_account_name': dataAccountName,
          'identity_url': identityUrl,
          'key_book_url': _selectedKeyBook,
          'key_page_url': keyPageUrl,
          'transaction_id': txId.toString(),
          'credit_payer': _selectedCreditPayer,
          'adi_name': _selectedAdi,
          'creation_timestamp': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('Data account created successfully: $dataAccountUrl');
      debugPrint('Transaction ID: $txId');

      // Wait a moment for transaction to propagate
      await Future.delayed(const Duration(seconds: 2));

      // Query transaction status
      try {
        debugPrint('Checking transaction status...');
        final txStatus = await client.queryTx(txId.toString());
        final status = txStatus['result']?['status'];
        debugPrint('Transaction status: $status');
      } catch (e) {
        debugPrint('Could not query transaction status: $e');
      }

    } catch (e) {
      debugPrint('Error creating data account: $e');
      throw e;
    }
  }

  Future<void> _createTokenAccount(String action, Map<String, String> accountType, WalletStorageService storageService) async {
    try {
      debugPrint('Starting token account creation...');

      // Validate required inputs
      if (_selectedAdi == null) {
        throw Exception('ADI is required for token account creation');
      }
      if (_selectedKeyBook == null) {
        throw Exception('Key Book is required for token account creation');
      }
      if (_nameController.text.isEmpty) {
        throw Exception('Account name is required for token account creation');
      }
      if (_selectedCreditPayer == null) {
        throw Exception('Credit payer is required');
      }

      final tokenAccountName = _nameController.text.trim();
      debugPrint('Token Account Name: $tokenAccountName');
      debugPrint('Selected ADI: $_selectedAdi');
      debugPrint('Selected Key Book: $_selectedKeyBook');
      debugPrint('Credit Payer: $_selectedCreditPayer');

      // Get the ADI account information
      final adiAccount = _adiAccounts[_selectedAdi!];
      if (adiAccount == null) {
        throw Exception('Selected ADI not found in accounts');
      }
      final identityUrl = adiAccount.address; // e.g., acc://testtesttest1.acme

      // Construct key page URL
      final keyPageUrl = '$_selectedKeyBook/1'; // e.g., acc://testtesttest1.acme/book/1
      debugPrint('Key Page URL: $keyPageUrl');

      // Initialize services
      final keyService = KeyManagementService();
      final facade = AccumulateServiceFacade();
      await facade.initialize();

      // Create token account on blockchain
      debugPrint('Creating token account on blockchain...');
      final response = await facade.createADITokenAccount(
        accountName: tokenAccountName,
        identityUrl: identityUrl,
        keyPageUrl: keyPageUrl,
      );

      if (response.success) {
        debugPrint('Token account created successfully!');
        debugPrint('Transaction ID: ${response.transactionId}');

        // The account is already stored by the facade, so we're done
        debugPrint('Token account stored in local database');
      } else {
        throw Exception(response.error ?? 'Unknown error creating token account');
      }

      // Optional: Query transaction status
      try {
        await Future.delayed(const Duration(seconds: 2));
        // Could add transaction status check here if needed
      } catch (e) {
        debugPrint('Could not query transaction status: $e');
      }
    } catch (e) {
      debugPrint('Error creating token account: $e');
      throw e;
    }
  }

  Future<void> _createKeyBook(String action, Map<String, String> accountType, WalletStorageService storageService) async {
    try {
      debugPrint('Starting key book creation...');

      // Validate required inputs
      if (_selectedAdi == null) {
        throw Exception('ADI is required for key book creation');
      }
      if (_nameController.text.isEmpty) {
        throw Exception('Key book name is required');
      }
      if (_selectedCreditPayer == null) {
        throw Exception('Credit payer is required');
      }

      final keyBookName = _nameController.text.trim();
      debugPrint('Key Book Name: $keyBookName');
      debugPrint('Selected ADI: $_selectedAdi');
      debugPrint('Credit Payer: $_selectedCreditPayer');

      // Get the ADI account information
      final adiAccount = _adiAccounts[_selectedAdi!];
      if (adiAccount == null) {
        throw Exception('Selected ADI not found in accounts');
      }
      final identityUrl = adiAccount.address; // e.g., acc://testtesttest1.acme

      // Generate new key pair for the key book's first key page
      final keyService = KeyManagementService();
      final keyPair = await keyService.generateKeyPair();
      debugPrint('Generated key pair for key book');
      debugPrint('Public key hash: ${keyPair.publicKeyHash}');

      // Construct key book URL
      final keyBookUrl = '$identityUrl/$keyBookName';
      debugPrint('Key Book URL: $keyBookUrl');

      // Construct key page URL for signing (use existing book/1)
      final signerKeyPageUrl = '$identityUrl/book/1';
      debugPrint('Signer Key Page URL: $signerKeyPageUrl');

      // Initialize services
      final facade = AccumulateServiceFacade();
      await facade.initialize();

      // Create key book on blockchain
      debugPrint('Creating key book on blockchain...');
      final response = await facade.createKeyBook(
        keyBookName: keyBookName,
        identityUrl: identityUrl,
        keyPageUrl: signerKeyPageUrl,
      );

      if (response.success) {
        debugPrint('Key book created successfully!');
        debugPrint('Transaction ID: ${response.transactionId}');

        // Now create the first key page for this key book
        debugPrint('Creating first key page for key book...');

        // Store the key for the new key page in secure storage
        final firstKeyPageUrl = '$keyBookUrl/1';
        await keyService.storeLiteAccountKey(firstKeyPageUrl, keyPair.privateKey);
        debugPrint('Stored key for first key page: $firstKeyPageUrl');

        // Create the first key page
        final keyPageResponse = await facade.createKeyPage(
          keyPageName: '1',
          keyBookUrl: keyBookUrl,
          signerKeyPageUrl: signerKeyPageUrl,
          additionalKeys: [keyPair.publicKeyHash],
        );

        if (keyPageResponse.success) {
          debugPrint('First key page created successfully!');
          debugPrint('Key page transaction ID: ${keyPageResponse.transactionId}');
        } else {
          debugPrint('Key book created but key page failed: ${keyPageResponse.error}');
        }

      } else {
        throw Exception(response.error ?? 'Unknown error creating key book');
      }

      // Optional: Query transaction status
      try {
        await Future.delayed(const Duration(seconds: 2));
        // Could add transaction status check here if needed
      } catch (e) {
        debugPrint('Could not query transaction status: $e');
      }
    } catch (e) {
      debugPrint('Error creating key book: $e');
      throw e;
    }
  }

  Future<void> _createKeyPage(String action, Map<String, String> accountType, WalletStorageService storageService) async {
    try {
      debugPrint('Starting key page creation...');

      // Validate required inputs
      if (_selectedAdi == null) {
        throw Exception('ADI is required for key page creation');
      }
      if (_selectedKeyBook == null) {
        throw Exception('Key Book is required for key page creation');
      }
      if (_selectedCreditPayer == null) {
        throw Exception('Credit payer is required');
      }

      debugPrint('Selected ADI: $_selectedAdi');
      debugPrint('Selected Key Book: $_selectedKeyBook');
      debugPrint('Credit Payer: $_selectedCreditPayer');

      // Get the ADI account information
      final adiAccount = _adiAccounts[_selectedAdi!];
      if (adiAccount == null) {
        throw Exception('Selected ADI not found in accounts');
      }

      // Generate new key pair for the new key page
      final keyService = KeyManagementService();
      final keyPair = await keyService.generateKeyPair();
      debugPrint('Generated key pair for new key page');
      debugPrint('Public key hash: ${keyPair.publicKeyHash}');

      // Query existing key pages to determine next page number (like SDK example)
      final nextPageNumber = await _getNextKeyPageNumber(_selectedKeyBook!);
      final newKeyPageUrl = '$_selectedKeyBook/$nextPageNumber';
      debugPrint('New Key Page URL: $newKeyPageUrl');

      // Construct signing key page URL (use book/1)
      final signerKeyPageUrl = '${adiAccount.address}/book/1';
      debugPrint('Signer Key Page URL: $signerKeyPageUrl');

      // Store the key for the new key page in secure storage
      await keyService.storeLiteAccountKey(newKeyPageUrl, keyPair.privateKey);
      debugPrint('Stored key for new key page: $newKeyPageUrl');

      // Initialize services
      final facade = AccumulateServiceFacade();
      await facade.initialize();

      // Create key page on blockchain
      debugPrint('Creating key page on blockchain...');
      final response = await facade.createKeyPage(
        keyPageName: nextPageNumber.toString(),
        keyBookUrl: _selectedKeyBook!,
        signerKeyPageUrl: signerKeyPageUrl,
        additionalKeys: [keyPair.publicKeyHash],
      );

      if (response.success) {
        debugPrint('Key page created successfully!');
        debugPrint('Transaction ID: ${response.transactionId}');
      } else {
        throw Exception(response.error ?? 'Unknown error creating key page');
      }

      // Optional: Query transaction status
      try {
        await Future.delayed(const Duration(seconds: 2));
        // Could add transaction status check here if needed
      } catch (e) {
        debugPrint('Could not query transaction status: $e');
      }
    } catch (e) {
      debugPrint('Error creating key page: $e');
      throw e;
    }
  }

  Future<void> _createCustomToken(String action, Map<String, String> accountType, WalletStorageService storageService) async {
    try {
      debugPrint('Starting custom token creation...');

      // Validate required inputs
      if (_selectedAdi == null) {
        throw Exception('ADI is required for custom token creation');
      }
      if (_selectedKeyBook == null) {
        throw Exception('Key Book is required for custom token creation');
      }
      if (_nameController.text.isEmpty) {
        throw Exception('Token symbol is required for custom token creation');
      }
      if (_selectedCreditPayer == null) {
        throw Exception('Credit payer is required');
      }

      final tokenSymbol = _nameController.text.trim().toUpperCase();
      debugPrint('Token Symbol: $tokenSymbol');
      debugPrint('Selected ADI: $_selectedAdi');
      debugPrint('Selected Key Book: $_selectedKeyBook');
      debugPrint('Credit Payer: $_selectedCreditPayer');

      // Get the ADI account information
      final adiAccount = _adiAccounts[_selectedAdi!];
      if (adiAccount == null) {
        throw Exception('Selected ADI not found in accounts');
      }
      final identityUrl = adiAccount.address; // e.g., acc://testtesttest1.acme

      // Construct token URL: acc://testtesttest1.acme/CTKN1
      final tokenUrl = '$identityUrl/$tokenSymbol';
      debugPrint('Token URL: $tokenUrl');

      // Construct key page URL for signing
      final keyPageUrl = '$_selectedKeyBook/1';
      debugPrint('Key Page URL: $keyPageUrl');

      // Initialize services
      final keyService = KeyManagementService();
      final facade = AccumulateServiceFacade();
      await facade.initialize();

      // Create custom token on blockchain
      debugPrint('Creating custom token on blockchain...');
      final response = await facade.createCustomToken(
        tokenName: tokenSymbol, // Use symbol as name for simplicity
        tokenSymbol: tokenSymbol,
        identityUrl: identityUrl,
        keyPageUrl: keyPageUrl,
        precision: 6, // Hardcoded e6 precision
      );

      if (response.success) {
        debugPrint('Custom token created successfully!');
        debugPrint('Transaction ID: ${response.transactionId}');

        // The token is already stored by the facade, so we're done
        debugPrint('Custom token stored in local database');
      } else {
        throw Exception(response.error ?? 'Unknown error creating custom token');
      }

      // Optional: Query transaction status
      try {
        await Future.delayed(const Duration(seconds: 2));
        // Could add transaction status check here if needed
      } catch (e) {
        debugPrint('Could not query transaction status: $e');
      }
    } catch (e) {
      debugPrint('Error creating custom token: $e');
      throw e;
    }
  }

  /// Get the next available key page number for a key book (based on SDK example)
  Future<int> _getNextKeyPageNumber(String keyBookUrl) async {
    try {
      debugPrint('Querying existing key pages for: $keyBookUrl');

      // Initialize accumulate client
      final keyService = KeyManagementService();
      final accumulateService = EnhancedAccumulateService(keyService: keyService);

      // Use the same client as the enhanced service
      final client = ACMEClient(AppConstants.defaultAccumulateDevnetUrl);

      // Query directory to get existing key pages
      final qp = QueryPagination()
        ..start = 0
        ..count = 100;

      debugPrint('Querying directory for key book: $keyBookUrl');
      final response = await client.queryDirectory(keyBookUrl, qp, null);
      debugPrint('Directory query response: $response');

      // Parse the response to find existing key pages
      if (response['result'] != null && response['result']['items'] != null) {
        final items = response['result']['items'] as List<dynamic>;
        debugPrint('Found ${items.length} items in key book');

        if (items.isEmpty) {
          debugPrint('No existing key pages found, starting with page 1');
          return 1;
        }

        // Find the highest page number
        int highestPageNumber = 0;
        for (final item in items) {
          if (item is String) {
            // Extract page number from URL like "acc://testtesttest1.acme/book/2"
            final parts = item.split('/');
            if (parts.isNotEmpty) {
              final pageNumberStr = parts.last;
              final pageNumber = int.tryParse(pageNumberStr) ?? 0;
              if (pageNumber > highestPageNumber) {
                highestPageNumber = pageNumber;
              }
            }
          }
        }

        final nextPageNumber = highestPageNumber + 1;
        debugPrint('Highest existing page: $highestPageNumber, next page: $nextPageNumber');
        return nextPageNumber;
      }

      debugPrint('No items found in response, starting with page 1');
      return 1;

    } catch (e) {
      debugPrint('Error querying key pages, defaulting to page 2: $e');
      return 2; // Safe fallback
    }
  }

  Future<dynamic> _createPayerSigner(KeyManagementService keyService, String payerAddress) async {
    try {
      if (payerAddress.contains('.acme')) {
        // ADI account - use key page signer
        final keyPageUrl = payerAddress.contains('/book/')
            ? payerAddress
            : '${payerAddress.replaceAll('/ACME', '')}/book/1';
        debugPrint('Creating ADI signer for key page: $keyPageUrl');
        return await keyService.createADISigner(keyPageUrl);
      } else {
        // Lite account - use lite identity signer
        // Extract base lite identity from token account URL if needed
        String baseLiteIdentity = payerAddress;
        if (payerAddress.endsWith('/ACME')) {
          baseLiteIdentity = payerAddress.substring(0, payerAddress.length - 5);
        }

        debugPrint('Creating lite identity signer for: $baseLiteIdentity');
        final liteIdentity = await keyService.createLiteIdentitySigner(baseLiteIdentity);

        if (liteIdentity == null) {
          debugPrint('No private key found for lite identity: $baseLiteIdentity');
          return null;
        }

        return liteIdentity;
      }
    } catch (e) {
      debugPrint('Error creating payer signer: $e');
      return null;
    }
  }

  Future<void> _performAction(String action) async {
    final accountType = _accountTypes.firstWhere(
      (type) => type['value'] == _selectedAccountType,
    );

    try {
      final storageService = WalletStorageService();

      if (_selectedAccountType == 'lite_account') {
        // For lite accounts, generate new keys and create on blockchain
        await _createLiteAccount(action, accountType, storageService);
      } else if (_selectedAccountType == 'adi') {
        // For ADI accounts, create real ADI on blockchain
        await _createAdi(action, accountType, storageService);
      } else if (_selectedAccountType == 'data_account') {
        // For data accounts, create real data account on blockchain
        await _createDataAccount(action, accountType, storageService);
      } else if (_selectedAccountType == 'token_account') {
        // For token accounts, create real token account on blockchain
        await _createTokenAccount(action, accountType, storageService);
      } else if (_selectedAccountType == 'add_keybook') {
        // For key books, create real key book on blockchain
        await _createKeyBook(action, accountType, storageService);
      } else if (_selectedAccountType == 'add_keypage') {
        // For key pages, create real key page on blockchain
        await _createKeyPage(action, accountType, storageService);
      } else if (_selectedAccountType == 'custom_token') {
        // For custom tokens, create real token issuer on blockchain
        await _createCustomToken(action, accountType, storageService);
      } else {
        // For other account types, use the existing demo logic
        final address = 'acc://${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';

        await storageService.createAccount(
          address: address,
          accountType: _selectedAccountType!,
          // In developer mode, generate demo keys
          privateKey: 'demo_private_key_${address}',
          publicKey: 'demo_public_key_${address}',
        metadata: {
          'created_by': 'developer_mode',
          'account_label': accountType['label'],
          'action': action,
          'adi': _selectedAdi,
          'keybook': _selectedKeyBook,
          'keypage': _selectedKeyPage,
          'credit_payer': _selectedCreditPayer,
          'token_issuer': _selectedTokenIssuer,
          'token_account': _selectedTokenAccount,
          'amount': _amountController.text,
          'update_action': _selectedAction,
          'keyhash_or_delegate': _selectedKeyHashOrDelegate,
          'delegate_keybook': _delegateKeyBookController.text,
          'auth_action': _selectedAuthAction,
          'authority': _authorityController.text,
        },
      );
      }

      String message = '${accountType['label']} ${action}d successfully!';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      setState(() {
        _selectedAccountType = null;
        _nameController.clear();
        _adiNameController.clear();
        _amountController.clear();
        _delegateKeyBookController.clear();
        _authorityController.clear();
        _selectedAdi = null;
        _selectedKeyBook = null;
        _selectedKeyPage = null;
        _selectedCreditPayer = null;
        _selectedTokenIssuer = null;
        _selectedTokenAccount = null;
        _selectedAction = null;
        _selectedKeyHashOrDelegate = null;
        _selectedAuthAction = null;
        _canCreate = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error ${action}ing account: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _checkCanCreate() {
    setState(() {
      if (_selectedAccountType == null) {
        _canCreate = false;
        return;
      }

      switch (_selectedAccountType!) {
        case 'lite_account':
          _canCreate = true; // No additional fields required
          break;
        case 'adi':
          _canCreate = _adiNameController.text.isNotEmpty && _selectedCreditPayer != null;
          break;
        case 'token_account':
        case 'data_account':
        case 'custom_token':
          _canCreate = _selectedAdi != null &&
                      _selectedKeyBook != null &&
                      _nameController.text.isNotEmpty &&
                      _selectedCreditPayer != null;
          break;
        case 'add_keybook':
          _canCreate = _selectedAdi != null &&
                      _nameController.text.isNotEmpty &&
                      _selectedCreditPayer != null;
          break;
        case 'add_keypage':
          _canCreate = _selectedAdi != null &&
                      _selectedKeyBook != null &&
                      _selectedCreditPayer != null;
          break;
        case 'update_keypage':
          _canCreate = _selectedAdi != null &&
                      _selectedKeyBook != null &&
                      _selectedKeyPage != null &&
                      _selectedAction != null &&
                      _selectedKeyHashOrDelegate != null &&
                      (_selectedKeyHashOrDelegate != 'delegate' || _delegateKeyBookController.text.isNotEmpty) &&
                      _selectedCreditPayer != null;
          break;
        case 'update_authority':
          _canCreate = _selectedAdi != null &&
                      _selectedAuthAction != null &&
                      _authorityController.text.isNotEmpty &&
                      _selectedCreditPayer != null;
          break;
        default:
          _canCreate = _nameController.text.isNotEmpty && _selectedCreditPayer != null;
          break;
      }
    });
  }
}

/// Purchase Credits Widget for buying credits with ACME
class _PurchaseCreditsWidget extends StatefulWidget {
  const _PurchaseCreditsWidget();

  @override
  State<_PurchaseCreditsWidget> createState() => _PurchaseCreditsWidgetState();
}

class _PurchaseCreditsWidgetState extends State<_PurchaseCreditsWidget> {
  final _formKey = GlobalKey<FormState>();
  final _creditAmountController = TextEditingController();

  String? _selectedCreditAccount;
  String? _selectedACMEPayer;
  List<Map<String, dynamic>> _creditAccounts = [];
  List<Map<String, dynamic>> _acmePayerAccounts = [];

  bool _isLoading = false;
  bool _isCalculating = false;
  int? _oracleValue;
  Map<String, dynamic>? _costCalculation;

  // Credit service for real RPC calls
  late CreditService _creditService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadAccountsOptimized();
    _loadOracleValue();
  }

  void _initializeServices() {
    // Initialize services for credit operations
    final dbHelper = DatabaseHelper();
    final keyService = KeyManagementService();
    final accumulateService = EnhancedAccumulateService(keyService: keyService);

    _creditService = CreditService(
      dbHelper: dbHelper,
      keyService: keyService,
      accumulateService: accumulateService,
    );
  }

  Future<void> _loadAccountsOptimized() async {
    setState(() => _isLoading = true);

    try {
      // Load accounts without expensive key checks first for instant UI
      final dbHelper = DatabaseHelper();
      final basicAccounts = await dbHelper.getAllAccounts();
      _creditAccounts = [];

      // Add lite accounts (base identity without /ACME)
      for (final account in basicAccounts) {
        if (account.address.contains('/ACME')) {
          // Remove /ACME suffix for lite accounts
          final baseAddress = account.address.substring(0, account.address.length - 5);
          _creditAccounts.add({
            'name': account.name,
            'url': baseAddress,
            'accountType': 'lite_account',
            'displayName': '${account.name} (${AppConstants.formatLiteAccountAddress(baseAddress)})',
          });
        }
      }

      // Add key pages from stored ADI accounts
      for (final account in basicAccounts) {
        if (account.accountType == 'key_page') {
          // This is a key page we can add credits to
          final keyPageName = account.metadata?['account_label'] ?? 'Unknown Key Page';
          _creditAccounts.add({
            'name': keyPageName,
            'url': account.address,
            'accountType': 'key_page',
            'displayName': '$keyPageName (${AppConstants.formatLiteAccountAddress(account.address)})',
          });
        }
      }

      // Load all token accounts for ACME Payer dropdown
      _acmePayerAccounts = [];

      // Add lite token accounts
      for (final account in basicAccounts) {
        if (account.address.contains('/ACME')) {
          _acmePayerAccounts.add({
            'name': account.name,
            'url': account.address,
            'accountType': 'lite_token_account',
            'displayName': '${account.name} (${AppConstants.formatLiteAccountAddress(account.address)})',
          });
        }
      }

      // Add actual ADI token accounts (not fake ones!)
      // Only include accounts that are actually token accounts on the blockchain
      for (final account in basicAccounts) {
        if (account.accountType == 'adi_token_account') {
          // This is an actual ADI token account that exists on the blockchain
          final tokenName = account.metadata?['token_name'] ?? 'ACME';
          final adiName = account.metadata?['adi_name'] ?? 'Unknown ADI';
          _acmePayerAccounts.add({
            'name': adiName,
            'url': account.address,
            'accountType': 'adi_token_account',
            'displayName': '$adiName $tokenName (${AppConstants.formatLiteAccountAddress(account.address)})',
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading accounts: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOracleValue() async {
    try {
      debugPrint('Loading oracle value from network...');
      _oracleValue = await _creditService.getCurrentOracleValue();
      debugPrint('Oracle value loaded: $_oracleValue');
    } catch (e) {
      debugPrint('Error loading oracle value: $e');
      _oracleValue = 1000000; // Fallback value
    }
  }

  Future<void> _calculateCost() async {
    if (_creditAmountController.text.isEmpty || _oracleValue == null) return;

    setState(() => _isCalculating = true);

    try {
      final creditAmount = int.tryParse(_creditAmountController.text);
      if (creditAmount != null && creditAmount > 0) {
        // Calculate ACME cost: (creditAmount * 100 * 10^8) / oracleValue
        final acmeCost = (creditAmount * 100 * 100000000) ~/ _oracleValue!;
        final acmeCostFormatted = (acmeCost / 100000000).toStringAsFixed(8);

        setState(() {
          _costCalculation = {
            'creditAmount': creditAmount,
            'acmeCost': acmeCost,
            'acmeCostFormatted': acmeCostFormatted,
            'oracleValue': _oracleValue,
            'costPerCredit': acmeCost / creditAmount,
          };
        });
      }
    } catch (e) {
      debugPrint('Error calculating cost: $e');
    } finally {
      setState(() => _isCalculating = false);
    }
  }

  Future<void> _purchaseCredits() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate selections
    if (_selectedCreditAccount == null || _selectedACMEPayer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both recipient and payer accounts'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final creditAmount = int.parse(_creditAmountController.text);

      debugPrint('Starting credit purchase...');
      debugPrint('Payer: $_selectedACMEPayer');
      debugPrint('Recipient: $_selectedCreditAccount');
      debugPrint('Credits: $creditAmount');

      // Create purchase request
      final request = PurchaseCreditRequest(
        recipientUrl: _selectedCreditAccount!,
        payerAccountUrl: _selectedACMEPayer!,
        creditAmount: creditAmount,
        memo: 'Credit purchase via Accumulate Lite Wallet',
      );

      // Execute real credit purchase via RPC
      final response = await _creditService.purchaseCredits(request);

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Successfully purchased ${response.creditsAmount} credits!'),
                  if (response.transactionId != null)
                    Text('Transaction ID: ${response.transactionId}',
                      style: const TextStyle(fontSize: 12)),
                  if (response.acmeAmount != null)
                    Text('ACME Cost: ${response.acmeAmount! / 100000000} ACME',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );

          // Clear form on success
          _creditAmountController.clear();
          setState(() {
            _selectedCreditAccount = null;
            _selectedACMEPayer = null;
            _costCalculation = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${response.error ?? 'Credit purchase failed'}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error purchasing credits: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error purchasing credits: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Purchase Credits',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Buy credits using ACME to perform transactions on the network.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Add Credits to Dropdown
              const Text(
                'Add Credits to:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCreditAccount,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select account to receive credits',
                ),
                items: _creditAccounts.map((account) {
                  return DropdownMenuItem<String>(
                    value: account['url'],
                    child: SizedBox(
                      width: 250,
                      child: Text(
                        account['displayName'],
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _selectedCreditAccount = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a credit account';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ACME Payer Dropdown
              const Text(
                'ACME Payer Account',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedACMEPayer,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select ACME payer account',
                ),
                items: _acmePayerAccounts.map((account) {
                  return DropdownMenuItem<String>(
                    value: account['url'],
                    child: SizedBox(
                      width: 250,
                      child: Text(
                        account['displayName'],
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _selectedACMEPayer = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an ACME payer account';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Credit Amount Field
              const Text(
                'Credit Amount',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _creditAmountController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter number of credits to purchase',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _calculateCost(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter credit amount';
                  }
                  final amount = int.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid number greater than 0';
                  }
                  return null;
                },
              ),

              // Cost Calculation Display
              if (_costCalculation != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cost Calculation',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Credits: ${_costCalculation!['creditAmount']}'),
                      Text('ACME Cost: ${_costCalculation!['acmeCostFormatted']} ACME'),
                      Text('Oracle Value: ${_costCalculation!['oracleValue']}'),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Purchase Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _purchaseCredits,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Purchase Credits',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _creditAmountController.dispose();
    super.dispose();
  }
}

/// Send/Receive screen with QR generation
class _SendReceiveScreen extends StatefulWidget {
  const _SendReceiveScreen();

  @override
  State<_SendReceiveScreen> createState() => _SendReceiveScreenState();
}

class _SendReceiveScreenState extends State<_SendReceiveScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Send', icon: Icon(Icons.send)),
            Tab(text: 'Receive', icon: Icon(Icons.qr_code)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              const _SendTab(),
              const _ReceiveTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _SendTab extends StatefulWidget {
  const _SendTab();

  @override
  State<_SendTab> createState() => _SendTabState();
}

class _SendTabState extends State<_SendTab> {
  final _formKey = GlobalKey<FormState>();
  final _toController = TextEditingController();
  final _amountController = TextEditingController();

  String? _selectedFromAccount;
  String? _selectedCreditPayer;
  List<WalletAccountInfo> _accounts = [];
  List<WalletAccountInfo> _liteAndTokenAccounts = [];
  List<WalletAccountInfo> _liteAccounts = [];
  bool _isLoading = true;
  bool _isSendingTransaction = false;

  // Credit Payer variables
  List<String> _creditPayerList = [];
  Map<String, WalletAccount> _creditPayerAccounts = {};
  bool _creditPayerLoaded = false;
  bool _creditPayerLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAccountsOptimized();
    _loadCreditPayerData(); // Auto-load credit payer data when screen loads
  }

  Future<void> _loadAccountsOptimized() async {
    try {
      // Load accounts without expensive key checks first for instant UI
      final dbHelper = DatabaseHelper();
      final basicAccounts = await dbHelper.getAllAccounts();

      if (mounted) {
        setState(() {
          _accounts = basicAccounts.map((account) => WalletAccountInfo(
            account: account,
            hasPrivateKey: false, // Will be checked when needed
            hasMnemonic: false,
          )).toList();

          _liteAndTokenAccounts = _accounts.where((account) =>
            account.account.accountType == 'lite_account' ||
            account.account.accountType == 'token_account'
          ).toList();

          _liteAccounts = _accounts.where((account) =>
            account.account.accountType == 'lite_account'
          ).toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCreditPayerData() async {
    if (_creditPayerLoaded || _creditPayerLoading) return;

    if (mounted) setState(() => _creditPayerLoading = true);

    try {
      final storageService = WalletStorageService();
      final accountsWithInfo = await storageService.getAllAccountsWithKeyInfo();
      final accounts = accountsWithInfo.map((info) => info.account).toList();

      final creditPayers = <String>[];
      final creditPayerAccounts = <String, WalletAccount>{};

      // Add lite identities (base addresses without /ACME) that can pay for credits
      final liteIdentities = accounts
          .where((acc) => acc.accountType == 'lite_identity');
      for (final account in liteIdentities) {
        creditPayers.add(account.address);
        creditPayerAccounts[account.address] = account;
      }

      // Add key pages that can sign and pay for transactions
      final keyPages = accounts
          .where((acc) => acc.accountType?.contains('key') == true || acc.address.contains('/book/'));
      for (final account in keyPages) {
        creditPayers.add(account.address);
        creditPayerAccounts[account.address] = account;
      }

      _creditPayerList = creditPayers.isNotEmpty
          ? creditPayers
          : ['demo-lite-account-1', 'demo-lite-account-2'];
      _creditPayerAccounts = creditPayerAccounts;
      _creditPayerLoaded = true;
    } catch (e) {
      debugPrint('Error loading Credit Payer data: $e');
      _creditPayerList = ['demo-lite-account-1', 'demo-lite-account-2'];
    } finally {
      if (mounted) setState(() => _creditPayerLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send Tokens',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Send tokens to another account.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // From Account Dropdown
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'From',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedFromAccount,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select source account',
                        ),
                        items: _liteAndTokenAccounts.map((accountInfo) {
                          return DropdownMenuItem<String>(
                            value: accountInfo.account.address,
                            child: Text(
                              '${accountInfo.account.name} (${accountInfo.account.accountType})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _selectedFromAccount = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a source account';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // To Address Field
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'To',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _toController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter recipient address (acc://...)',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter recipient address';
                          }
                          if (!value.startsWith('acc://')) {
                            return 'Address must start with acc://';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Amount Field
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Amount',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter amount (e.g., 10.5)',
                          suffixText: 'ACME',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid positive number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Credit Payer Dropdown
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Credit Payer',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCreditPayer,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select Credit Payer',
                        ),
                        items: _creditPayerLoading
                            ? []
                            : _creditPayerList.map((payer) {
                                final account = _creditPayerAccounts[payer];
                                String displayName;
                                if (account != null) {
                                  // Show account name and formatted address
                                  displayName = '${account.name} (${AppConstants.formatLiteAccountAddress(payer)})';
                                } else {
                                  // Fallback for demo accounts
                                  displayName = payer;
                                }
                                return DropdownMenuItem<String>(
                                  value: payer,
                                  child: Text(
                                    displayName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _selectedCreditPayer = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a credit payer account';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Send Button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _processSendTransaction();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Send Transaction',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _processSendTransaction() async {
    // Prevent duplicate requests
    if (_isSendingTransaction) {
      debugPrint('Transaction already in progress, ignoring duplicate request');
      return;
    }

    // Validate inputs
    if (_selectedFromAccount == null || _selectedFromAccount!.isEmpty) {
      _showErrorDialog('Please select a source account');
      return;
    }

    if (_toController.text.isEmpty) {
      _showErrorDialog('Please enter recipient address');
      return;
    }

    if (_amountController.text.isEmpty) {
      _showErrorDialog('Please enter amount');
      return;
    }

    if (_selectedCreditPayer == null || _selectedCreditPayer!.isEmpty) {
      _showErrorDialog('Please select a credit payer');
      return;
    }

    final fromAccount = _liteAndTokenAccounts.firstWhere(
      (account) => account.account.address == _selectedFromAccount,
    );
    final creditPayerAccount = _creditPayerAccounts[_selectedCreditPayer];
    final amount = double.tryParse(_amountController.text);

    if (amount == null || amount <= 0) {
      _showErrorDialog('Please enter a valid positive amount');
      return;
    }

    // Convert amount to sub-units (ACME has 8 decimal places)
    final amountSubUnits = (amount * 100000000).round();

    // Set sending state (no confirmation dialog or loading dialog)
    setState(() {
      _isSendingTransaction = true;
    });

    try {
      await _executeSendTransaction(
        fromAccount.account.address,
        _toController.text,
        amountSubUnits,
        _selectedCreditPayer!,
        fromAccount,
        creditPayerAccount
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingTransaction = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Always reset the sending state
      if (mounted) {
        setState(() {
          _isSendingTransaction = false;
        });
      }
    }
  }

  Future<bool> _showConfirmationDialog(WalletAccount fromAccount, String toAddress, double amount, String creditPayerName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${fromAccount.name}'),
            Text('From Address: ${AppConstants.formatLiteAccountAddress(fromAccount.address)}'),
            const SizedBox(height: 8),
            Text('To: ${AppConstants.formatLiteAccountAddress(toAddress)}'),
            const SizedBox(height: 8),
            Text('Amount: ${amount.toStringAsFixed(8)} ACME'),
            const SizedBox(height: 8),
            Text('Credit Payer: $creditPayerName'),
            const SizedBox(height: 16),
            const Text(
              'Please confirm this transaction. This action cannot be undone.',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Transaction'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Sending transaction...'),
            Text('Please wait', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String txId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Sent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transaction submitted successfully!'),
            const SizedBox(height: 8),
            const Text('Transaction ID:'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                txId,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeSendTransaction(
    String fromAccount,
    String toAccount,
    int amountSubUnits,
    String creditPayerAddress,
    WalletAccountInfo fromAccountInfo,
    WalletAccount? creditPayerAccount
  ) async {
    try {
      // Create SendTokensRequest using the service facade
      final sendTokensRequest = accumulate_requests.SendTokensRequest(
        fromAccountUrl: fromAccount,
        recipients: [accumulate_requests.TokenRecipient(accountUrl: toAccount, amount: amountSubUnits)],
        signerUrl: creditPayerAddress,
        memo: 'ACME transfer from Accumulate Lite Wallet',
      );

      // Execute the transaction using the transaction service
      final result = await ServiceLocator().transactionService.sendTokens(sendTokensRequest);

      if (mounted) {
        if (result.success) {
          final txId = result.transactionId ?? 'Unknown';

          // Clear form after successful transaction
          setState(() {
            _selectedFromAccount = null;
            _selectedCreditPayer = null;
            _toController.clear();
            _amountController.clear();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaction sent successfully! TX: $txId'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final error = result.error ?? 'Unknown error occurred';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaction failed: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send transaction: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _toController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}

class _ReceiveTab extends StatefulWidget {
  const _ReceiveTab();

  @override
  State<_ReceiveTab> createState() => _ReceiveTabState();
}

class _ReceiveTabState extends State<_ReceiveTab> {
  String? _selectedAccount;
  List<WalletAccountInfo> _liteAndTokenAccounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccountsOptimized();
  }

  Future<void> _loadAccountsOptimized() async {
    try {
      // Load accounts without expensive key checks first for instant UI
      final dbHelper = DatabaseHelper();
      final basicAccounts = await dbHelper.getAllAccounts();

      if (mounted) {
        setState(() {
          _liteAndTokenAccounts = basicAccounts.where((account) =>
            account.accountType == 'lite_account' ||
            account.accountType == 'token_account'
          ).map((account) => WalletAccountInfo(
            account: account,
            hasPrivateKey: false, // Not needed for receive screen
            hasMnemonic: false,
          )).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receive Tokens',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Select an account to generate its receive address and QR code.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Account Selection Dropdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Account',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedAccount,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select account to receive tokens',
                      ),
                      items: _liteAndTokenAccounts.map((accountInfo) {
                        return DropdownMenuItem<String>(
                          value: accountInfo.account.address,
                          child: Text(
                            '${accountInfo.account.name} (${accountInfo.account.accountType})',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedAccount = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_selectedAccount != null) ...[
              // Address Display
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Receive Address',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppConstants.formatLiteAccountAddress(_selectedAccount!),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: _selectedAccount!));
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Address copied to clipboard'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // QR Code Display
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'QR Code',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _selectedAccount != null
                            ? QrImageView(
                                data: _selectedAccount!,
                                version: QrVersions.auto,
                                size: 200.0,
                                backgroundColor: Colors.white,
                              )
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.qr_code, size: 80, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text(
                                      'Select an account\nto generate QR code',
                                      style: TextStyle(color: Colors.grey),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _selectedAccount != null
                            ? () async {
                                await Clipboard.setData(ClipboardData(text: _selectedAccount!));
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Address copied to clipboard for sharing'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            : null,
                        icon: const Icon(Icons.share),
                        label: const Text('Share QR Code'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const Card(
                color: Colors.blue,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.white, size: 48),
                      SizedBox(height: 8),
                      Text(
                        'Select Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please select an account above to display its receive address and QR code.',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Data screen for writing data to the blockchain
class _DataScreen extends StatefulWidget {
  const _DataScreen();

  @override
  State<_DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<_DataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dataController = TextEditingController();

  String? _selectedCreditPayer;
  String? _selectedDataAccount;
  List<WalletAccountInfo> _liteAccounts = [];
  List<String> _dataAccountList = [];
  Map<String, WalletAccount> _dataAccountMap = {};
  bool _isLoading = true;
  bool _dataAccountLoaded = false;
  bool _dataAccountLoading = false;
  bool _isWritingData = false;

  // Credit Payer variables
  List<String> _creditPayerList = [];
  Map<String, WalletAccount> _creditPayerAccounts = {};
  bool _creditPayerLoaded = false;
  bool _creditPayerLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAccountsOptimized();
    // Force immediate loading without guards for auto-loading
    _immediateLoadDataAccountData();
    _immediateLoadCreditPayerData();
  }

  Future<void> _loadAccountsOptimized() async {
    try {
      // Load accounts without expensive key checks first for instant UI
      final dbHelper = DatabaseHelper();
      final basicAccounts = await dbHelper.getAllAccounts();

      if (mounted) {
        setState(() {
          _liteAccounts = basicAccounts.where((account) =>
            account.accountType == 'lite_account'
          ).map((account) => WalletAccountInfo(
            account: account,
            hasPrivateKey: false, // Will be checked when needed
            hasMnemonic: false,
          )).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCreditPayerData() async {
    if (_creditPayerLoaded || _creditPayerLoading) return;

    if (mounted) setState(() => _creditPayerLoading = true);

    try {
      final storageService = WalletStorageService();
      final accountsWithInfo = await storageService.getAllAccountsWithKeyInfo();
      final accounts = accountsWithInfo.map((info) => info.account).toList();

      final creditPayers = <String>[];
      final creditPayerAccounts = <String, WalletAccount>{};

      // Add lite identities (base addresses without /ACME) that can pay for credits
      final liteIdentities = accounts
          .where((acc) => acc.accountType == 'lite_identity');
      for (final account in liteIdentities) {
        creditPayers.add(account.address);
        creditPayerAccounts[account.address] = account;
      }

      // Add key pages that can sign and pay for transactions
      final keyPages = accounts
          .where((acc) => acc.accountType?.contains('key') == true || acc.address.contains('/book/'));
      for (final account in keyPages) {
        creditPayers.add(account.address);
        creditPayerAccounts[account.address] = account;
      }

      _creditPayerList = creditPayers.isNotEmpty
          ? creditPayers
          : ['demo-lite-account-1', 'demo-lite-account-2'];
      _creditPayerAccounts = creditPayerAccounts;
      _creditPayerLoaded = true;
    } catch (e) {
      debugPrint('Error loading Credit Payer data: $e');
      _creditPayerList = ['demo-lite-account-1', 'demo-lite-account-2'];
    } finally {
      if (mounted) setState(() => _creditPayerLoading = false);
    }
  }

  Future<void> _loadDataAccountData() async {
    if (_dataAccountLoaded || _dataAccountLoading) return;

    if (mounted) setState(() => _dataAccountLoading = true);

    try {
      final storageService = WalletStorageService();
      final accountsWithInfo = await storageService.getAllAccountsWithKeyInfo();
      final accounts = accountsWithInfo.map((info) => info.account).toList();

      final dataAccounts = <String>[];
      final dataAccountMap = <String, WalletAccount>{};

      // Add ADI Data Accounts only
      final adiDataAccounts = accounts
          .where((acc) => acc.accountType == 'data_account' && acc.address.startsWith('acc://'));
      for (final account in adiDataAccounts) {
        dataAccounts.add(account.address);
        dataAccountMap[account.address] = account;
      }

      _dataAccountList = dataAccounts.isNotEmpty
          ? dataAccounts
          : [];
      _dataAccountMap = dataAccountMap;
      _dataAccountLoaded = true;
    } catch (e) {
      debugPrint('Error loading Data Account data: $e');
      _dataAccountList = [];
    } finally {
      if (mounted) setState(() => _dataAccountLoading = false);
    }
  }

  /// Immediate loading methods that bypass loading guards for auto-loading
  Future<void> _immediateLoadCreditPayerData() async {
    debugPrint('WRITE DATA: Immediate loading Credit Payer data...');
    if (mounted) {
      setState(() {
        _creditPayerLoading = true;
        _creditPayerLoaded = false;
      });
    }

    try {
      final storageService = WalletStorageService();
      final accountsWithInfo = await storageService.getAllAccountsWithKeyInfo();
      final accounts = accountsWithInfo.map((info) => info.account).toList();

      final creditPayers = <String>[];
      final creditPayerAccounts = <String, WalletAccount>{};

      // Add lite identities (base addresses without /ACME) that can pay for credits
      final liteIdentities = accounts
          .where((acc) => acc.accountType == 'lite_identity');
      for (final account in liteIdentities) {
        creditPayers.add(account.address);
        creditPayerAccounts[account.address] = account;
      }

      // Add key pages that can sign and pay for transactions
      final keyPages = accounts
          .where((acc) => acc.accountType?.contains('key') == true || acc.address.contains('/book/'));
      for (final account in keyPages) {
        creditPayers.add(account.address);
        creditPayerAccounts[account.address] = account;
      }

      if (mounted) {
        setState(() {
          _creditPayerList = creditPayers.isNotEmpty
              ? creditPayers
              : ['demo-lite-account-1', 'demo-lite-account-2'];
          _creditPayerAccounts = creditPayerAccounts;
          _creditPayerLoaded = true;
          _creditPayerLoading = false;
        });
      }

      debugPrint('WRITE DATA: Credit Payer immediate loading complete. Found ${_creditPayerList.length} payers');
    } catch (e) {
      debugPrint('WRITE DATA: Error in immediate Credit Payer loading: $e');
      if (mounted) {
        setState(() {
          _creditPayerList = ['demo-lite-account-1', 'demo-lite-account-2'];
          _creditPayerLoaded = true;
          _creditPayerLoading = false;
        });
      }
    }
  }

  Future<void> _immediateLoadDataAccountData() async {
    debugPrint('WRITE DATA: Immediate loading Data Account data...');
    if (mounted) {
      setState(() {
        _dataAccountLoading = true;
        _dataAccountLoaded = false;
      });
    }

    try {
      final storageService = WalletStorageService();
      final accountsWithInfo = await storageService.getAllAccountsWithKeyInfo();
      final accounts = accountsWithInfo.map((info) => info.account).toList();

      final dataAccounts = <String>[];
      final dataAccountMap = <String, WalletAccount>{};

      // Add ONLY ADI Data Accounts (acc:// addresses with data_account type)
      final adiDataAccounts = accounts
          .where((acc) => acc.accountType == 'data_account' && acc.address.startsWith('acc://'));
      for (final account in adiDataAccounts) {
        dataAccounts.add(account.address);
        dataAccountMap[account.address] = account;
      }

      if (mounted) {
        setState(() {
          _dataAccountList = dataAccounts;
          _dataAccountMap = dataAccountMap;
          _dataAccountLoaded = true;
          _dataAccountLoading = false;
        });
      }

      debugPrint('WRITE DATA: Data Account immediate loading complete. Found ${_dataAccountList.length} ADI data accounts');
    } catch (e) {
      debugPrint('WRITE DATA: Error in immediate Data Account loading: $e');
      if (mounted) {
        setState(() {
          _dataAccountList = [];
          _dataAccountMap = {};
          _dataAccountLoaded = true;
          _dataAccountLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Write Data to Blockchain',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Store immutable data entries on the Accumulate blockchain.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Write To Field
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Write To',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedDataAccount,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select Data Account',
                        ),
                        items: _dataAccountLoading
                            ? []
                            : _dataAccountList.map((dataAccount) {
                                return DropdownMenuItem<String>(
                                  value: dataAccount,
                                  child: Text(dataAccount),
                                );
                              }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDataAccount = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a data account';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Data to Write Field
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Data to Write',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _dataController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter your data here...',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter data to write';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Credit Payer Dropdown
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Credit Payer',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCreditPayer,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select Credit Payer',
                        ),
                        items: _creditPayerLoading
                            ? []
                            : _creditPayerList.map((payer) {
                                final account = _creditPayerAccounts[payer];
                                String displayName;
                                if (account != null) {
                                  // Show account name and formatted address
                                  displayName = '${account.name} (${AppConstants.formatLiteAccountAddress(payer)})';
                                } else {
                                  // Fallback for demo accounts
                                  displayName = payer;
                                }
                                return DropdownMenuItem<String>(
                                  value: payer,
                                  child: Text(
                                    displayName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _selectedCreditPayer = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a credit payer account';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Write Data Button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _processDataWrite();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Write Data',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _processDataWrite() async {
    // Prevent duplicate requests
    if (_isWritingData) {
      debugPrint('Data write already in progress, ignoring duplicate request');
      return;
    }

    if (_selectedDataAccount == null || _selectedDataAccount!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a data account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_dataController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter data to write'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCreditPayer == null || _selectedCreditPayer!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a credit payer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Set writing state (no loading dialog)
    setState(() {
      _isWritingData = true;
    });

    try {
      await _executeDataWrite();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isWritingData = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error writing data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Always reset the writing state
      if (mounted) {
        setState(() {
          _isWritingData = false;
        });
      }
    }
  }

  Future<bool> _showConfirmationDialog() async {
    final creditPayerAccount = _creditPayerAccounts[_selectedCreditPayer];
    final dataEntries = _parseDataEntries(_dataController.text);

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Data Write'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Write To: $_selectedDataAccount'),
            const SizedBox(height: 8),
            Text('Credit Payer: ${creditPayerAccount?.name ?? _selectedCreditPayer}'),
            const SizedBox(height: 8),
            Text('Number of entries: ${dataEntries.length}'),
            const SizedBox(height: 8),
            const Text('Data Entries:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ...dataEntries.take(3).map((entry) => Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
              child: Text(
                '• ${entry.length > 50 ? entry.substring(0, 50) + '...' : entry}',
                style: const TextStyle(fontSize: 12),
              ),
            )),
            if (dataEntries.length > 3)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text('... and ${dataEntries.length - 3} more entries'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Write Data'),
          ),
        ],
      ),
    ) ?? false;
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String txId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Data written successfully to the blockchain!'),
            const SizedBox(height: 8),
            const Text('Transaction ID:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            SelectableText(
              txId,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  List<String> _parseDataEntries(String rawData) {
    // Split by semicolon and filter out empty entries
    return rawData
        .split(';')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  Future<void> _executeDataWrite() async {
    try {
      final dataEntries = _parseDataEntries(_dataController.text);
      if (dataEntries.isEmpty) {
        throw Exception('No valid data entries found');
      }

      // Convert string entries to Uint8List as required by the SDK
      final dataEntriesBytes = dataEntries
          .map((entry) => Uint8List.fromList(utf8.encode(entry)))
          .toList();

      // Get the enhanced accumulate service
      final enhancedService = ServiceLocator().enhancedAccumulateService;

      // Create the write data request
      final writeDataRequest = accumulate_requests.WriteDataRequest(
        dataAccountUrl: _selectedDataAccount!,
        dataEntries: dataEntries,
        signerUrl: _selectedCreditPayer!,
        scratch: false,
        writeToState: true,
        memo: 'Data written from Accumulate Lite Wallet',
      );

      debugPrint('Writing ${dataEntries.length} data entries to $_selectedDataAccount');
      debugPrint('Entries: ${dataEntries.join(', ')}');
      debugPrint('Signer: $_selectedCreditPayer');

      // Execute the write data operation
      final response = await ServiceLocator().dataService.writeData(writeDataRequest);

      debugPrint('Data write operation completed, response: ${response.success}');

      if (mounted) {
        if (response.success) {
          debugPrint(' Data written successfully!');
          debugPrint('Transaction ID: ${response.transactionId}');

          // Clear the form
          _dataController.clear();
          setState(() {
            _selectedDataAccount = null;
            _selectedCreditPayer = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(' Data written successfully! Transaction: ${response.transactionId ?? 'Unknown'}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(response.error ?? 'Unknown error occurred');
        }
      }
    } catch (e) {
      debugPrint('Error writing data: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }
}

/// Credits screen for purchasing and managing credits
class _CreditsScreen extends StatefulWidget {
  const _CreditsScreen();

  @override
  State<_CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<_CreditsScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Credits Management',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Purchase and manage credits for network transactions.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Purchase Credits Section
              _PurchaseCreditsWidget(),
            ],
          ),
        ),
      ),
    );
  }
}


/// Sign screen for transaction signing
class _SignScreen extends StatefulWidget {
  const _SignScreen();

  @override
  State<_SignScreen> createState() => _SignScreenState();
}

class _SignScreenState extends State<_SignScreen> {
  String? _selectedSigner;
  String _transactionHash = '';
  List<WalletAccountInfo> _keyPageAccounts = [];
  bool _isLoading = true;
  bool _isSigning = false;
  final _transactionHashController = TextEditingController();

  final List<Map<String, dynamic>> _pendingTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadAccountsOptimized();
  }

  @override
  void dispose() {
    _transactionHashController.dispose();
    super.dispose();
  }

  Future<void> _loadAccountsOptimized() async {
    try {
      // Load accounts without expensive key checks first for instant UI
      final dbHelper = DatabaseHelper();
      final basicAccounts = await dbHelper.getAllAccounts();

      if (mounted) {
        setState(() {
          // Filter for actual ADI key page accounts only
          _keyPageAccounts = basicAccounts
              .where((account) =>
                  account.accountType == 'key_page' ||
                  account.address.contains('/book/') ||
                  account.accountType?.contains('key') == true)
              .map((account) => WalletAccountInfo(
                account: account,
                hasPrivateKey: false, // Will be checked when needed
                hasMnemonic: false,
              )).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signTransaction() async {
    if (_selectedSigner == null || _transactionHashController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a transaction hash and select a signer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSigning = true;
    });

    try {
      // Get services from service locator
      final keyService = serviceLocator.keyManagementService;
      final dbHelper = serviceLocator.databaseHelper;
      final accumulateService = serviceLocator.enhancedAccumulateService;

      // Create transaction signing service
      final signingService = TransactionSigningService(
        keyService: keyService,
        dbHelper: dbHelper,
        baseUrl: accumulateService.baseUrl,
      );

      // Sign the transaction
      final result = await signingService.signTransaction(
        transactionHash: _transactionHashController.text.trim(),
        signerKeyPageUrl: _selectedSigner!,
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction signed successfully!\nSignature: ${result.signatureHash?.substring(0, 16)}...'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );

        // Clear the form
        _transactionHashController.clear();
        setState(() {
          _selectedSigner = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing transaction: ${result.error}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSigning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Signing',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Select a signer and review pending transactions.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Transaction Hash Input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transaction Hash to Sign',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _transactionHashController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter transaction hash (e.g., 0x1234...)',
                      prefixIcon: Icon(Icons.tag),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _transactionHash = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a transaction hash';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Signer Selection Dropdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Signer (Key Page)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSigner,
                    isExpanded: true, // Fix for overflow
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select signing key page',
                    ),
                    items: _keyPageAccounts.map((accountInfo) {
                      return DropdownMenuItem<String>(
                        value: accountInfo.account.address,
                        child: Text(
                          accountInfo.account.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedSigner = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_selectedSigner != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSigning ? null : _signTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: _isSigning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Sign Transaction',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ] else ...[
            const Card(
              color: Colors.indigo,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.key, color: Colors.white, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Select Signer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please select a key page above to review and sign pending transactions.',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            DeveloperBypass.createBypassToggle(
              screenName: 'Sign Screen Bypass',
              onBypass: () {
                setState(() {
                  _selectedSigner = _keyPageAccounts.isNotEmpty ? _keyPageAccounts.first.account.address : 'demo_signer';
                });
              },
              customMessage: 'Bypass signer selection for development. '
                  'This allows you to view and interact with pending transactions.',
            ),
          ],
        ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, Map<String, dynamic> tx) {
    String signerName = 'Demo Signer';

    // Try to find the signer account, fallback to demo name if using bypass
    try {
      final signerAccount = _keyPageAccounts.firstWhere(
        (account) => account.account.address == _selectedSigner,
      );
      signerName = signerAccount.account.name;
    } catch (e) {
      // Using developer bypass with demo signer
      signerName = 'Demo Signer (Developer Mode)';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction: ${tx['id']}'),
            Text('Type: ${tx['type']}'),
            const SizedBox(height: 8),
            Text('Signer: $signerName'),
            const SizedBox(height: 16),
            const Text(
              'Transaction signing is not implemented yet.',
              style: TextStyle(color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Transaction ${tx['id']} rejected'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSignDialog(BuildContext context, Map<String, dynamic> tx) {
    String signerName = 'Demo Signer';

    // Try to find the signer account, fallback to demo name if using bypass
    try {
      final signerAccount = _keyPageAccounts.firstWhere(
        (account) => account.account.address == _selectedSigner,
      );
      signerName = signerAccount.account.name;
    } catch (e) {
      // Using developer bypass with demo signer
      signerName = 'Demo Signer (Developer Mode)';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction: ${tx['id']}'),
            Text('Type: ${tx['type']}'),
            const SizedBox(height: 8),
            Text('Signer: $signerName'),
            const SizedBox(height: 16),
            const Text(
              'Transaction signing is not implemented yet.',
              style: TextStyle(color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Transaction ${tx['id']} signed & broadcast'),
                  backgroundColor: Colors.green,
                ),
              );
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Sign & Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Keep the original demo screens for individual testing

/// Demo transaction screen with validation blocking
class _DemoTransactionScreen extends StatefulWidget {
  const _DemoTransactionScreen();

  @override
  State<_DemoTransactionScreen> createState() => _DemoTransactionScreenState();
}

class _DemoTransactionScreenState extends State<_DemoTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isValidated = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Transaction'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Recipient Address',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 20) {
                        return 'Invalid address format';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || double.tryParse(value) == null) {
                        return 'Invalid amount';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (!_isValidated) ...[
              const Card(
                color: Colors.orange,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.block, color: Colors.white, size: 48),
                      SizedBox(height: 8),
                      Text(
                        'Transactions Blocked',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Accumulate Transactions require blockchain connection and network fees in credits.',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DeveloperBypass.createBypassToggle(
                screenName: 'Transaction Validation',
                onBypass: () {
                  setState(() {
                    _isValidated = true;
                  });
                },
                customMessage: 'Bypass transaction validation for development. '
                    'This simulates successful blockchain connection and fee payment.',
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transaction sent successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text('Send Transaction'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }
}

/// Demo balance screen with network call blocking
class _DemoBalanceScreen extends StatefulWidget {
  const _DemoBalanceScreen();

  @override
  State<_DemoBalanceScreen> createState() => _DemoBalanceScreenState();
}

class _DemoBalanceScreenState extends State<_DemoBalanceScreen> {
  bool _isLoading = true;
  String? _balance;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Check if developer mode is enabled
      final balance = await DeveloperBypass.simulateBalance();
      setState(() {
        _balance = balance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load balance: Network error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Balance'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isLoading) ...[
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading balance...'),
                    ],
                  ),
                ),
              ),
            ] else if (_error != null) ...[
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      const Text(
                        'Balance Loading Failed',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_error!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DeveloperBypass.createBypassToggle(
                screenName: 'Network Calls',
                onBypass: () {
                  _loadBalance();
                },
                customMessage: 'Bypass network calls and simulate successful responses. '
                    'This allows testing UI without implementing API calls.',
              ),
            ] else ...[
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.account_balance_wallet,
                          color: Colors.green, size: 48),
                      const SizedBox(height: 8),
                      const Text(
                        'Current Balance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _balance!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Add Chart Widget
              const SizedBox(height: 16),
              const ChartWidget(),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadBalance,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Balance'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Demo QR scanner screen with permission blocking
class _DemoQRScreen extends StatefulWidget {
  const _DemoQRScreen();

  @override
  State<_DemoQRScreen> createState() => _DemoQRScreenState();
}

class _DemoQRScreenState extends State<_DemoQRScreen> {
  bool _hasPermission = false;
  String? _scannedData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_hasPermission) ...[
              const Card(
                color: Colors.orange,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.camera_alt, color: Colors.white, size: 48),
                      SizedBox(height: 8),
                      Text(
                        'Camera Permission Required',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This feature requires camera access to scan QR codes.',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DeveloperBypass.createBypassToggle(
                screenName: 'Camera Permission',
                onBypass: () {
                  setState(() {
                    _hasPermission = true;
                    _scannedData = 'acc://1234567890abcdef/ACME/123.45';
                  });
                },
                customMessage: 'Bypass camera permission and simulate QR scan result. '
                    'This allows testing QR functionality without camera access.',
              ),
            ] else ...[
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.qr_code, color: Colors.blue, size: 48),
                      const SizedBox(height: 8),
                      const Text(
                        'QR Scanner Active',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Scanner is ready to read QR codes'),
                    ],
                  ),
                ),
              ),
              if (_scannedData != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 48),
                        const SizedBox(height: 8),
                        const Text(
                          'QR Code Scanned',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppConstants.formatLiteAccountAddress(_scannedData!),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/*
DEVELOPER NOTES:

This is a minimal working version that compiles and runs without errors.

Core Features Ready:
- Service initialization and dependency injection
- Secure storage integration
- Theme system
- Basic navigation structure
- Authentication placeholder

To extend this wallet:
1. Follow the authentication guide in docs/AUTHENTICATION.md
2. Add UI features from the original feature directories
3. Extend data persistence per docs/PERSISTENCE.md
4. Configure networks per docs/CONFIGURATION.md

The core blockchain services are initialized and ready to use in your implementations.
*/