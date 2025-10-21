import 'package:flutter/foundation.dart';
// Facade service that combines all Accumulate operations
import 'service_locator.dart';
import '../models/accumulate_requests.dart';
import '../models/local_storage_models.dart' show WalletAccount, AccumulateIdentity, AccumulateKeyPage;

class AccumulateServiceFacade {
  final ServiceLocator _serviceLocator = ServiceLocator();

  /// Initialize all services
  Future<void> initialize() async {
    await _serviceLocator.initialize();
  }

  // ===== IDENTITY OPERATIONS =====

  /// Create a complete identity (ADI) with default key structure
  Future<AccumulateResponse> createIdentity({
    required String name,
    required String sponsorAddress,
  }) async {
    try {
      // Validate name
      if (!_serviceLocator.identityManagementService.isValidIdentityName(name)) {
        return AccumulateResponse.failure('Invalid identity name format');
      }

      // Check if name is available locally
      final isAvailable = await _serviceLocator.identityManagementService.isIdentityNameAvailable(name);
      if (!isAvailable) {
        return AccumulateResponse.failure('Identity name already exists locally');
      }

      // Create identity structure locally
      final identityData = await _serviceLocator.identityManagementService.createCompleteIdentity(
        name: name,
        sponsorAddress: sponsorAddress,
      );

      // Create identity on network
      final request = CreateIdentityRequest(
        name: name,
        sponsorAddress: sponsorAddress,
        keyBookName: 'book0',
        publicKeyHash: identityData['publicKeyHash'],
      );

      final response = await _serviceLocator.enhancedAccumulateService.createIdentity(request);

      if (response.success) {
        // Identity created successfully - data is already stored locally
        return AccumulateResponse.success(
          transactionId: response.transactionId,
          hash: response.hash,
          data: identityData,
        );
      } else {
        // Remove local data if network creation failed
        await _serviceLocator.identityManagementService.deleteIdentity(identityData['identityId']);
        return response;
      }
    } catch (e) {
      return AccumulateResponse.failure('Error creating identity: ${e.toString()}');
    }
  }

  /// Create a lite token account
  Future<AccumulateResponse> createLiteTokenAccount({
    required String name,
    required String sponsorAddress,
    String? tokenUrl,
  }) async {
    try {
      final request = CreateLiteTokenAccountRequest(
        sponsorAddress: sponsorAddress,
        tokenUrl: tokenUrl,
      );

      final response = await _serviceLocator.enhancedAccumulateService.createLiteTokenAccount(request);

      if (response.success && response.data != null) {
        // Store account locally
        await _serviceLocator.tokenManagementService.createTokenAccount(
          address: response.data!['address'],
          accountType: 'lite_account',
          tokenUrl: tokenUrl,
        );

        // Store private key securely
        await _serviceLocator.keyManagementService.storeLiteAccountKey(
          response.data!['address'],
          response.data!['privateKey'],
        );

        return response;
      }

      return response;
    } catch (e) {
      return AccumulateResponse.failure('Error creating lite token account: ${e.toString()}');
    }
  }

  /// Create an ADI token account
  Future<AccumulateResponse> createADITokenAccount({
    required String accountName,
    required String identityUrl,
    required String keyPageUrl,
  }) async {
    try {
      // Token URL is always hardcoded to ACME
      const String tokenUrl = "acc://ACME";

      final request = CreateADITokenAccountRequest(
        name: accountName,
        identityUrl: identityUrl,
        tokenUrl: tokenUrl,
        keyPageUrl: keyPageUrl,
      );

      final response = await _serviceLocator.enhancedAccumulateService.createADITokenAccount(request);

      if (response.success) {
        // Get identity info
        final identity = await _serviceLocator.identityManagementService.getIdentityByUrl(identityUrl);
        final keyPage = await _serviceLocator.identityManagementService.getKeyPageByUrl(keyPageUrl);

        // Store account locally
        await _serviceLocator.tokenManagementService.createTokenAccount(
          address: request.accountUrl,
          accountType: 'token_account',
          parentIdentityId: identity?.id,
          tokenUrl: tokenUrl,
          keyPageId: keyPage?.id,
        );

        return response;
      }

      return response;
    } catch (e) {
      return AccumulateResponse.failure('Error creating ADI token account: ${e.toString()}');
    }
  }

