import 'package:flutter/foundation.dart';
// Key management service for cryptographic operations
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:accumulate_api/accumulate_api.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/accumulate_requests.dart';
import '../../models/local_storage_models.dart';
import '../../constants/app_constants.dart';
import '../storage/database_helper.dart';
import '../storage/secure_keys_service.dart';

class KeyManagementService {
  final SecureKeysService _secureKeysService;
  final DatabaseHelper _dbHelper;

  KeyManagementService({
    SecureKeysService? secureKeysService,
    DatabaseHelper? dbHelper,
  }) : _secureKeysService = secureKeysService ?? SecureKeysService(),
       _dbHelper = dbHelper ?? DatabaseHelper();

  /// Generate a new Ed25519 key pair
  Future<KeyPairData> generateKeyPair() async {
    final keyPair = Ed25519KeypairSigner.generate();

    final publicKey = keyPair.publicKey();
    final privateKey = keyPair.secretKey();
    final publicKeyHash = keyPair.publicKeyHash();

    return KeyPairData(
      publicKey: _bytesToHex(publicKey),
      privateKey: _bytesToHex(privateKey),
      publicKeyHash: _bytesToHex(publicKeyHash),
    );
  }

  /// Create a lite identity signer from an address
  Future<LiteIdentity?> createLiteIdentitySigner(String address) async {
    try {
      debugPrint('Looking for private key for address: $address');

      // Use SecureKeysService to get private key - this ensures we use the same storage instance
      final privateKeyHex = await _secureKeysService.getPrivateKey(address);
      if (privateKeyHex != null) {
        debugPrint(' Found private key for address: $address');
        final privateKeyBytes = _hexToBytes(privateKeyHex);
        final keyPair = Ed25519KeypairSigner.fromKeyRaw(privateKeyBytes);
        return LiteIdentity(keyPair);
      }

      debugPrint(' No private key found for address: $address');
      return null;
    } catch (e) {
      debugPrint(' Error creating lite identity signer: $e');
      return null;
    }
  }

  /// Debug method to check what keys exist for an account
  Future<Map<String, bool>> debugAccountKeys(String accountAddress) async {
    try {
      final baseAddress = accountAddress.endsWith('/ACME')
          ? accountAddress.substring(0, accountAddress.length - 5)
          : accountAddress;
      final tokenAddress = accountAddress.endsWith('/ACME')
          ? accountAddress
          : '$accountAddress/ACME';

      final results = <String, bool>{};

      // Check if private keys exist for both base and token addresses
      final hasBaseKey = await _secureKeysService.hasPrivateKey(baseAddress);
      final hasTokenKey = await _secureKeysService.hasPrivateKey(tokenAddress);

      results['base_address_$baseAddress'] = hasBaseKey;
      results['token_address_$tokenAddress'] = hasTokenKey;

      debugPrint('Debug key check results:');
      debugPrint('   - Base address ($baseAddress): ${hasBaseKey ? '' : ''}');
      debugPrint('   - Token address ($tokenAddress): ${hasTokenKey ? '' : ''}');

      return results;
    } catch (e) {
      debugPrint(' Error checking account keys: $e');
      return {};
    }
  }

