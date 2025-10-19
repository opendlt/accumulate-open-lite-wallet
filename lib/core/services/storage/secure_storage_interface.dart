// Core storage interface - no Flutter dependencies

/// Abstract interface for secure storage operations
/// This allows the core business logic to be independent of Flutter's secure storage
abstract class SecureStorageInterface {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
  Future<Map<String, String>> readAll();
}

/// Core secure storage service that works with any implementation
class SecureStorageCoreService {
  final SecureStorageInterface _storage;

  SecureStorageCoreService(this._storage);

  // User-related storage operations
  Future<String?> getUserId() async {
    return await _storage.read('userId');
  }

  Future<void> setUserId(String userId) async {
    await _storage.write('userId', userId);
  }

  Future<String?> getUsername(String userId) async {
    return await _storage.read('username_$userId');
  }

  Future<void> setUsername(String userId, String username) async {
    await _storage.write('username_$userId', username);
  }

  Future<String?> getPublicKey(String userId) async {
    return await _storage.read('publicKey_$userId');
  }

  Future<void> setPublicKey(String userId, String publicKey) async {
    await _storage.write('publicKey_$userId', publicKey);
  }

  Future<String?> getPrivateKey(String userId) async {
    return await _storage.read('privateKey_$userId');
  }

  Future<void> setPrivateKey(String userId, String privateKey) async {
    await _storage.write('privateKey_$userId', privateKey);
  }

  Future<String?> getPublicKeyHash(String userId) async {
    return await _storage.read('publicKeyHash_$userId');
  }

  Future<void> setPublicKeyHash(String userId, String publicKeyHash) async {
    await _storage.write('publicKeyHash_$userId', publicKeyHash);
  }

  // Settings
  Future<bool> getAddTxMemosEnabled() async {
    final value = await _storage.read('add_tx_memos');
    return value == 'true';
  }

  Future<void> setAddTxMemosEnabled(bool enabled) async {
    await _storage.write('add_tx_memos', enabled.toString());
  }

  // Clear all user data
  Future<void> clearUserData(String userId) async {
    await _storage.delete('privateKey_$userId');
    await _storage.delete('publicKey_$userId');
    await _storage.delete('publicKeyHash_$userId');
    await _storage.delete('userId');
    await _storage.delete('username_$userId');
  }
}
