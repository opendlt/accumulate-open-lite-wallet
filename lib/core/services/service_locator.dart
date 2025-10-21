import 'package:flutter/foundation.dart';
// Service locator for dependency injection
import 'blockchain/accumulate_api_service.dart';
import 'blockchain/enhanced_accumulate_service.dart';
import 'crypto/key_management_service.dart';
import 'identity/identity_management_service.dart';
import 'token/token_management_service.dart';
import 'transaction/transaction_service.dart';
import 'data/data_service.dart';
import 'credits/purchase_credits_service.dart';
import 'faucet/faucet_service.dart';
import 'storage/database_helper.dart';
import 'networking/network_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Core services
  late final DatabaseHelper _databaseHelper;
  late final NetworkService _networkService;
  late final KeyManagementService _keyManagementService;
  late final IdentityManagementService _identityManagementService;
  late final TokenManagementService _tokenManagementService;
  late final TransactionService _transactionService;
  late final DataService _dataService;
  late final PurchaseCreditsService _purchaseCreditsService;
  late final FaucetService _faucetService;
  late final AccumulateApiService _accumulateApiService;
  late final EnhancedAccumulateService _enhancedAccumulateService;

  bool _isInitialized = false;

  /// Initialize all services
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize core services
    _databaseHelper = DatabaseHelper();
    _networkService = NetworkService();

    // Initialize crypto service
    _keyManagementService = KeyManagementService(
      dbHelper: _databaseHelper,
    );

    // Initialize identity management
    _identityManagementService = IdentityManagementService(
      dbHelper: _databaseHelper,
      keyService: _keyManagementService,
    );

    // Initialize token management
    _tokenManagementService = TokenManagementService(
      dbHelper: _databaseHelper,
    );

    // Initialize API services
    _accumulateApiService = AccumulateApiService();
    _enhancedAccumulateService = EnhancedAccumulateService(
      keyService: _keyManagementService,
    );

    // Initialize transaction services
    _transactionService = TransactionService(
      dbHelper: _databaseHelper,
      keyService: _keyManagementService,
      accumulateService: _enhancedAccumulateService,
    );


    // Initialize data service
    _dataService = DataService(
      dbHelper: _databaseHelper,
      keyService: _keyManagementService,
      accumulateService: _enhancedAccumulateService,
    );

    // Initialize purchase credits service
    _purchaseCreditsService = PurchaseCreditsService(
      dbHelper: _databaseHelper,
      keyService: _keyManagementService,
      accumulateService: _enhancedAccumulateService,
      identityService: _identityManagementService,
      tokenService: _tokenManagementService,
    );

    // Initialize faucet service
    _faucetService = FaucetService(
      dbHelper: _databaseHelper,
      keyService: _keyManagementService,
      accumulateService: _enhancedAccumulateService,
      tokenService: _tokenManagementService,
    );

    _isInitialized = true;
  }

  /// Get database helper
  DatabaseHelper get databaseHelper {
    _ensureInitialized();
    return _databaseHelper;
  }

  /// Get network service
  NetworkService get networkService {
    _ensureInitialized();
    return _networkService;
  }

  /// Get key management service
  KeyManagementService get keyManagementService {
    _ensureInitialized();
    return _keyManagementService;
  }

  /// Get identity management service
  IdentityManagementService get identityManagementService {
    _ensureInitialized();
    return _identityManagementService;
  }

  /// Get token management service
  TokenManagementService get tokenManagementService {
    _ensureInitialized();
    return _tokenManagementService;
  }

  /// Get accumulate API service
  AccumulateApiService get accumulateApiService {
    _ensureInitialized();
    return _accumulateApiService;
  }

  /// Get enhanced accumulate service
  EnhancedAccumulateService get enhancedAccumulateService {
    _ensureInitialized();
    return _enhancedAccumulateService;
  }

  /// Get transaction service
  TransactionService get transactionService {
    _ensureInitialized();
    return _transactionService;
  }


  /// Get data service
  DataService get dataService {
    _ensureInitialized();
    return _dataService;
  }

  /// Get purchase credits service
  PurchaseCreditsService get purchaseCreditsService {
    _ensureInitialized();
    return _purchaseCreditsService;
  }

  /// Get faucet service
  FaucetService get faucetService {
    _ensureInitialized();
    return _faucetService;
  }

  /// Ensure services are initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('ServiceLocator must be initialized before use. Call initialize() first.');
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    if (_isInitialized) {
      await _keyManagementService.clearAllKeys();
      await _databaseHelper.close();
      _isInitialized = false;
    }
  }

  /// Reset all services (for logout)
  Future<void> reset() async {
    await dispose();
    await initialize();
  }
}

/// Global service locator instance
final serviceLocator = ServiceLocator();