  /// Create a data account
  Future<AccumulateResponse> createDataAccount({
    required String accountName,
    required String identityUrl,
    required String keyPageUrl,
  }) async {
    try {
      final request = CreateDataAccountRequest(
        name: accountName,
        identityUrl: identityUrl,
        keyPageUrl: keyPageUrl,
      );

      final response = await _serviceLocator.enhancedAccumulateService.createDataAccount(request);

      if (response.success) {
        // Get identity info
        final identity = await _serviceLocator.identityManagementService.getIdentityByUrl(identityUrl);

        // Store data account locally
        await _serviceLocator.tokenManagementService.createDataAccount(
          name: accountName,
          url: request.accountUrl,
          parentIdentityId: identity!.id!,
        );

        return response;
      }

      return response;
    } catch (e) {
      return AccumulateResponse.failure('Error creating data account: ${e.toString()}');
    }
  }

  /// Create a key book
  Future<AccumulateResponse> createKeyBook({
    required String keyBookName,
    required String identityUrl,
    required String keyPageUrl,
  }) async {
    try {
      // Generate key pair for the key book
      final keyPair = await _serviceLocator.keyManagementService.generateKeyPair();

      final request = CreateKeyBookRequest(
        name: keyBookName,
        identityUrl: identityUrl,
        publicKeyHash: keyPair.publicKeyHash,
        keyPageUrl: keyPageUrl,
      );

      final response = await _serviceLocator.enhancedAccumulateService.createKeyBook(request);

      if (response.success) {
        // Get or create identity info
        var identity = await _serviceLocator.identityManagementService.getIdentityByUrl(identityUrl);

        if (identity == null) {
          // Identity doesn't exist in local database, create it
          debugPrint('Creating identity record for: $identityUrl');
          final identityId = await _serviceLocator.identityManagementService.createIdentity(
            name: identityUrl.split('//')[1].split('.')[0], // Extract name from URL
            url: identityUrl,
          );
          identity = await _serviceLocator.identityManagementService.getIdentityByUrl(identityUrl);
        }

        if (identity?.id != null) {
          // Store key book locally
          debugPrint('Storing key book locally: ${request.keyBookUrl}');
          await _serviceLocator.identityManagementService.createKeyBook(
            identityId: identity!.id!,
            name: keyBookName,
            url: request.keyBookUrl,
            publicKeyHash: keyPair.publicKeyHash,
          );
          debugPrint(' Key book stored in SQLite database');
        } else {
          debugPrint(' Failed to create or find identity for key book storage');
        }

        return response;
      }

      return response;
    } catch (e) {
      return AccumulateResponse.failure('Error creating key book: ${e.toString()}');
    }
  }

  /// Create a key page
  Future<AccumulateResponse> createKeyPage({
    required String keyPageName,
    required String keyBookUrl,
    required String signerKeyPageUrl,
    List<String>? additionalKeys,
  }) async {
    try {
      // Generate key pair for the key page
      final keyPair = await _serviceLocator.keyManagementService.generateKeyPair();
      final keyHashes = [keyPair.publicKeyHash];

      // Add any additional keys
      if (additionalKeys != null) {
        keyHashes.addAll(additionalKeys);
      }

      final request = CreateKeyPageRequest(
        name: keyPageName,
        keyBookUrl: keyBookUrl,
        publicKeyHashes: keyHashes,
        signerKeyPageUrl: signerKeyPageUrl,
      );

      final response = await _serviceLocator.enhancedAccumulateService.createKeyPage(request);

      if (response.success) {
        // Get or create key book info
        var keyBook = await _serviceLocator.identityManagementService.getKeyBookByUrl(keyBookUrl);

        if (keyBook == null) {
          // Key book doesn't exist in local database, need to create it
          debugPrint('Key book not found, need to create it first: $keyBookUrl');

          // Extract identity URL from key book URL (e.g., acc://testtesttest1.acme/book -> acc://testtesttest1.acme)
          final identityUrl = keyBookUrl.substring(0, keyBookUrl.lastIndexOf('/'));

          // Get or create identity
          var identity = await _serviceLocator.identityManagementService.getIdentityByUrl(identityUrl);
          if (identity == null) {
            debugPrint('Creating identity record for: $identityUrl');
            final identityId = await _serviceLocator.identityManagementService.createIdentity(
              name: identityUrl.split('//')[1].split('.')[0], // Extract name from URL
              url: identityUrl,
            );
            identity = await _serviceLocator.identityManagementService.getIdentityByUrl(identityUrl);
          }

          if (identity?.id != null) {
            // Create the key book record
            debugPrint('Creating key book record: $keyBookUrl');
            await _serviceLocator.identityManagementService.createKeyBook(
              identityId: identity!.id!,
              name: keyBookUrl.split('/').last, // Extract key book name from URL
              url: keyBookUrl,
              publicKeyHash: 'placeholder', // We don't have the original key book's hash
            );
            keyBook = await _serviceLocator.identityManagementService.getKeyBookByUrl(keyBookUrl);
          }
        }

        if (keyBook?.id != null) {
          // Store key page locally
          debugPrint('Storing key page locally: ${request.keyPageUrl}');
          final keyPageId = await _serviceLocator.identityManagementService.createKeyPage(
            keyBookId: keyBook!.id!,
            name: keyPageName,
            url: request.keyPageUrl,
          );

          // Store the key
          debugPrint('Storing key for key page');
          await _serviceLocator.keyManagementService.storeADIKey(
            keyPageId: keyPageId,
            name: 'default',
            publicKey: keyPair.publicKey,
            privateKey: keyPair.privateKey,
            publicKeyHash: keyPair.publicKeyHash,
            isDefault: true,
          );
          debugPrint(' Key page and key stored in SQLite database');
        } else {
          debugPrint(' Failed to create or find key book for key page storage');
        }

        return response;
      }

      return response;
    } catch (e) {
      return AccumulateResponse.failure('Error creating key page: ${e.toString()}');
    }
  }

