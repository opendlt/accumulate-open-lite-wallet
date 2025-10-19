// Core user repository - abstracts data access
import '../services/storage/secure_storage_interface.dart';
import '../models/user_identity.dart';

class UserRepository {
  final SecureStorageInterface _storage;

  UserRepository(this._storage);

  /// Save user data to storage
  Future<void> saveUser(UserIdentity user) async {
    await _storage.write('userId', user.userId);
    await _storage.write('username_${user.userId}', user.username);
    await _storage.write('publicKey_${user.userId}', user.publicKey);
    await _storage.write('publicKeyHash_${user.userId}', user.publicKeyHash);
  }

  /// Load user from storage
  Future<UserIdentity?> loadUser() async {
    final userId = await _storage.read('userId');
    if (userId == null) return null;

    final username = await _storage.read('username_$userId');
    final publicKey = await _storage.read('publicKey_$userId');
    final publicKeyHash = await _storage.read('publicKeyHash_$userId');

    if (username == null || publicKey == null || publicKeyHash == null) {
      return null;
    }

    return UserIdentity(
      userId: userId,
      username: username,
      publicKey: publicKey,
      publicKeyHash: publicKeyHash,
      email: '$username@accu2.io',
    );
  }

  /// Check if user exists in storage
  Future<bool> hasUser() async {
    final userId = await _storage.read('userId');
    return userId != null;
  }

  /// Delete user from storage
  Future<void> deleteUser() async {
    final userId = await _storage.read('userId');
    if (userId != null) {
      await _storage.delete('privateKey_$userId');
      await _storage.delete('publicKey_$userId');
      await _storage.delete('publicKeyHash_$userId');
      await _storage.delete('username_$userId');
    }
    await _storage.delete('userId');
  }

  /// Get user settings
  Future<Map<String, dynamic>> getUserSettings() async {
    final addTxMemos = await _storage.read('add_tx_memos');

    return {
      'addTxMemosEnabled': addTxMemos == 'true',
    };
  }

  /// Save user settings
  Future<void> saveUserSettings(Map<String, dynamic> settings) async {
    if (settings.containsKey('addTxMemosEnabled')) {
      await _storage.write(
          'add_tx_memos', settings['addTxMemosEnabled'].toString());
    }
  }
}
