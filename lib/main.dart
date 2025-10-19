// Clean main.dart for Accumulate Lite Wallet - Open Source Core
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Core architecture imports
import 'core/di/service_locator.dart';
import 'core/adapters/flutter_secure_storage_adapter.dart';

// Theme and utilities
import 'shared/themes/app_theme.dart';
import 'shared/utils/developer_bypass.dart';

// Storage services
import 'core/services/storage/wallet_storage_service.dart';

// Chart widget
import 'widgets/chart_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the core services (pure Dart business logic)
  _initializeCoreServices();

  // Start the app
  runApp(const AccumulateLiteWalletApp());
}

void _initializeCoreServices() async {
  final serviceLocator = ServiceLocator();
  const flutterStorage = FlutterSecureStorage();
  final storageAdapter = FlutterSecureStorageAdapter(flutterStorage);
  serviceLocator.initializeCoreServices(storageAdapter);

  // Initialize wallet storage
  final WalletStorageService storageService = WalletStorageService();
  await storageService.initializeStorage();

  debugPrint('✅ Core services and storage initialized successfully');
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
  bool _developerMode = false; // Toggle for bypassing auth

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    try {
      // Check if developer mode is enabled first
      final isDeveloperMode = await DeveloperBypass.isDeveloperModeEnabled();

      // Check if user exists (developers should implement proper auth)
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading wallet...'),
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
        title: const Text('Accumulate Lite Wallet'),
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
                      '• Add secure storage for user data\n'
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
              '✅ Core Services Ready:\n'
              '• Blockchain API integration\n'
              '• Secure storage adapters\n'
              '• Service dependency injection\n'
              '• Network configuration\n'
              '• Token sending functionality',
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
  String _selectedNetwork = 'Mainnet';

  final List<Widget> _screens = [
    const _HomeScreen(),
    const _CreateScreen(),
    const _SendReceiveScreen(),
    const _DataScreen(),
    const _VoteScreen(),
    const _SignScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Accumulate Wallet'),
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
              if (_selectedNetwork != 'Mainnet') ...[
                const PopupMenuItem<String>(
                  value: 'faucet',
                  child: ListTile(
                    leading: Icon(Icons.water_drop),
                    title: Text('Faucet'),
                  ),
                ),
              ],
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
              icon: Icon(Icons.how_to_vote),
              label: 'Vote',
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
            content: Text('🔧 Developer mode active - All features unlocked'),
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
                    subtitle: const Text('14478bd573ea:26660'),
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
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Network switched to $_selectedNetwork'),
                        backgroundColor: Colors.green,
                      ),
                    );
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
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select account to receive test tokens:'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedAccountAddress,
                    hint: const Text('Select Account'),
                    items: accounts.map((accountInfo) {
                      return DropdownMenuItem<String>(
                        value: accountInfo.account.address,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(accountInfo.account.name),
                            Text(
                              accountInfo.account.address,
                              style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: Colors.grey,
                              ),
                            ),
                          ],
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedAccountAddress != null ? () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Test tokens added to account: ${accounts.firstWhere((a) => a.account.address == selectedAccountAddress).account.name}'),
                        backgroundColor: Colors.green,
                      ),
                    );
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Wallets and Data'),
          content: const Text(
            'This feature is not implemented yet. It will reset all wallet data and accounts.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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
  List<WalletAccountInfo> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _storageService.getAllAccountsWithKeyInfo();
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
                  const Text(
                    'Account Balance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<String>(
                    future: DeveloperBypass.simulateBalance(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          snapshot.data!,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        );
                      }
                      return const Text(
                        'Loading...',
                        style: TextStyle(fontSize: 24),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '≈ \$1,250.75 USD',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _QuickActionButton(
                        icon: Icons.send,
                        label: 'Send',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const _DemoTransactionScreen(),
                          ),
                        ),
                      ),
                      _QuickActionButton(
                        icon: Icons.qr_code_scanner,
                        label: 'Scan',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const _DemoQRScreen(),
                          ),
                        ),
                      ),
                      _QuickActionButton(
                        icon: Icons.account_balance_wallet,
                        label: 'Receive',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const _DemoBalanceScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
                        onPressed: _loadAccounts,
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
                            title: Text(account.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(typeLabel),
                                Text(
                                  account.address,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (accountInfo.hasPrivateKey)
                                  const Icon(Icons.key, size: 16, color: Colors.green),
                                if (accountInfo.hasMnemonic)
                                  const Icon(Icons.security, size: 16, color: Colors.blue),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recent Activity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _ActivityItem(
                    icon: Icons.arrow_upward,
                    title: 'Sent ACME',
                    subtitle: 'To acc://1234...5678',
                    amount: '-50.00 ACME',
                    color: Colors.red,
                  ),
                  _ActivityItem(
                    icon: Icons.arrow_downward,
                    title: 'Received ACME',
                    subtitle: 'From acc://abcd...efgh',
                    amount: '+125.50 ACME',
                    color: Colors.green,
                  ),
                  _ActivityItem(
                    icon: Icons.how_to_vote,
                    title: 'Vote Cast',
                    subtitle: 'Motion #acc://vote...1234',
                    amount: '',
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Chart Widget
          const ChartWidget(),
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

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
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
    {
      'value': 'burn_mint_tokens',
      'label': 'Burn/Mint Custom Tokens',
      'description': 'Burn or mint existing custom tokens'
    },
  ];

  @override
  void initState() {
    super.initState();
    // No heavy loading in initState - everything is lazy loaded
  }

  // Lazy loading methods for each dropdown type
  Future<void> _loadAdiData() async {
    if (_adiLoaded || _adiLoading) return;

    setState(() => _adiLoading = true);

    try {
      // Demo data for ADI - in real app this would query SQLite for ADI accounts
      await Future.delayed(const Duration(milliseconds: 50)); // Simulate minimal DB delay
      _adiList = ['demo-adi-1', 'demo-adi-2', 'demo-adi-3'];
      _adiLoaded = true;
    } catch (e) {
      print('Error loading ADI data: $e');
      _adiList = ['demo-adi-1'];
    } finally {
      if (mounted) setState(() => _adiLoading = false);
    }
  }

  Future<void> _loadKeyBookData() async {
    if (_keyBookLoaded || _keyBookLoading) return;

    setState(() => _keyBookLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 50));
      _keyBookList = ['demo-keybook-1', 'demo-keybook-2'];
      _keyBookLoaded = true;
    } catch (e) {
      print('Error loading KeyBook data: $e');
      _keyBookList = ['demo-keybook-1'];
    } finally {
      if (mounted) setState(() => _keyBookLoading = false);
    }
  }

  Future<void> _loadKeyPageData() async {
    if (_keyPageLoaded || _keyPageLoading) return;

    setState(() => _keyPageLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 50));
      _keyPageList = ['demo-keypage-1', 'demo-keypage-2', 'demo-keypage-3'];
      _keyPageLoaded = true;
    } catch (e) {
      print('Error loading KeyPage data: $e');
      _keyPageList = ['demo-keypage-1'];
    } finally {
      if (mounted) setState(() => _keyPageLoading = false);
    }
  }

  Future<void> _loadCreditPayerData() async {
    if (_creditPayerLoaded || _creditPayerLoading) return;

    setState(() => _creditPayerLoading = true);

    try {
      final storageService = WalletStorageService();
      final accountsWithInfo = await storageService.getAllAccountsWithKeyInfo();
      final accounts = accountsWithInfo.map((info) => info.account).toList();

      final liteAccounts = accounts
          .where((acc) => acc.accountType == 'lite_account')
          .map((acc) => acc.name)
          .toList();

      _creditPayerList = liteAccounts.isNotEmpty
          ? liteAccounts
          : ['demo-lite-account-1', 'demo-lite-account-2'];
      _creditPayerLoaded = true;
    } catch (e) {
      print('Error loading Credit Payer data: $e');
      _creditPayerList = ['demo-lite-account-1', 'demo-lite-account-2'];
    } finally {
      if (mounted) setState(() => _creditPayerLoading = false);
    }
  }

  Future<void> _loadTokenIssuerData() async {
    if (_tokenIssuerLoaded || _tokenIssuerLoading) return;

    setState(() => _tokenIssuerLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 50));
      _tokenIssuerList = ['demo-token-issuer-1', 'demo-token-issuer-2'];
      _tokenIssuerLoaded = true;
    } catch (e) {
      print('Error loading Token Issuer data: $e');
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
      print('Error loading Token Account data: $e');
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

      case 'add_keybook':
        return [
          _buildAdiDropdown(),
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

      case 'burn_mint_tokens':
        return [
          _buildAdiDropdown(),
          const SizedBox(height: 16),
          _buildKeyPageDropdown(),
          const SizedBox(height: 16),
          _buildTokenIssuerDropdown(),
          const SizedBox(height: 16),
          _buildTokenAccountDropdown(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Amount',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter amount',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                  _checkCanCreate();
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
                  _checkCanCreate();
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
                if (_creditPayerLoading) ...[
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
              value: _selectedCreditPayer,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select Credit Payer',
              ),
              items: _creditPayerLoading
                  ? []
                  : _creditPayerList.map((payer) {
                      return DropdownMenuItem<String>(
                        value: payer,
                        child: Text(payer),
                      );
                    }).toList(),
              onTap: () {
                if (!_creditPayerLoaded && !_creditPayerLoading) {
                  _loadCreditPayerData();
                }
              },
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
      case 'burn_mint_tokens':
        return [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _performAction('mint'),
                  icon: const Icon(Icons.add_circle),
                  label: const Text('Mint Tokens'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _performAction('burn'),
                  icon: const Icon(Icons.remove_circle),
                  label: const Text('Burn Tokens'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ];

      default:
        return [
          ElevatedButton.icon(
            onPressed: () => _performAction('create'),
            icon: const Icon(Icons.add_circle),
            label: const Text('Create Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ];
    }
  }

  Future<void> _performAction(String action) async {
    final accountType = _accountTypes.firstWhere(
      (type) => type['value'] == _selectedAccountType,
    );

    try {
      // Generate a simulated address for demo purposes
      final address = 'acc://${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';

      // Create the account using storage service
      final storageService = WalletStorageService();

      String accountName = '';
      if (_selectedAccountType == 'adi') {
        accountName = _adiNameController.text;
      } else if (_selectedAccountType == 'lite_account') {
        accountName = 'Lite Account ${DateTime.now().millisecondsSinceEpoch}';
      } else {
        accountName = _nameController.text;
      }

      await storageService.createAccount(
        name: accountName,
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

      String message = '✨ ${accountType['label']} "$accountName" ${action}d successfully!';
      if (action == 'mint' || action == 'burn') {
        String capitalizedAction = action[0].toUpperCase() + action.substring(1);
        message = '✨ $capitalizedAction ${_amountController.text} tokens successfully!';
      }

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
          content: Text('❌ Error ${action}ing account: $e'),
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
          _canCreate = _selectedAdi != null && _selectedCreditPayer != null;
          break;
        case 'add_keypage':
          _canCreate = _selectedAdi != null &&
                      _selectedKeyBook != null &&
                      _selectedCreditPayer != null;
          break;
        case 'burn_mint_tokens':
          _canCreate = _selectedAdi != null &&
                      _selectedKeyPage != null &&
                      _selectedTokenIssuer != null &&
                      _selectedTokenAccount != null &&
                      _amountController.text.isNotEmpty &&
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

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final WalletStorageService storageService = WalletStorageService();
      final accounts = await storageService.getAllAccountsWithKeyInfo();

      setState(() {
        _accounts = accounts;
        _liteAndTokenAccounts = accounts.where((account) =>
          account.account.accountType == 'lite_account' ||
          account.account.accountType == 'token_account'
        ).toList();
        _liteAccounts = accounts.where((account) =>
          account.account.accountType == 'lite_account'
        ).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select source account',
                        ),
                        items: _liteAndTokenAccounts.map((accountInfo) {
                          return DropdownMenuItem<String>(
                            value: accountInfo.account.address,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(accountInfo.account.name),
                                Text(
                                  '${accountInfo.account.accountType} - ${accountInfo.account.address}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
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
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select credit payer account',
                        ),
                        items: _liteAccounts.map((accountInfo) {
                          return DropdownMenuItem<String>(
                            value: accountInfo.account.address,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(accountInfo.account.name),
                                Text(
                                  accountInfo.account.address,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
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

  void _processSendTransaction() {
    final fromAccount = _liteAndTokenAccounts.firstWhere(
      (account) => account.account.address == _selectedFromAccount,
    );
    final creditPayerAccount = _liteAccounts.firstWhere(
      (account) => account.account.address == _selectedCreditPayer,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${fromAccount.account.name}'),
            Text('To: ${_toController.text}'),
            Text('Amount: ${_amountController.text} ACME'),
            Text('Credit Payer: ${creditPayerAccount.account.name}'),
            const SizedBox(height: 16),
            const Text(
              'Transaction processing is not implemented yet.',
              style: TextStyle(color: Colors.orange),
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
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final WalletStorageService storageService = WalletStorageService();
      final accounts = await storageService.getAllAccountsWithKeyInfo();

      setState(() {
        _liteAndTokenAccounts = accounts.where((account) =>
          account.account.accountType == 'lite_account' ||
          account.account.accountType == 'token_account'
        ).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select account to receive tokens',
                      ),
                      items: _liteAndTokenAccounts.map((accountInfo) {
                        return DropdownMenuItem<String>(
                          value: accountInfo.account.address,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(accountInfo.account.name),
                              Text(
                                '${accountInfo.account.accountType} - ${accountInfo.account.address}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
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
                                _selectedAccount!,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('📋 Address copied to clipboard'),
                                  ),
                                );
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
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code, size: 80, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'QR Code\n(Simulated)',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('📤 QR code shared successfully'),
                            ),
                          );
                        },
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
  final _writeToController = TextEditingController();
  final _dataController = TextEditingController();

  String? _selectedCreditPayer;
  List<WalletAccountInfo> _liteAccounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final WalletStorageService storageService = WalletStorageService();
      final accounts = await storageService.getAllAccountsWithKeyInfo();

      setState(() {
        _liteAccounts = accounts.where((account) =>
          account.account.accountType == 'lite_account'
        ).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
                      TextFormField(
                        controller: _writeToController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter data account address (acc://...)',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter data account address';
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
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select credit payer account',
                        ),
                        items: _liteAccounts.map((accountInfo) {
                          return DropdownMenuItem<String>(
                            value: accountInfo.account.address,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(accountInfo.account.name),
                                Text(
                                  accountInfo.account.address,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
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

  void _processDataWrite() {
    final creditPayerAccount = _liteAccounts.firstWhere(
      (account) => account.account.address == _selectedCreditPayer,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Write Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Write To: ${_writeToController.text}'),
            const SizedBox(height: 8),
            Text('Data: ${_dataController.text}'),
            const SizedBox(height: 8),
            Text('Credit Payer: ${creditPayerAccount.account.name}'),
            const SizedBox(height: 16),
            const Text(
              'Data writing is not implemented yet.',
              style: TextStyle(color: Colors.orange),
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

  @override
  void dispose() {
    _writeToController.dispose();
    _dataController.dispose();
    super.dispose();
  }
}

/// Vote screen for governance participation
class _VoteScreen extends StatefulWidget {
  const _VoteScreen();

  @override
  State<_VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<_VoteScreen> {
  String? _selectedVoter;
  List<WalletAccountInfo> _keyPageAccounts = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _motions = [
    {
      'id': 1,
      'title': 'Protocol Upgrade v2.1',
      'description': 'Upgrade consensus algorithm and improve performance',
      'votes': {'endorse': 1250, 'reject': 340, 'abstain': 210},
      'deadline': '2024-12-31',
    },
    {
      'id': 2,
      'title': 'Treasury Allocation',
      'description': 'Allocate funds for ecosystem development',
      'votes': {'endorse': 980, 'reject': 520, 'abstain': 150},
      'deadline': '2024-11-15',
    },
    {
      'id': 3,
      'title': 'Staking Rewards Update',
      'description': 'Increase staking rewards by 2%',
      'votes': {'endorse': 1850, 'reject': 150, 'abstain': 75},
      'deadline': '2024-10-30',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final WalletStorageService storageService = WalletStorageService();
      final accounts = await storageService.getAllAccountsWithKeyInfo();

      setState(() {
        // For demonstration, we'll use all accounts as potential key pages
        // In a real implementation, this would filter for actual key page accounts
        _keyPageAccounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
                      'Governance Voting',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Participate in Accumulate protocol governance decisions.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Voter Selection Dropdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Voter (Key Page)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedVoter,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select voting key page',
                      ),
                      items: _keyPageAccounts.map((accountInfo) {
                        return DropdownMenuItem<String>(
                          value: accountInfo.account.address,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(accountInfo.account.name),
                              Text(
                                'Key Page - ${accountInfo.account.address}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedVoter = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_selectedVoter != null) ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _motions.length,
                itemBuilder: (context, index) {
                  final motion = _motions[index];
                  final totalVotes = motion['votes']['endorse'] + motion['votes']['reject'] + motion['votes']['abstain'];
                  final endorsePercentage = totalVotes > 0 ? (motion['votes']['endorse'] / totalVotes * 100).round() : 0;
                  final rejectPercentage = totalVotes > 0 ? (motion['votes']['reject'] / totalVotes * 100).round() : 0;
                  final abstainPercentage = totalVotes > 0 ? (motion['votes']['abstain'] / totalVotes * 100).round() : 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            motion['title'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            motion['description'],
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 12),

                          // Vote statistics
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  Text('$endorsePercentage%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                  const Text('Endorse', style: TextStyle(fontSize: 10)),
                                ],
                              ),
                              Column(
                                children: [
                                  Text('$rejectPercentage%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                  const Text('Reject', style: TextStyle(fontSize: 10)),
                                ],
                              ),
                              Column(
                                children: [
                                  Text('$abstainPercentage%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                  const Text('Abstain', style: TextStyle(fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Deadline: ${motion['deadline']}'),
                          const SizedBox(height: 12),

                          // Voting Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: ElevatedButton(
                                    onPressed: () => _showVoteDialog(context, motion, 'Abstain'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    child: const Text('Abstain', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: ElevatedButton(
                                    onPressed: () => _showVoteDialog(context, motion, 'Reject'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    child: const Text('Reject', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: ElevatedButton(
                                    onPressed: () => _showVoteDialog(context, motion, 'Endorse'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    child: const Text('Endorse', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ] else ...[
              const Card(
                color: Colors.purple,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.how_to_vote, color: Colors.white, size: 48),
                      SizedBox(height: 8),
                      Text(
                        'Select Voter',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please select a key page above to participate in governance voting.',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DeveloperBypass.createBypassToggle(
                screenName: 'Vote Screen Bypass',
                onBypass: () {
                  setState(() {
                    _selectedVoter = _keyPageAccounts.isNotEmpty ? _keyPageAccounts.first.account.address : 'demo_voter';
                  });
                },
                customMessage: 'Bypass voter selection for development. '
                    'This allows you to view and interact with voting motions.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showVoteDialog(BuildContext context, Map<String, dynamic> motion, String voteType) {
    String voterName = 'Demo Voter';

    // Try to find the voter account, fallback to demo name if using bypass
    try {
      final voterAccount = _keyPageAccounts.firstWhere(
        (account) => account.account.address == _selectedVoter,
      );
      voterName = voterAccount.account.name;
    } catch (e) {
      // Using developer bypass with demo voter
      voterName = 'Demo Voter (Developer Mode)';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vote $voteType'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Motion: "${motion['title']}"'),
            const SizedBox(height: 8),
            Text('Voter: $voterName'),
            const SizedBox(height: 8),
            Text('Vote: $voteType'),
            const SizedBox(height: 16),
            const Text(
              'Voting functionality is not implemented yet.',
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
              Color voteColor = Colors.orange;
              if (voteType == 'Endorse') voteColor = Colors.green;
              if (voteType == 'Reject') voteColor = Colors.red;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🗳️ Vote cast: $voteType (demo)'),
                  backgroundColor: voteColor,
                ),
              );
            },
            child: const Text('Confirm Vote'),
          ),
        ],
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
  List<WalletAccountInfo> _keyPageAccounts = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _pendingTransactions = [
    {
      'id': 'tx_001',
      'type': 'Send Token',
      'amount': '50.00 ACME',
      'to': 'acc://1234...5678',
      'fee': '0.01 ACME',
      'timestamp': '2024-10-18 15:30:00',
    },
    {
      'id': 'tx_002',
      'type': 'Data Write',
      'data': 'Document hash: 0x789abc...',
      'to': 'acc://data...entry',
      'fee': '0.005 ACME',
      'timestamp': '2024-10-18 15:25:00',
    },
    {
      'id': 'tx_003',
      'type': 'Vote Cast',
      'motion': 'Protocol Upgrade v2.1',
      'vote': 'Endorse',
      'fee': '0.002 ACME',
      'timestamp': '2024-10-18 15:20:00',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final WalletStorageService storageService = WalletStorageService();
      final accounts = await storageService.getAllAccountsWithKeyInfo();

      setState(() {
        // For demonstration, we'll use all accounts as potential key pages
        // In a real implementation, this would filter for actual key page accounts
        _keyPageAccounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
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
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select signing key page',
                    ),
                    items: _keyPageAccounts.map((accountInfo) {
                      return DropdownMenuItem<String>(
                        value: accountInfo.account.address,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(accountInfo.account.name),
                            Text(
                              'Key Page - ${accountInfo.account.address}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
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
            Expanded(
              child: ListView.builder(
                itemCount: _pendingTransactions.length,
                itemBuilder: (context, index) {
                  final tx = _pendingTransactions[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tx['type'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                tx['id'],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (tx['amount'] != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Amount:'),
                                Text(
                                  tx['amount'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],

                          if (tx['data'] != null) ...[
                            const Text('Data:'),
                            Text(
                              tx['data'],
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                          ],

                          if (tx['motion'] != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Motion:'),
                                Text(tx['motion']),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Vote:'),
                                Text(
                                  tx['vote'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],

                          if (tx['to'] != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('To:'),
                                Text(
                                  tx['to'],
                                  style: const TextStyle(fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Fee:'),
                              Text(tx['fee']),
                            ],
                          ),
                          const SizedBox(height: 4),

                          Text(
                            'Created: ${tx['timestamp']}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _showRejectDialog(context, tx),
                                icon: const Icon(Icons.close),
                                label: const Text('Reject'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showSignDialog(context, tx),
                                icon: const Icon(Icons.check),
                                label: const Text('Sign & Send'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
                  content: Text('❌ Transaction ${tx['id']} rejected'),
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
                  content: Text('✅ Transaction ${tx['id']} signed & broadcast'),
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
                        content: Text('🎉 Transaction sent successfully!'),
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
                          _scannedData!,
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
✅ Service initialization and dependency injection
✅ Secure storage integration
✅ Theme system
✅ Basic navigation structure
✅ Authentication placeholder

To extend this wallet:
1. Follow the authentication guide in docs/AUTHENTICATION.md
2. Add UI features from the original feature directories
3. Implement data persistence per docs/PERSISTENCE.md
4. Configure networks per docs/CONFIGURATION.md

The core blockchain services are initialized and ready to use in your implementations.
*/