  /// Create a custom token
  Future<AccumulateResponse> createCustomToken({
    required String tokenName,
    required String tokenSymbol,
    required String identityUrl,
    required String keyPageUrl,
    int precision = 8,
  }) async {
    try {
      // Validate token data
      if (!_serviceLocator.tokenManagementService.isValidTokenName(tokenName)) {
        return AccumulateResponse.failure('Invalid token name format');
      }

      if (!_serviceLocator.tokenManagementService.isValidTokenSymbol(tokenSymbol)) {
        return AccumulateResponse.failure('Invalid token symbol format');
      }

      // Check symbol availability
      final isSymbolAvailable = await _serviceLocator.tokenManagementService.isTokenSymbolAvailable(tokenSymbol);
      if (!isSymbolAvailable) {
        return AccumulateResponse.failure('Token symbol already exists');
      }

      final request = CreateCustomTokenRequest(
        name: tokenName,
        symbol: tokenSymbol,
        identityUrl: identityUrl,
        keyPageUrl: keyPageUrl,
        precision: precision,
      );

      final response = await _serviceLocator.enhancedAccumulateService.createCustomToken(request);

      if (response.success) {
        // Get identity info
        final identity = await _serviceLocator.identityManagementService.getIdentityByUrl(identityUrl);

        // Store custom token locally
        await _serviceLocator.tokenManagementService.createCustomToken(
          name: tokenName,
          symbol: tokenSymbol,
          url: request.tokenUrl,
          precision: precision,
          creatorIdentityId: identity?.id,
        );

        return response;
      }

      return response;
    } catch (e) {
      return AccumulateResponse.failure('Error creating custom token: ${e.toString()}');
    }
  }

  /// Mint tokens
  Future<AccumulateResponse> mintTokens({
    required String tokenUrl,
    required String recipientUrl,
    required double amount,
    required String keyPageUrl,
    int precision = 8,
  }) async {
    try {
      // Convert amount to base units
      final baseAmount = _serviceLocator.tokenManagementService.parseTokenAmount(
        amount.toString(),
        precision,
      );

      final request = MintTokensRequest(
        tokenUrl: tokenUrl,
        recipientUrl: recipientUrl,
        amount: baseAmount,
        keyPageUrl: keyPageUrl,
      );

      return await _serviceLocator.enhancedAccumulateService.mintTokens(request);
    } catch (e) {
      return AccumulateResponse.failure('Error minting tokens: ${e.toString()}');
    }
  }

  // ===== DATA RETRIEVAL FOR DROPDOWNS =====

  /// Get identities for dropdown
  Future<List<AccumulateIdentity>> getIdentitiesForDropdown() async {
    return await _serviceLocator.identityManagementService.getAllIdentities();
  }

