import 'package:flutter/foundation.dart';
// Token management service for custom tokens and accounts
import '../storage/database_helper.dart';
import '../../models/local_storage_models.dart';
import '../../models/accumulate_requests.dart';

class TokenManagementService {
  final DatabaseHelper _dbHelper;

  TokenManagementService({
    DatabaseHelper? dbHelper,
  }) : _dbHelper = dbHelper ?? DatabaseHelper();

  /// Create and store a custom token
  Future<int> createCustomToken({
    required String name,
    required String symbol,
    required String url,
    int precision = 8,
    int? creatorIdentityId,
  }) async {
    final token = AccumulateCustomToken(
      name: name,
      symbol: symbol,
      url: url,
      precision: precision,
      creatorIdentityId: creatorIdentityId,
    );

    final db = await _dbHelper.database;
    return await db.insert('custom_tokens', token.toMap());
  }

  /// Get all custom tokens
  Future<List<AccumulateCustomToken>> getAllCustomTokens() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'custom_tokens',
      orderBy: 'id DESC',
    );

    return maps.map((map) => AccumulateCustomToken.fromMap(map)).toList();
  }

  /// Get custom token by URL
  Future<AccumulateCustomToken?> getCustomTokenByUrl(String url) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'custom_tokens',
      where: 'url = ?',
      whereArgs: [url],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return AccumulateCustomToken.fromMap(maps.first);
    }
    return null;
  }

  /// Get custom token by symbol
  Future<AccumulateCustomToken?> getCustomTokenBySymbol(String symbol) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'custom_tokens',
      where: 'symbol = ?',
      whereArgs: [symbol],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return AccumulateCustomToken.fromMap(maps.first);
    }
    return null;
  }

  /// Get custom tokens created by an identity
  Future<List<AccumulateCustomToken>> getCustomTokensByCreator(int creatorIdentityId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'custom_tokens',
      where: 'creator_identity_id = ?',
      whereArgs: [creatorIdentityId],
      orderBy: 'id DESC',
    );

    return maps.map((map) => AccumulateCustomToken.fromMap(map)).toList();
  }

  /// Create and store a data account
  Future<int> createDataAccount({
    required String name,
    required String url,
    required int parentIdentityId,
  }) async {
    final dataAccount = AccumulateDataAccount(
      name: name,
      url: url,
      parentIdentityId: parentIdentityId,
    );

    final db = await _dbHelper.database;
    return await db.insert('data_accounts', dataAccount.toMap());
  }

  /// Get all data accounts
  Future<List<AccumulateDataAccount>> getAllDataAccounts() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'data_accounts',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'id DESC',
    );

    return maps.map((map) => AccumulateDataAccount.fromMap(map)).toList();
  }

  /// Get data accounts by parent identity
  Future<List<AccumulateDataAccount>> getDataAccountsByIdentity(int parentIdentityId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'data_accounts',
      where: 'parent_identity_id = ? AND is_active = ?',
      whereArgs: [parentIdentityId, 1],
      orderBy: 'id DESC',
    );

    return maps.map((map) => AccumulateDataAccount.fromMap(map)).toList();
  }

  /// Get data account by URL
  Future<AccumulateDataAccount?> getDataAccountByUrl(String url) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'data_accounts',
      where: 'url = ? AND is_active = ?',
      whereArgs: [url, 1],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return AccumulateDataAccount.fromMap(maps.first);
    }
    return null;
  }

  /// Create and store a token account (ADI or Lite)
  Future<int> createTokenAccount({
    required String address,
    required String accountType,
    int? parentIdentityId,
    String? tokenUrl,
    int? keyBookId,
    int? keyPageId,
    Map<String, dynamic>? metadata,
  }) async {
    final account = WalletAccount(
      address: address,
      accountType: accountType,
      parentIdentityId: parentIdentityId,
      tokenUrl: tokenUrl,
      keyBookId: keyBookId,
      keyPageId: keyPageId,
      metadata: metadata,
    );

    return await _dbHelper.insertAccount(account);
  }

  /// Get token accounts by type
  Future<List<WalletAccount>> getTokenAccountsByType(String accountType) async {
    return await _dbHelper.getAccountsByType(accountType);
  }

  /// Get token accounts by parent identity
  Future<List<WalletAccount>> getTokenAccountsByIdentity(int parentIdentityId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'wallet_accounts',
      where: 'parent_identity_id = ? AND is_active = ?',
      whereArgs: [parentIdentityId, 1],
      orderBy: 'id DESC',
    );

    return maps.map((map) => WalletAccount.fromMap(map)).toList();
  }

  /// Get token accounts by token URL
  Future<List<WalletAccount>> getTokenAccountsByTokenUrl(String tokenUrl) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'wallet_accounts',
      where: 'token_url = ? AND is_active = ?',
      whereArgs: [tokenUrl, 1],
      orderBy: 'id DESC',
    );

    return maps.map((map) => WalletAccount.fromMap(map)).toList();
  }

  /// Get all lite accounts
  Future<List<WalletAccount>> getAllLiteAccounts() async {
    return await getTokenAccountsByType('lite_account');
  }

  /// Get all ADI token accounts
  Future<List<WalletAccount>> getAllADITokenAccounts() async {
    return await getTokenAccountsByType('token_account');
  }

  /// Get available token types for dropdown
  Future<List<Map<String, String>>> getAvailableTokenTypes() async {
    final tokens = <Map<String, String>>[];

    // Add ACME as default token
    tokens.add({
      'name': 'ACME',
      'symbol': 'ACME',
      'url': 'acc://ACME',
    });

    // Add custom tokens
    final customTokens = await getAllCustomTokens();
    for (final token in customTokens) {
      tokens.add({
        'name': token.name,
        'symbol': token.symbol,
        'url': token.url,
      });
    }

    return tokens;
  }

  /// Validate token symbol format
  bool isValidTokenSymbol(String symbol) {
    // Allow uppercase letters and numbers, 2-8 characters
    final RegExp validSymbol = RegExp(r'^[A-Z0-9]{2,8}$');
    return validSymbol.hasMatch(symbol);
  }

  /// Validate token name format
  bool isValidTokenName(String name) {
    // Allow letters, numbers, spaces, and common punctuation
    final RegExp validName = RegExp(r'^[a-zA-Z0-9\s\-_\.]+$');
    return validName.hasMatch(name) && name.trim().isNotEmpty && name.length <= 64;
  }

  /// Check if token symbol is available
  Future<bool> isTokenSymbolAvailable(String symbol) async {
    final existing = await getCustomTokenBySymbol(symbol);
    return existing == null;
  }

  /// Check if token URL is available
  Future<bool> isTokenUrlAvailable(String url) async {
    final existing = await getCustomTokenByUrl(url);
    return existing == null;
  }

  /// Delete custom token (hard delete since it's user's own token)
  Future<void> deleteCustomToken(int tokenId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'custom_tokens',
      where: 'id = ?',
      whereArgs: [tokenId],
    );
  }

  /// Delete data account (soft delete)
  Future<void> deleteDataAccount(int dataAccountId) async {
    final db = await _dbHelper.database;
    await db.update(
      'data_accounts',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [dataAccountId],
    );
  }

  /// Get token statistics
  Future<Map<String, int>> getTokenStats() async {
    final db = await _dbHelper.database;

    final customTokenCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM custom_tokens'
    );

    final dataAccountCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM data_accounts WHERE is_active = 1'
    );

    final liteAccountCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM wallet_accounts WHERE account_type = "lite_account" AND is_active = 1'
    );

    final adiTokenAccountCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM wallet_accounts WHERE account_type = "token_account" AND is_active = 1'
    );

    return {
      'customTokens': customTokenCount.first['count'] as int,
      'dataAccounts': dataAccountCount.first['count'] as int,
      'liteAccounts': liteAccountCount.first['count'] as int,
      'adiTokenAccounts': adiTokenAccountCount.first['count'] as int,
    };
  }

  /// Format token amount with proper precision
  String formatTokenAmount(int amount, int precision) {
    final divisor = BigInt.from(10).pow(precision);
    final major = amount ~/ divisor.toInt();
    final minor = amount % divisor.toInt();

    if (minor == 0) {
      return major.toString();
    }

    final minorStr = minor.toString().padLeft(precision, '0');
    final trimmedMinor = minorStr.replaceAll(RegExp(r'0+$'), '');

    if (trimmedMinor.isEmpty) {
      return major.toString();
    }

    return '$major.$trimmedMinor';
  }

  /// Parse token amount to base units
  int parseTokenAmount(String amount, int precision) {
    final parts = amount.split('.');
    final major = int.parse(parts[0]);

    if (parts.length == 1) {
      return major * BigInt.from(10).pow(precision).toInt();
    }

    final minorStr = parts[1].padRight(precision, '0').substring(0, precision);
    final minor = int.parse(minorStr);

    return major * BigInt.from(10).pow(precision).toInt() + minor;
  }

  /// Get accounts for dropdown selection
  Future<List<Map<String, dynamic>>> getAccountsForDropdown() async {
    final accounts = <Map<String, dynamic>>[];

    // Get all wallet accounts
    final walletAccounts = await _dbHelper.getAllAccounts();
    for (final account in walletAccounts) {
      accounts.add({
        'type': 'account',
        'data': account,
        'displayName': '${account.name} (${account.accountType})',
        'address': account.address,
      });
    }

    return accounts;
  }

  /// Get tokens for dropdown selection
  Future<List<Map<String, dynamic>>> getTokensForDropdown() async {
    final tokens = <Map<String, dynamic>>[];

    // Add ACME
    tokens.add({
      'type': 'token',
      'name': 'ACME',
      'symbol': 'ACME',
      'url': 'acc://ACME',
      'precision': 8,
      'isCustom': false,
    });

    // Add custom tokens
    final customTokens = await getAllCustomTokens();
    for (final token in customTokens) {
      tokens.add({
        'type': 'token',
        'name': token.name,
        'symbol': token.symbol,
        'url': token.url,
        'precision': token.precision,
        'isCustom': true,
      });
    }

    return tokens;
  }
}