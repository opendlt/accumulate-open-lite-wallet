// Core identity service - no Flutter dependencies
import 'package:accumulate_api/accumulate_api.dart';
import '../storage/secure_storage_interface.dart';
import '../../models/user_identity.dart';
import '../../utils/crypto_utils.dart';

class CoreIdentityService {
  final SecureStorageInterface _storage;

  CoreIdentityService(this._storage);

  /// Generate a new identity with keypair
  Future<UserIdentity> generateIdentity(
      String userId, String username, String email) async {
    // Generate key pair
    final newKeySigner = Ed25519KeypairSigner.generate();
    final publicKeyHash = newKeySigner.publicKeyHash();
    final privateKey = newKeySigner.secretKey();
    final publicKey = newKeySigner.publicKey();

    // Convert to hex strings
    final privateKeyHex = CryptoUtils.bytesToHex(privateKey);
    final publicKeyHex = CryptoUtils.bytesToHex(publicKey);
    final publicKeyHashHex = CryptoUtils.bytesToHex(publicKeyHash);

    // Create identity object
    final identity = UserIdentity(
      userId: userId,
      username: username,
      publicKey: publicKeyHex,
      publicKeyHash: publicKeyHashHex,
      email: email,
    );

    // Store keys securely
    await _storage.write("privateKey_$userId", privateKeyHex);
    await _storage.write("publicKey_$userId", publicKeyHex);
    await _storage.write("publicKeyHash_$userId", publicKeyHashHex);
    await _storage.write("userId", userId);
    await _storage.write("username_$userId", username);

    return identity;
  }

  /// Retrieve stored identity
  Future<UserIdentity?> getStoredIdentity() async {
    final userId = await _storage.read("userId");
    if (userId == null) return null;

    final username = await _storage.read("username_$userId");
    final publicKey = await _storage.read("publicKey_$userId");
    final publicKeyHash = await _storage.read("publicKeyHash_$userId");

    if (username == null || publicKey == null || publicKeyHash == null) {
      return null;
    }

    return UserIdentity(
      userId: userId,
      username: username,
      publicKey: publicKey,
      publicKeyHash: publicKeyHash,
      email: "$username@accu2.io", // Generate from username
    );
  }

  /// Get keypair for signing
  Future<KeyPair?> getKeyPair() async {
    final userId = await _storage.read("userId");
    if (userId == null) return null;

    final publicKey = await _storage.read("publicKey_$userId");
    final privateKey = await _storage.read("privateKey_$userId");
    final publicKeyHash = await _storage.read("publicKeyHash_$userId");

    if (publicKey == null || privateKey == null || publicKeyHash == null) {
      return null;
    }

    return KeyPair(
      publicKey: publicKey,
      privateKey: privateKey,
      publicKeyHash: publicKeyHash,
    );
  }

  /// Create signer from stored private key
  Future<Ed25519KeypairSigner?> createSigner() async {
    final keyPair = await getKeyPair();
    if (keyPair == null) return null;

    try {
      final privateKeyBytes = CryptoUtils.hexToBytes(keyPair.privateKey);
      // For now, return null - this would need the correct accumulate_api method
      // return Ed25519KeypairSigner.fromSecretKey(privateKeyBytes);
      return null; // TODO: Use correct method from accumulate_api
    } catch (e) {
      return null;
    }
  }

  /// Clear all identity data
  Future<void> clearIdentity() async {
    final userId = await _storage.read("userId");
    if (userId != null) {
      await _storage.delete("privateKey_$userId");
      await _storage.delete("publicKey_$userId");
      await _storage.delete("publicKeyHash_$userId");
      await _storage.delete("username_$userId");
    }
    await _storage.delete("userId");
  }

  /// Validate identity data integrity
  Future<bool> validateStoredIdentity() async {
    final identity = await getStoredIdentity();
    if (identity == null) return false;

    // Validate hex formats
    if (!CryptoUtils.isValidHex(identity.publicKey)) return false;
    if (!CryptoUtils.isValidHex(identity.publicKeyHash)) return false;

    // Validate username format
    if (identity.username.isEmpty || identity.username.length > 50)
      return false;

    return true;
  }
}