  /// Get key pages for dropdown
  Future<List<AccumulateKeyPage>> getKeyPagesForDropdown() async {
    return await _serviceLocator.identityManagementService.getAllKeyPages();
  }

  /// Get accounts for dropdown
  Future<List<Map<String, dynamic>>> getAccountsForDropdown() async {
    return await _serviceLocator.tokenManagementService.getAccountsForDropdown();
  }

  /// Get tokens for dropdown
  Future<List<Map<String, dynamic>>> getTokensForDropdown() async {
    return await _serviceLocator.tokenManagementService.getTokensForDropdown();
  }

  /// Get identity hierarchy (for advanced UI)
  Future<List<Map<String, dynamic>>> getIdentityHierarchy() async {
    return await _serviceLocator.identityManagementService.getIdentityHierarchy();
  }

  // ===== UTILITY METHODS =====

  /// Get network fees
  Future<Map<String, int>> getNetworkFees() async {
    return await _serviceLocator.enhancedAccumulateService.getNetworkFees();
  }

  /// Get identity creation cost
  Future<int> getIdentityCreationCost(String name) async {
    return await _serviceLocator.enhancedAccumulateService.getIdentityCreationCost(name);
  }

  /// Format token amount
  String formatTokenAmount(int amount, int precision) {
    return _serviceLocator.tokenManagementService.formatTokenAmount(amount, precision);
  }

  /// Parse token amount
  int parseTokenAmount(String amount, int precision) {
    return _serviceLocator.tokenManagementService.parseTokenAmount(amount, precision);
  }

  /// Get statistics
  Future<Map<String, dynamic>> getAllStats() async {
    final identityStats = await _serviceLocator.identityManagementService.getIdentityStats();
    final tokenStats = await _serviceLocator.tokenManagementService.getTokenStats();
    final dbStats = await _serviceLocator.databaseHelper.getDatabaseStats();

    return {
      'identity': identityStats,
      'token': tokenStats,
      'database': dbStats,
    };
  }

  // ===== SEND/RECEIVE OPERATIONS =====

  /// Send tokens from one account to another
  Future<AccumulateResponse> sendTokens({
    required String fromAccountUrl,
    required List<TokenRecipient> recipients,
    required String signerUrl,
    String? memo,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final request = SendTokensRequest(
        fromAccountUrl: fromAccountUrl,
        recipients: recipients,
        signerUrl: signerUrl,
        memo: memo,
        metadata: metadata,
      );

      return await _serviceLocator.transactionService.sendTokens(request);
    } catch (e) {
      return AccumulateResponse.failure('Error sending tokens: ${e.toString()}');
    }
  }

  /// Query account balance
  Future<BalanceResponse> queryBalance({
    required String accountUrl,
    String? tokenUrl,
  }) async {
    try {
      final request = QueryBalanceRequest(
        accountUrl: accountUrl,
        tokenUrl: tokenUrl,
      );

      return await _serviceLocator.transactionService.queryBalance(request);
    } catch (e) {
      return BalanceResponse.failure('Error querying balance: ${e.toString()}');
    }
  }

  /// Get transaction history for an account
  Future<TransactionHistoryResponse> getTransactionHistory({
    required String accountUrl,
    int start = 0,
    int count = 50,
    bool? scratch,
  }) async {
    try {
      final request = QueryTransactionHistoryRequest(
        accountUrl: accountUrl,
        start: start,
        count: count,
        scratch: scratch,
      );

      return await _serviceLocator.transactionService.queryTransactionHistory(request);
    } catch (e) {
      return TransactionHistoryResponse.failure('Error getting transaction history: ${e.toString()}');
    }
  }

  /// Validate an account address
  Future<ValidateAddressResponse> validateAddress(String address) async {
    try {
      final request = ValidateAddressRequest(address: address);
      return await _serviceLocator.transactionService.validateAddress(request);
    } catch (e) {
      return ValidateAddressResponse.failure('Error validating address: ${e.toString()}');
    }
  }


  // ===== UTILITY METHODS FOR UI =====

  /// Get account balances for all user accounts
  Future<Map<String, BalanceResponse>> getAllAccountBalances() async {
    final accounts = await _serviceLocator.tokenManagementService.getAccountsForDropdown();
    final balances = <String, BalanceResponse>{};

    for (final account in accounts) {
      final accountData = account['data'] as WalletAccount?;
      if (accountData != null) {
        final balance = await queryBalance(accountUrl: accountData.address);
        balances[accountData.address] = balance;
      }
    }

    return balances;
  }

