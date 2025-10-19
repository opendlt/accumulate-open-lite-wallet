// Core dependency injection - no Flutter dependencies
import '../services/storage/secure_storage_interface.dart';
import '../services/networking/network_service.dart';
import '../services/blockchain/accumulate_api_service.dart';
import '../services/identity/core_identity_service.dart';
import '../services/pending_tx/core_pending_tx_service.dart';
// Activity service removed - implement if needed
import '../repositories/user_repository.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};

  /// Register a service
  void register<T>(T service) {
    _services[T] = service;
  }

  /// Get a service
  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T not registered');
    }
    return service as T;
  }

  /// Check if service is registered
  bool isRegistered<T>() {
    return _services.containsKey(T);
  }

  /// Clear all services
  void clear() {
    _services.clear();
  }

  /// Initialize core services with provided storage adapter
  void initializeCoreServices(SecureStorageInterface storageAdapter) {
    // Register storage adapter
    register<SecureStorageInterface>(storageAdapter);

    // Register networking
    register<NetworkService>(NetworkService());

    // Register API service
    register<AccumulateApiService>(AccumulateApiService());

    // Register repositories
    register<UserRepository>(UserRepository(storageAdapter));

    // Register core services
    register<CoreIdentityService>(CoreIdentityService(storageAdapter));
    register<CorePendingTxService>(CorePendingTxService(
      get<AccumulateApiService>(),
    ));
    // Activity service removed - implement if needed
  }
}

/// Convenience getters for commonly used services
extension ServiceLocatorExtensions on ServiceLocator {
  UserRepository get userRepository => get<UserRepository>();
  CoreIdentityService get identityService => get<CoreIdentityService>();
  CorePendingTxService get pendingTxService => get<CorePendingTxService>();
  // Activity service removed - implement if needed
  AccumulateApiService get apiService => get<AccumulateApiService>();
  NetworkService get networkService => get<NetworkService>();
}
