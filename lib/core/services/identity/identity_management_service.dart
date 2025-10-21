import 'package:flutter/foundation.dart';
// Identity management service for ADI operations
import '../storage/database_helper.dart';
import '../crypto/key_management_service.dart';
import '../../models/local_storage_models.dart';
import '../../models/accumulate_requests.dart';

class IdentityManagementService {
  final DatabaseHelper _dbHelper;
  final KeyManagementService _keyService;

  IdentityManagementService({
    DatabaseHelper? dbHelper,
    required KeyManagementService keyService,
  }) : _dbHelper = dbHelper ?? DatabaseHelper(),
       _keyService = keyService;

  /// Create and store a new identity locally
  Future<int> createIdentity({
    required String name,
    required String url,
    String? sponsorAddress,
    int keyBookCount = 1,
    int accountCount = 0,
  }) async {
    final identity = AccumulateIdentity(
      name: name,
      url: url,
      keyBookCount: keyBookCount,
      accountCount: accountCount,
      sponsorAddress: sponsorAddress,
    );

    final db = await _dbHelper.database;
    return await db.insert('identities', identity.toMap());
  }

  /// Get all identities
  Future<List<AccumulateIdentity>> getAllIdentities() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'identities',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'id DESC',
    );

    return maps.map((map) => AccumulateIdentity.fromMap(map)).toList();
  }

  /// Get identity by URL
  Future<AccumulateIdentity?> getIdentityByUrl(String url) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'identities',
      where: 'url = ? AND is_active = ?',
      whereArgs: [url, 1],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return AccumulateIdentity.fromMap(maps.first);
    }
    return null;
  }

  /// Get identity by name
  Future<AccumulateIdentity?> getIdentityByName(String name) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'identities',
      where: 'name = ? AND is_active = ?',
      whereArgs: [name, 1],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return AccumulateIdentity.fromMap(maps.first);
    }
    return null;
  }

  /// Create and store a key book
  Future<int> createKeyBook({
    required int identityId,
    required String name,
    required String url,
    String? publicKeyHash,
  }) async {
    final keyBook = AccumulateKeyBook(
      identityId: identityId,
      name: name,
      url: url,
      publicKeyHash: publicKeyHash,
    );

    final db = await _dbHelper.database;
    return await db.insert('key_books', keyBook.toMap());
  }

  /// Get key books for an identity
  Future<List<AccumulateKeyBook>> getKeyBooksForIdentity(int identityId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'key_books',
      where: 'identity_id = ? AND is_active = ?',
      whereArgs: [identityId, 1],
      orderBy: 'id ASC',
    );

    return maps.map((map) => AccumulateKeyBook.fromMap(map)).toList();
  }

  /// Get key book by URL
  Future<AccumulateKeyBook?> getKeyBookByUrl(String url) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'key_books',
      where: 'url = ? AND is_active = ?',
      whereArgs: [url, 1],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return AccumulateKeyBook.fromMap(maps.first);
    }
    return null;
  }

  /// Create and store a key page
  Future<int> createKeyPage({
    required int keyBookId,
    required String name,
    required String url,
    int keysRequired = 1,
    int keysRequiredOf = 1,
  }) async {
    final keyPage = AccumulateKeyPage(
      keyBookId: keyBookId,
      name: name,
      url: url,
      keysRequired: keysRequired,
      keysRequiredOf: keysRequiredOf,
    );

    final db = await _dbHelper.database;
    return await db.insert('key_pages', keyPage.toMap());
  }

  /// Get key pages for a key book
  Future<List<AccumulateKeyPage>> getKeyPagesForKeyBook(int keyBookId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'key_pages',
      where: 'key_book_id = ? AND is_active = ?',
      whereArgs: [keyBookId, 1],
      orderBy: 'id ASC',
    );

    return maps.map((map) => AccumulateKeyPage.fromMap(map)).toList();
  }

  /// Get key page by URL
  Future<AccumulateKeyPage?> getKeyPageByUrl(String url) async {
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

  /// Get all key pages for dropdown population
  Future<List<AccumulateKeyPage>> getAllKeyPages() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'key_pages',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'url ASC',
    );

    return maps.map((map) => AccumulateKeyPage.fromMap(map)).toList();
  }

  /// Create a complete identity with default key structure
  Future<Map<String, dynamic>> createCompleteIdentity({
    required String name,
    required String sponsorAddress,
    String keyBookName = 'book0',
    String keyPageName = '1',
    String keyName = 'default',
  }) async {
    final identityUrl = 'acc://$name.acme';
    final keyBookUrl = '$identityUrl/$keyBookName';
    final keyPageUrl = '$keyBookUrl/$keyPageName';

    // Generate key pair for the identity
    final keyPair = await _keyService.generateKeyPair();

    // Create identity
    final identityId = await createIdentity(
      name: name,
      url: identityUrl,
      sponsorAddress: sponsorAddress,
    );

    // Create default key book
    final keyBookId = await createKeyBook(
      identityId: identityId,
      name: keyBookName,
      url: keyBookUrl,
      publicKeyHash: keyPair.publicKeyHash,
    );

    // Create default key page
    final keyPageId = await createKeyPage(
      keyBookId: keyBookId,
      name: keyPageName,
      url: keyPageUrl,
    );

    // Store the key
    final keyId = await _keyService.storeADIKey(
      keyPageId: keyPageId,
      name: keyName,
      publicKey: keyPair.publicKey,
      privateKey: keyPair.privateKey,
      publicKeyHash: keyPair.publicKeyHash,
      isDefault: true,
    );

    return {
      'identityId': identityId,
      'identityUrl': identityUrl,
      'keyBookId': keyBookId,
      'keyBookUrl': keyBookUrl,
      'keyPageId': keyPageId,
      'keyPageUrl': keyPageUrl,
      'keyId': keyId,
      'publicKeyHash': keyPair.publicKeyHash,
    };
  }

  /// Update identity account count
  Future<void> updateIdentityAccountCount(int identityId, int newCount) async {
    final db = await _dbHelper.database;
    await db.update(
      'identities',
      {'account_count': newCount},
      where: 'id = ?',
      whereArgs: [identityId],
    );
  }

  /// Update identity key book count
  Future<void> updateIdentityKeyBookCount(int identityId, int newCount) async {
    final db = await _dbHelper.database;
    await db.update(
      'identities',
      {'key_book_count': newCount},
      where: 'id = ?',
      whereArgs: [identityId],
    );
  }

  /// Delete identity (soft delete)
  Future<void> deleteIdentity(int identityId) async {
    final db = await _dbHelper.database;
    await db.update(
      'identities',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [identityId],
    );
  }

  /// Delete key book (soft delete)
  Future<void> deleteKeyBook(int keyBookId) async {
    final db = await _dbHelper.database;
    await db.update(
      'key_books',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [keyBookId],
    );
  }

  /// Delete key page (soft delete)
  Future<void> deleteKeyPage(int keyPageId) async {
    final db = await _dbHelper.database;
    await db.update(
      'key_pages',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [keyPageId],
    );
  }

  /// Get identity hierarchy for dropdown population
  Future<List<Map<String, dynamic>>> getIdentityHierarchy() async {
    final identities = await getAllIdentities();
    final hierarchy = <Map<String, dynamic>>[];

    for (final identity in identities) {
      final keyBooks = await getKeyBooksForIdentity(identity.id!);
      final identityData = {
        'identity': identity,
        'keyBooks': <Map<String, dynamic>>[],
      };

      for (final keyBook in keyBooks) {
        final keyPages = await getKeyPagesForKeyBook(keyBook.id!);
        final keyBookData = {
          'keyBook': keyBook,
          'keyPages': keyPages,
        };
        (identityData['keyBooks'] as List<Map<String, dynamic>>).add(keyBookData);
      }

      hierarchy.add(identityData);
    }

    return hierarchy;
  }

  /// Validate identity name format
  bool isValidIdentityName(String name) {
    // Allow letters, numbers, and hyphens only
    final RegExp validName = RegExp(r'^[a-zA-Z0-9-]+$');
    return validName.hasMatch(name) &&
           name.isNotEmpty &&
           name.length <= 64 &&
           !name.startsWith('-') &&
           !name.endsWith('-');
  }

  /// Check if identity name is available locally
  Future<bool> isIdentityNameAvailable(String name) async {
    final existing = await getIdentityByName(name);
    return existing == null;
  }

  /// Get statistics about identities
  Future<Map<String, int>> getIdentityStats() async {
    final db = await _dbHelper.database;

    final identityCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM identities WHERE is_active = 1'
    );

    final keyBookCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM key_books WHERE is_active = 1'
    );

    final keyPageCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM key_pages WHERE is_active = 1'
    );

    final keyCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM keys WHERE is_active = 1'
    );

    return {
      'identities': identityCount.first['count'] as int,
      'keyBooks': keyBookCount.first['count'] as int,
      'keyPages': keyPageCount.first['count'] as int,
      'keys': keyCount.first['count'] as int,
    };
  }
}