  // ===== DATA OPERATIONS =====

  /// Write data to a data account
  Future<DataResponse> writeData({
    required String dataAccountUrl,
    required List<String> dataEntries,
    required String signerUrl,
    bool scratch = false,
    bool writeToState = false,
    String? memo,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final request = WriteDataRequest(
        dataAccountUrl: dataAccountUrl,
        dataEntries: dataEntries,
        signerUrl: signerUrl,
        scratch: scratch,
        writeToState: writeToState,
        memo: memo,
        metadata: metadata,
      );

      return await _serviceLocator.dataService.writeData(request);
    } catch (e) {
      return DataResponse.failure('Error writing data: ${e.toString()}');
    }
  }

  /// Query data entries from a data account
  Future<DataHistoryResponse> queryDataEntries({
    required String dataAccountUrl,
    int start = 0,
    int count = 50,
    bool? scratch,
    bool? expand,
  }) async {
    try {
      final request = QueryDataHistoryRequest(
        dataAccountUrl: dataAccountUrl,
        start: start,
        count: count,
        scratch: scratch,
        expand: expand,
      );

      return await _serviceLocator.dataService.queryDataEntries(request);
    } catch (e) {
      return DataHistoryResponse.failure('Error querying data entries: ${e.toString()}');
    }
  }

  /// Query specific data entry by hash
  Future<DataResponse> queryDataEntry({
    required String dataAccountUrl,
    String? entryHash,
  }) async {
    try {
      final request = QueryDataRequest(
        dataAccountUrl: dataAccountUrl,
        entryHash: entryHash,
      );

      return await _serviceLocator.dataService.queryDataEntry(request);
    } catch (e) {
      return DataResponse.failure('Error querying data entry: ${e.toString()}');
    }
  }

  /// Query data account information
  Future<DataAccountResponse> queryDataAccount({
    required String dataAccountUrl,
    bool? expand,
  }) async {
    try {
      final request = QueryDataAccountRequest(
        dataAccountUrl: dataAccountUrl,
        expand: expand,
      );

      return await _serviceLocator.dataService.queryDataAccount(request);
    } catch (e) {
      return DataAccountResponse.failure('Error querying data account: ${e.toString()}');
    }
  }

  /// Get recent data entries across all accounts
  Future<List<DataEntry>> getRecentDataEntries({int limit = 20}) async {
    return await _serviceLocator.dataService.getRecentDataEntries(limit: limit);
  }

  /// Search data entries by content
  Future<List<DataEntry>> searchDataEntries({
    String? query,
    String? dataAccountUrl,
    int limit = 50,
  }) async {
    return await _serviceLocator.dataService.searchDataEntries(
      query: query,
      dataAccountUrl: dataAccountUrl,
      limit: limit,
    );
  }

  /// Get data entry count for an account
  Future<int> getDataEntryCount(String dataAccountUrl) async {
    return await _serviceLocator.dataService.getDataEntryCount(dataAccountUrl);
  }

  /// Validate data account URL
  bool isValidDataAccountUrl(String url) {
    return _serviceLocator.dataService.isValidDataAccountUrl(url);
  }

  /// Get available data accounts for dropdown
  Future<List<Map<String, dynamic>>> getDataAccountsForDropdown() async {
    return await _serviceLocator.dataService.getDataAccountsForDropdown();
  }

  /// Export data entries for backup
  Future<List<Map<String, dynamic>>> exportDataEntries({
    String? dataAccountUrl,
  }) async {
    return await _serviceLocator.dataService.exportDataEntries(
      dataAccountUrl: dataAccountUrl,
    );
  }

  /// Clear data entries for an account
  Future<AccumulateResponse> clearDataEntriesForAccount(String dataAccountUrl) async {
    try {
      await _serviceLocator.dataService.clearDataEntriesForAccount(dataAccountUrl);
      return AccumulateResponse.success();
    } catch (e) {
      return AccumulateResponse.failure('Error clearing data entries: ${e.toString()}');
    }
  }

  // ===== PURCHASE CREDITS OPERATIONS =====