  /// Create an ADI signer from a key page URL
  Future<TxSigner?> createADISigner(String keyPageUrl) async {
    try {
      debugPrint('ADI SIGNER: Starting creation for key page: $keyPageUrl');

      // First try the old database approach (key_pages table)
      debugPrint('ADI SIGNER: Checking old key_pages table...');
      final keyPage = await _getKeyPageByUrl(keyPageUrl);
      if (keyPage != null) {
        debugPrint(' ADI SIGNER: Found key page in key_pages table');

        // Get the first available key from the key page
        final keys = await _getKeysByKeyPageId(keyPage.id!);
        debugPrint('ADI SIGNER: Found ${keys.length} keys for key page');

        if (keys.isEmpty) {
          debugPrint(' ADI SIGNER: No keys found in key_pages table');
          return null;
        }

        final key = keys.first;

        // Decrypt the private key
        debugPrint('🔐 ADI SIGNER: Decrypting private key from key_pages table...');
        final privateKeyBytes = await _decryptPrivateKey(key.privateKeyEncrypted);
        if (privateKeyBytes == null) {
          debugPrint(' ADI SIGNER: Failed to decrypt private key from key_pages table');
          return null;
        }

        debugPrint(' ADI SIGNER: Successfully decrypted private key from key_pages table');
        final keyPair = Ed25519KeypairSigner.fromKeyRaw(privateKeyBytes);
        var signer = TxSigner(keyPageUrl, keyPair);

        // Get the current version for this signer from the network
        return await _queryVersionAndCreateSigner(signer, keyPageUrl);
      }

      // New approach: Check if the key page exists as a regular account with private key in secure storage
      debugPrint('ADI SIGNER: Key page not found in key_pages table, trying secure storage...');

      // Check if we have a private key for this key page URL in secure storage
      final privateKeyHex = await _secureKeysService.getPrivateKey(keyPageUrl);
      if (privateKeyHex != null) {
        debugPrint(' ADI SIGNER: Found private key in secure storage for: $keyPageUrl');

        final privateKeyBytes = _hexToBytes(privateKeyHex);
        final keyPair = Ed25519KeypairSigner.fromKeyRaw(privateKeyBytes);
        var signer = TxSigner(keyPageUrl, keyPair);

        debugPrint(' ADI SIGNER: Successfully created signer from secure storage');
        return await _queryVersionAndCreateSigner(signer, keyPageUrl);
      }

      debugPrint(' ADI SIGNER: No private key found in secure storage for: $keyPageUrl');
      debugPrint(' ADI SIGNER: Key page not found in either key_pages table or secure storage');
      return null;

    } catch (e) {
      debugPrint(' ADI SIGNER: Exception during creation: $e');
      return null;
    }
  }

  /// Helper method to query version and create final signer
  Future<TxSigner?> _queryVersionAndCreateSigner(TxSigner signer, String keyPageUrl) async {
    try {
      // Get the current version for this signer from the network
      debugPrint('ADI SIGNER: Querying key page version from network...');
      final client = ACMEClient(AppConstants.defaultAccumulateKermitTestnetUrl); // Use Kermit testnet endpoint
      final response = await client.queryUrl(keyPageUrl);

      if (response['result'] != null && response['result']['data'] != null) {
        final version = response['result']['data']['version'] ?? 1;
        debugPrint('ADI SIGNER: Key page version for $keyPageUrl: $version');
        return TxSigner.withNewVersion(signer, version);
      }
    } catch (e) {
      debugPrint(' ADI SIGNER: Failed to query key page version: $e');
    }

    // Fallback to version 1 if query fails
    debugPrint('ADI SIGNER: Using fallback version 1');
    return TxSigner.withNewVersion(signer, 1);
  }

  /// Store a private key securely
  Future<void> storePrivateKey(String keyId, String privateKeyHex) async {
    await _secureKeysService.storeDerivatedKey('custom', keyId, privateKeyHex);
  }

  /// Store a lite account private key
  Future<void> storeLiteAccountKey(String address, String privateKeyHex) async {
    await _secureKeysService.storePrivateKey(address, privateKeyHex);
  }

  /// Store an encrypted private key for ADI keys
  Future<String> encryptPrivateKey(String privateKeyHex, String passphrase) async {
    // Simple encryption - in production, use proper encryption
    final bytes = _hexToBytes(privateKeyHex);
    final passphraseBytes = _hexToBytes(sha256.convert(passphrase.codeUnits).toString());

    final encrypted = <int>[];
    for (int i = 0; i < bytes.length; i++) {
      encrypted.add(bytes[i] ^ passphraseBytes[i % passphraseBytes.length]);
    }

    return _bytesToHex(Uint8List.fromList(encrypted));
  }

