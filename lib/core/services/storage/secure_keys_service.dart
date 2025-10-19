// Enhanced secure storage service for managing cryptographic keys
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';

class SecureKeysService {
  static final SecureKeysService _instance = SecureKeysService._internal();
  factory SecureKeysService() => _instance;
  SecureKeysService._internal();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    wOptions: WindowsOptions(),
    lOptions: LinuxOptions(),
  );

  // Key prefixes for organization
  static const String _privateKeyPrefix = 'priv_key_';
  static const String _publicKeyPrefix = 'pub_key_';
  static const String _mnemonicPrefix = 'mnemonic_';
  static const String _seedPrefix = 'seed_';
  static const String _pinPrefix = 'pin_';
  static const String _biometricPrefix = 'bio_';

  // ===== PRIVATE KEY MANAGEMENT =====

  /// Store a private key for a specific account address
  Future<void> storePrivateKey(String address, String privateKey) async {
    final key = _privateKeyPrefix + address;
    await _storage.write(key: key, value: privateKey);
  }

  /// Retrieve a private key for a specific account address
  Future<String?> getPrivateKey(String address) async {
    final key = _privateKeyPrefix + address;
    return await _storage.read(key: key);
  }

  /// Check if a private key exists for an account
  Future<bool> hasPrivateKey(String address) async {
    final privateKey = await getPrivateKey(address);
    return privateKey != null && privateKey.isNotEmpty;
  }

  /// Delete a private key for a specific account
  Future<void> deletePrivateKey(String address) async {
    final key = _privateKeyPrefix + address;
    await _storage.delete(key: key);
  }

  /// Get all account addresses that have stored private keys
  Future<List<String>> getAccountsWithKeys() async {
    final allKeys = await _storage.readAll();
    final addresses = <String>[];

    for (final key in allKeys.keys) {
      if (key.startsWith(_privateKeyPrefix)) {
        final address = key.substring(_privateKeyPrefix.length);
        addresses.add(address);
      }
    }

    return addresses;
  }

  // ===== PUBLIC KEY MANAGEMENT =====

  /// Store a public key for a specific account address
  Future<void> storePublicKey(String address, String publicKey) async {
    final key = _publicKeyPrefix + address;
    await _storage.write(key: key, value: publicKey);
  }

  /// Retrieve a public key for a specific account address
  Future<String?> getPublicKey(String address) async {
    final key = _publicKeyPrefix + address;
    return await _storage.read(key: key);
  }

  /// Delete a public key for a specific account
  Future<void> deletePublicKey(String address) async {
    final key = _publicKeyPrefix + address;
    await _storage.delete(key: key);
  }

  // ===== MNEMONIC PHRASE MANAGEMENT =====

  /// Store a mnemonic phrase for wallet recovery
  Future<void> storeMnemonic(String walletId, String mnemonic) async {
    final key = _mnemonicPrefix + walletId;
    await _storage.write(key: key, value: mnemonic);
  }

  /// Retrieve a mnemonic phrase for wallet recovery
  Future<String?> getMnemonic(String walletId) async {
    final key = _mnemonicPrefix + walletId;
    return await _storage.read(key: key);
  }

  /// Check if a mnemonic exists for a wallet
  Future<bool> hasMnemonic(String walletId) async {
    final mnemonic = await getMnemonic(walletId);
    return mnemonic != null && mnemonic.isNotEmpty;
  }

  /// Delete a mnemonic phrase
  Future<void> deleteMnemonic(String walletId) async {
    final key = _mnemonicPrefix + walletId;
    await _storage.delete(key: key);
  }

  // ===== SEED MANAGEMENT =====

  /// Store a wallet seed
  Future<void> storeSeed(String walletId, Uint8List seed) async {
    final key = _seedPrefix + walletId;
    final seedBase64 = base64.encode(seed);
    await _storage.write(key: key, value: seedBase64);
  }

  /// Retrieve a wallet seed
  Future<Uint8List?> getSeed(String walletId) async {
    final key = _seedPrefix + walletId;
    final seedBase64 = await _storage.read(key: key);
    if (seedBase64 != null) {
      return base64.decode(seedBase64);
    }
    return null;
  }

  /// Delete a wallet seed
  Future<void> deleteSeed(String walletId) async {
    final key = _seedPrefix + walletId;
    await _storage.delete(key: key);
  }

  // ===== PIN AND AUTHENTICATION =====

  /// Store a hashed PIN for local authentication
  Future<void> storePin(String pin) async {
    final hashedPin = _hashPin(pin);
    await _storage.write(key: _pinPrefix + 'hash', value: hashedPin);
  }

  /// Verify a PIN against the stored hash
  Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: _pinPrefix + 'hash');
    if (storedHash == null) return false;

    final inputHash = _hashPin(pin);
    return storedHash == inputHash;
  }

  /// Check if a PIN is set
  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _pinPrefix + 'hash');
    return hash != null && hash.isNotEmpty;
  }

  /// Delete the stored PIN
  Future<void> deletePin() async {
    await _storage.delete(key: _pinPrefix + 'hash');
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin + 'accumulate_salt'); // Add salt
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ===== BIOMETRIC AUTHENTICATION =====

  /// Store biometric authentication preference
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _biometricPrefix + 'enabled',
      value: enabled.toString(),
    );
  }

  /// Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricPrefix + 'enabled');
    return value == 'true';
  }

  /// Store a token for biometric authentication
  Future<void> storeBiometricToken(String token) async {
    await _storage.write(key: _biometricPrefix + 'token', value: token);
  }

  /// Retrieve the biometric authentication token
  Future<String?> getBiometricToken() async {
    return await _storage.read(key: _biometricPrefix + 'token');
  }

  /// Delete biometric authentication data
  Future<void> deleteBiometricData() async {
    await _storage.delete(key: _biometricPrefix + 'enabled');
    await _storage.delete(key: _biometricPrefix + 'token');
  }

  // ===== KEY DERIVATION =====

  /// Derive a key for specific purposes (encryption, signing, etc.)
  Future<void> storeDerivatedKey(String purpose, String address, String key) async {
    final storageKey = '${purpose}_key_$address';
    await _storage.write(key: storageKey, value: key);
  }

  /// Retrieve a derived key
  Future<String?> getDerivedKey(String purpose, String address) async {
    final storageKey = '${purpose}_key_$address';
    return await _storage.read(key: storageKey);
  }

  /// Delete a derived key
  Future<void> deleteDerivedKey(String purpose, String address) async {
    final storageKey = '${purpose}_key_$address';
    await _storage.delete(key: storageKey);
  }

  // ===== UTILITY METHODS =====

  /// Clear all stored keys and authentication data
  Future<void> clearAllSecureData() async {
    await _storage.deleteAll();
  }

  /// Get a count of stored keys by type
  Future<Map<String, int>> getKeyStatistics() async {
    final allKeys = await _storage.readAll();

    int privateKeys = 0;
    int publicKeys = 0;
    int mnemonics = 0;
    int seeds = 0;
    int other = 0;

    for (final key in allKeys.keys) {
      if (key.startsWith(_privateKeyPrefix)) {
        privateKeys++;
      } else if (key.startsWith(_publicKeyPrefix)) {
        publicKeys++;
      } else if (key.startsWith(_mnemonicPrefix)) {
        mnemonics++;
      } else if (key.startsWith(_seedPrefix)) {
        seeds++;
      } else {
        other++;
      }
    }

    return {
      'privateKeys': privateKeys,
      'publicKeys': publicKeys,
      'mnemonics': mnemonics,
      'seeds': seeds,
      'other': other,
    };
  }

  /// Export encrypted backup of keys (for backup purposes)
  Future<String?> exportEncryptedBackup(String password) async {
    try {
      final allKeys = await _storage.readAll();
      final backup = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'keys': allKeys,
      };

      final backupJson = jsonEncode(backup);
      // In production, implement proper encryption with the password
      // For now, just return base64 encoded
      return base64.encode(utf8.encode(backupJson));
    } catch (e) {
      return null;
    }
  }

  /// Import keys from encrypted backup
  Future<bool> importEncryptedBackup(String encryptedBackup, String password) async {
    try {
      // In production, implement proper decryption with the password
      final backupJson = utf8.decode(base64.decode(encryptedBackup));
      final backup = jsonDecode(backupJson) as Map<String, dynamic>;

      final keys = backup['keys'] as Map<String, dynamic>;

      // Import all keys
      for (final entry in keys.entries) {
        await _storage.write(key: entry.key, value: entry.value);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if the secure storage is available and working
  Future<bool> isSecureStorageAvailable() async {
    try {
      const testKey = 'test_key';
      const testValue = 'test_value';

      await _storage.write(key: testKey, value: testValue);
      final retrievedValue = await _storage.read(key: testKey);
      await _storage.delete(key: testKey);

      return retrievedValue == testValue;
    } catch (e) {
      return false;
    }
  }
}