  /// Purchase credits for a lite account or key page
  Future<PurchaseCreditsResponse> purchaseCredits({
    required String recipientUrl,
    required int creditAmount,
    required String payerUrl,
    required int oracleValue,
    String? memo,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final request = PurchaseCreditsRequest(
        recipientUrl: recipientUrl,
        creditAmount: creditAmount,
        payerUrl: payerUrl,
        oracleValue: oracleValue,
        memo: memo,
        metadata: metadata,
      );

      return await _serviceLocator.purchaseCreditsService.purchaseCredits(request);
    } catch (e) {
      return PurchaseCreditsResponse.failure('Error purchasing credits: ${e.toString()}');
    }
  }

  /// Query current oracle value
  Future<OracleResponse> queryOracleValue() async {
    return await _serviceLocator.purchaseCreditsService.queryOracleValue();
  }

  /// Get available credit accounts for dropdown (lite accounts + key pages)
  Future<List<CreditAccount>> getCreditAccountsForDropdown() async {
    return await _serviceLocator.purchaseCreditsService.getCreditAccountsForDropdown();
  }

  /// Get available ACME payer accounts for dropdown (lite accounts only)
  Future<List<CreditAccount>> getACMEPayerAccountsForDropdown() async {
    return await _serviceLocator.purchaseCreditsService.getACMEPayerAccountsForDropdown();
  }

  /// Calculate cost preview for credit purchase
  Future<Map<String, dynamic>> calculateCreditCost({
    required int creditAmount,
    int? oracleValue,
  }) async {
    return await _serviceLocator.purchaseCreditsService.calculateCreditCost(
      creditAmount: creditAmount,
      oracleValue: oracleValue,
    );
  }

  /// Check if an account can receive credits
  Future<bool> canReceiveCredits(String accountUrl) async {
    return await _serviceLocator.purchaseCreditsService.canReceiveCredits(accountUrl);
  }

  /// Get credit balance for an account
  Future<int?> getCreditBalance(String accountUrl) async {
    return await _serviceLocator.purchaseCreditsService.getCreditBalance(accountUrl);
  }

  /// Get recent credit transactions
  Future<List<TransactionRecord>> getRecentCreditTransactions({int limit = 20}) async {
    return await _serviceLocator.purchaseCreditsService.getRecentCreditTransactions(limit: limit);
  }

  /// Get all statistics including address book, data, and credits
  Future<Map<String, dynamic>> getAllStatsWithTransactions() async {
    final identityStats = await _serviceLocator.identityManagementService.getIdentityStats();
    final tokenStats = await _serviceLocator.tokenManagementService.getTokenStats();
    final dbStats = await _serviceLocator.databaseHelper.getDatabaseStats();
    final dataStats = await _serviceLocator.dataService.getDataStats();

    return {
      'identity': identityStats,
      'token': tokenStats,
      'database': dbStats,
      'data': dataStats,
    };
  }

  // ===== FAUCET OPERATIONS =====

  /// Request test tokens from faucet (devnet/testnet only)
  Future<FaucetResponse> requestFaucetTokens({
    required String accountUrl,
    String? tokenUrl,
    int? amount,
    String? memo,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final request = FaucetRequest(
        accountUrl: accountUrl,
        tokenUrl: tokenUrl ?? 'ACME',
        amount: amount ?? 100000000, // Default 1 ACME (100M units)
        memo: memo,
        metadata: metadata,
      );

      return await _serviceLocator.faucetService.requestTokens(request);
    } catch (e) {
      return FaucetResponse.failure('Error requesting faucet tokens: ${e.toString()}');
    }
  }

  /// Get available lite accounts for faucet
  Future<List<WalletAccount>> getLiteAccountsForFaucet() async {
    return await _serviceLocator.faucetService.getLiteAccountsForFaucet();
  }

  /// Check if account can receive faucet tokens
  Future<bool> canReceiveFaucetTokens(String accountUrl) async {
    return await _serviceLocator.faucetService.canReceiveFaucetTokens(accountUrl);
  }

  /// Get recent faucet transactions
  Future<List<TransactionRecord>> getRecentFaucetTransactions({int limit = 20}) async {
    return await _serviceLocator.faucetService.getRecentFaucetTransactions(limit: limit);
  }

  /// Reset all data (for logout)
  Future<void> reset() async {
    await _serviceLocator.reset();
  }
}