  /// Decrypt a private key
  Future<Uint8List?> _decryptPrivateKey(String encryptedHex) async {
    try {
      // Get the passphrase from secure storage via SecureKeysService
      final passphrase = await _secureKeysService.getDerivedKey('master', 'passphrase');
      if (passphrase == null) {
        return null;
      }

      final encryptedBytes = _hexToBytes(encryptedHex);
      final passphraseBytes = _hexToBytes(sha256.convert(passphrase.codeUnits).toString());

      final decrypted = <int>[];
      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ passphraseBytes[i % passphraseBytes.length]);
      }

      return Uint8List.fromList(decrypted);
    } catch (e) {
      return null;
    }
  }

  /// Generate a mnemonic seed phrase
  Future<String> generateMnemonic() async {
    // For now, we'll just generate a simple random key
    // In production, use proper BIP39 mnemonic generation
    final keyPair = Ed25519KeypairSigner.generate();
    return _bytesToHex(keyPair.secretKey());
  }

  /// Import a key from mnemonic
  Future<KeyPairData> importFromMnemonic(String mnemonic) async {
    // For now, we'll treat the mnemonic as a hex private key
    // In production, derive from proper BIP39 mnemonic
    final privateKeyBytes = _hexToBytes(mnemonic);
    final keyPair = Ed25519KeypairSigner.fromKeyRaw(privateKeyBytes);

    return KeyPairData(
      publicKey: _bytesToHex(keyPair.publicKey()),
      privateKey: _bytesToHex(keyPair.secretKey()),
      publicKeyHash: _bytesToHex(keyPair.publicKeyHash()),
    );
  }

  /// Validate a private key format
  bool isValidPrivateKey(String privateKeyHex) {
    try {
      final bytes = _hexToBytes(privateKeyHex);
      return bytes.length == 32; // Ed25519 private keys are 32 bytes
    } catch (e) {
      return false;
    }
  }

  /// Get key page by URL from database
  Future<AccumulateKeyPage?> _getKeyPageByUrl(String url) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'key_pages',
      where: 'url = ? AND is_active = ?',
      whereArgs: [url, 1],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return AccumulateKeyPage.fromMap(maps.first);
    }
    return null;
  }

  /// Get keys by key page ID from database
  Future<List<AccumulateKey>> _getKeysByKeyPageId(int keyPageId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'keys',
      where: 'key_page_id = ? AND is_active = ?',
      whereArgs: [keyPageId, 1],
      orderBy: 'is_default DESC', // Default keys first
    );

    return maps.map((map) => AccumulateKey.fromMap(map)).toList();
  }

  /// Convert bytes to hex string
  String _bytesToHex(Uint8List bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Convert hex string to bytes
  Uint8List _hexToBytes(String hex) {
    final bytes = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  /// Set master passphrase for encryption
  Future<void> setMasterPassphrase(String passphrase) async {
    await _secureKeysService.storeDerivatedKey('master', 'passphrase', passphrase);
  }

  /// Check if master passphrase is set
  Future<bool> hasMasterPassphrase() async {
    final passphrase = await _secureKeysService.getDerivedKey('master', 'passphrase');
    return passphrase != null;
  }

  /// Clear all stored keys (for logout/reset)
  Future<void> clearAllKeys() async {
    await _secureKeysService.clearAllSecureData();
  }

  /// Store ADI key in database with encrypted private key
  Future<int> storeADIKey({
    required int keyPageId,
    required String name,
    required String publicKey,
    required String privateKey,
    required String publicKeyHash,
    bool isDefault = false,
  }) async {
    // Encrypt the private key
    final passphrase = await _secureKeysService.getDerivedKey('master', 'passphrase') ?? 'default';
    final encryptedPrivateKey = await encryptPrivateKey(privateKey, passphrase);

    final key = AccumulateKey(
      keyPageId: keyPageId,
      name: name,
      publicKey: publicKey,
      privateKeyEncrypted: encryptedPrivateKey,
      publicKeyHash: publicKeyHash,
      isDefault: isDefault,
    );

    final db = await _dbHelper.database;
    return await db.insert('keys', key.toMap());
  }

  /// Get all keys for a key page
  Future<List<AccumulateKey>> getKeysForKeyPage(int keyPageId) async {
    return await _getKeysByKeyPageId(keyPageId);
  }

  /// Get key by public key hash
  Future<AccumulateKey?> getKeyByPublicKeyHash(String publicKeyHash) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'keys',
      where: 'public_key_hash = ? AND is_active = ?',
      whereArgs: [publicKeyHash, 1],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return AccumulateKey.fromMap(maps.first);
    }
    return null;
  }

  /// Get raw Ed25519KeypairSigner for ADI key page (for direct TxSigner creation)
  Future<Ed25519KeypairSigner?> getADIPrivateKeySigner(String keyPageUrl) async {
    try {
      debugPrint('RAW SIGNER: Starting creation for key page: $keyPageUrl');

      // First try the old database approach (key_pages table)
      debugPrint('RAW SIGNER: Checking old key_pages table...');
      final keyPage = await _getKeyPageByUrl(keyPageUrl);
      if (keyPage != null) {
        debugPrint(' RAW SIGNER: Found key page in key_pages table');

        // Get the first available key from the key page
        final keys = await _getKeysByKeyPageId(keyPage.id!);
        debugPrint('RAW SIGNER: Found ${keys.length} keys for key page');

        if (keys.isEmpty) {
          debugPrint(' RAW SIGNER: No keys found in key_pages table');
          return null;
        }

        final key = keys.first;

        // Decrypt the private key
        debugPrint('RAW SIGNER: Decrypting private key from key_pages table...');
        final privateKeyBytes = await _decryptPrivateKey(key.privateKeyEncrypted);
        if (privateKeyBytes == null) {
          debugPrint('RAW SIGNER: Failed to decrypt private key from key_pages table');
          return null;
        }

        debugPrint('RAW SIGNER: Successfully decrypted private key from key_pages table');
        return Ed25519KeypairSigner.fromKeyRaw(privateKeyBytes);
      }

      // New approach: Check if the key page exists as a regular account with private key in secure storage
      debugPrint('RAW SIGNER: Key page not found in key_pages table, trying secure storage...');

      // Check if we have a private key for this key page URL in secure storage
      final privateKeyHex = await _secureKeysService.getPrivateKey(keyPageUrl);
      if (privateKeyHex != null) {
        debugPrint('RAW SIGNER: Found private key in secure storage for: $keyPageUrl');

        final privateKeyBytes = _hexToBytes(privateKeyHex);
        debugPrint('RAW SIGNER: Successfully created raw signer from secure storage');
        return Ed25519KeypairSigner.fromKeyRaw(privateKeyBytes);
      }

      debugPrint('RAW SIGNER: No private key found in secure storage for: $keyPageUrl');
      debugPrint('RAW SIGNER: Key page not found in either key_pages table or secure storage');
      return null;

    } catch (e) {
      debugPrint('RAW SIGNER: Exception during creation: $e');
      return null;
    }
  }

  /// Get private key bytes for a given address
  Future<Uint8List?> getPrivateKeyBytes(String address) async {
    try {
      final privateKeyHex = await _secureKeysService.getPrivateKey(address);
      if (privateKeyHex != null) {
        return _hexToBytes(privateKeyHex);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting private key bytes: $e');
      return null;
    }
  }

  /// Get public key bytes for a given address
  Future<Uint8List?> getPublicKeyBytes(String address) async {
    try {
      final privateKeyBytes = await getPrivateKeyBytes(address);
      if (privateKeyBytes != null) {
        final keyPair = Ed25519KeypairSigner.fromKeyRaw(privateKeyBytes);
        return keyPair.publicKey();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting public key bytes: $e');
      return null;
    }
  }
}