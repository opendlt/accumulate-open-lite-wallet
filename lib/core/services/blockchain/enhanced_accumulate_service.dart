import 'package:flutter/foundation.dart';
// Enhanced Accumulate API service with create operations
import 'dart:convert';
import 'dart:typed_data';
import 'package:accumulate_api/accumulate_api.dart';
import 'package:convert/convert.dart';
import '../../models/accumulate_requests.dart';
import '../../models/local_storage_models.dart';
import '../../constants/app_constants.dart';
import '../networking/network_service.dart';
import '../crypto/key_management_service.dart';

class EnhancedAccumulateService {
  final ACMEClient _acmeClient;
  final NetworkService _networkService;
  final KeyManagementService _keyService;
  final String _baseUrl;

  EnhancedAccumulateService({
    String? baseUrl,  // Make optional
    required KeyManagementService keyService,
  }) : _acmeClient = ACMEClient(AppConstants.defaultAccumulateDevnetUrl),  // Always use devnet
       _networkService = NetworkService(),
       _keyService = keyService,
       _baseUrl = AppConstants.defaultAccumulateDevnetUrl {  // Always use devnet
    debugPrint('Enhanced Accumulate Service initialized with endpoint: ${AppConstants.defaultAccumulateDevnetUrl}');
  }

  /// Get the base URL for this service
  String get baseUrl => _baseUrl;

  /// Create an Accumulate Digital Identity (ADI)
  Future<AccumulateResponse> createIdentity(CreateIdentityRequest request) async {
    try {
      // Validate identity name
      if (!_isValidIdentityName(request.name)) {
        return AccumulateResponse.failure('Invalid identity name. Use only letters, numbers, and hyphens.');
      }

      // Check if identity already exists
      final existsCheck = await _checkIdentityExists(request.identityUrl);
      if (existsCheck) {
        return AccumulateResponse.failure('Identity with name "${request.name}" already exists.');
      }

      // Extract base lite identity from sponsor address (remove /ACME if present)
      String sponsorLiteIdentity = request.sponsorAddress;
      if (request.sponsorAddress.endsWith('/ACME')) {
        sponsorLiteIdentity = request.sponsorAddress.substring(0, request.sponsorAddress.length - 5);
      }

      // Get sponsor account for signing (using base lite identity)
      final sponsorSigner = await _keyService.createLiteIdentitySigner(sponsorLiteIdentity);
      if (sponsorSigner == null) {
        return AccumulateResponse.failure('Could not create signer for sponsor lite identity: $sponsorLiteIdentity');
      }

      // Create identity parameters
      final createIdentityParam = CreateIdentityParam();
      createIdentityParam.url = request.identityUrl;
      createIdentityParam.keyHash = Uint8List.fromList(hex.decode(request.publicKeyHash));
      createIdentityParam.keyBookUrl = request.keyBookUrl;

      // Execute transaction
      debugPrint('Creating Identity: ${request.identityUrl}');
      debugPrint('Sponsor token account: ${request.sponsorAddress}');
      debugPrint('Sponsor lite identity: $sponsorLiteIdentity');

      final response = await _acmeClient.createIdentity(
        sponsorLiteIdentity,  // Use lite identity for createIdentity call
        createIdentityParam,
        sponsorSigner,
      );

      debugPrint('Identity Creation Response: $response');
      return _parseResponse(response);
    } catch (e) {
      return AccumulateResponse.failure('Error creating identity: ${e.toString()}');
    }
  }

  /// Create a lite token account
  Future<AccumulateResponse> createLiteTokenAccount(CreateLiteTokenAccountRequest request) async {
    try {
      // Generate new key pair for the lite account
      final keyPair = await _keyService.generateKeyPair();

      // Get sponsor signer
      final sponsorSigner = await _keyService.createLiteIdentitySigner(request.sponsorAddress);
      if (sponsorSigner == null) {
        return AccumulateResponse.failure('Could not create signer for sponsor account');
      }

      // Create lite identity from key pair
      final privateKeyBytes = Uint8List.fromList(hex.decode(keyPair.privateKey));
      final signer = Ed25519KeypairSigner.fromKeyRaw(privateKeyBytes);
      final liteIdentity = LiteIdentity(signer);

      // For token accounts, we need to execute createTokenAccount
      if (request.tokenUrl != null) {
        final createTokenAccountParam = CreateTokenAccountParam();
        createTokenAccountParam.url = liteIdentity.url.toString();
        createTokenAccountParam.tokenUrl = request.tokenUrl!;

        final response = await _acmeClient.createTokenAccount(
          request.sponsorAddress,
          createTokenAccountParam,
          sponsorSigner,
        );

        final result = _parseResponse(response);
        if (result.success) {
          return AccumulateResponse.success(
            transactionId: result.transactionId,
            hash: result.hash,
            data: {
              'address': liteIdentity.url.toString(),
              'publicKey': keyPair.publicKey,
              'privateKey': keyPair.privateKey,
              'publicKeyHash': keyPair.publicKeyHash,
            },
          );
        }
        return result;
      } else {
        // For ACME accounts, just return the generated account info
        return AccumulateResponse.success(
          data: {
            'address': liteIdentity.url.toString(),
            'publicKey': keyPair.publicKey,
            'privateKey': keyPair.privateKey,
            'publicKeyHash': keyPair.publicKeyHash,
          },
        );
      }
    } catch (e) {
      return AccumulateResponse.failure('Error creating lite token account: ${e.toString()}');
    }
  }

  /// Create an ADI token account
  Future<AccumulateResponse> createADITokenAccount(CreateADITokenAccountRequest request) async {
    try {
      // Get signing key page (same as data account creation)
      final signer = await _keyService.createADISigner(request.keyPageUrl);
      if (signer == null) {
        return AccumulateResponse.failure('Could not create signer for key page');
      }

      // Create token account parameters
      final createTokenAccountParam = CreateTokenAccountParam();
      createTokenAccountParam.url = request.accountUrl;
      createTokenAccountParam.tokenUrl = request.tokenUrl;

      // Execute transaction
      debugPrint('Creating ADI token account: ${request.accountUrl}');
      debugPrint('Identity URL: ${request.identityUrl}');
      debugPrint('Key page URL: ${request.keyPageUrl}');
      debugPrint('Signer: ${signer.url} (version: ${signer.version})');

      final response = await _acmeClient.createTokenAccount(
        request.identityUrl,
        createTokenAccountParam,
        signer,
      );

      debugPrint('Create ADI token account response: $response');
      return _parseResponse(response);
    } catch (e) {
      return AccumulateResponse.failure('Error creating ADI token account: ${e.toString()}');
    }
  }

  /// Create a data account
  Future<AccumulateResponse> createDataAccount(CreateDataAccountRequest request) async {
    try {
      // Get signing key page
      final signer = await _keyService.createADISigner(request.keyPageUrl);
      if (signer == null) {
        return AccumulateResponse.failure('Could not create signer for key page');
      }

      // Create data account parameters
      final createDataAccountParam = CreateDataAccountParam();
      createDataAccountParam.url = request.accountUrl;

      // Execute transaction
      debugPrint('Creating data account: ${request.accountUrl}');
      debugPrint('Identity URL: ${request.identityUrl}');
      debugPrint('Key page URL: ${request.keyPageUrl}');
      debugPrint('Signer: ${signer.url} (version: ${signer.version})');

      final response = await _acmeClient.createDataAccount(
        request.identityUrl,
        createDataAccountParam,
        signer,
      );

      debugPrint('Data account creation response: $response');
      return _parseResponse(response);
    } catch (e) {
      return AccumulateResponse.failure('Error creating data account: ${e.toString()}');
    }
  }

  /// Create a key book
  Future<AccumulateResponse> createKeyBook(CreateKeyBookRequest request) async {
    try {
      debugPrint('Creating key book: ${request.keyBookUrl}');
      debugPrint('Identity URL: ${request.identityUrl}');
      debugPrint('Signer key page URL: ${request.keyPageUrl}');
      debugPrint('Public key hash: ${request.publicKeyHash}');

      // Get the raw Ed25519KeypairSigner for the key page (like SDK example)
      final rawSigner = await _keyService.getADIPrivateKeySigner(request.keyPageUrl);
      if (rawSigner == null) {
        return AccumulateResponse.failure('Could not get private key signer for key page: ${request.keyPageUrl}');
      }

      // Create TxSigner with the key page URL and raw signer (following SDK pattern)
      var txSigner = TxSigner(request.keyPageUrl, rawSigner);

      // Query for current version (critical for key operations)
      debugPrint('Querying key page version...');
      final versionResponse = await _acmeClient.queryUrl(txSigner.url);
      if (versionResponse['result'] != null && versionResponse['result']['data'] != null) {
        final version = versionResponse['result']['data']['version'] ?? 1;
        debugPrint('Key page version: $version');
        txSigner = TxSigner.withNewVersion(txSigner, version);
      }

      // Create key book parameters
      final createKeyBookParam = CreateKeyBookParam();
      createKeyBookParam.url = request.keyBookUrl;
      createKeyBookParam.publicKeyHash = Uint8List.fromList(hex.decode(request.publicKeyHash));

      debugPrint('Key book params:');
      debugPrint('  - Key book URL: ${createKeyBookParam.url}');
      debugPrint('  - Public key hash: ${request.publicKeyHash}');

      // Execute transaction
      debugPrint('Sending createKeyBook request...');
      final response = await _acmeClient.createKeyBook(
        request.identityUrl,
        createKeyBookParam,
        txSigner,
      );

      debugPrint('Create key book response: $response');
      return _parseResponse(response);
    } catch (e) {
      debugPrint(' Error creating key book: ${e.toString()}');
      return AccumulateResponse.failure('Error creating key book: ${e.toString()}');
    }
  }

  /// Create a key page
  Future<AccumulateResponse> createKeyPage(CreateKeyPageRequest request) async {
    try {
      debugPrint('Creating key page: ${request.keyPageUrl}');
      debugPrint('Key book URL: ${request.keyBookUrl}');
      debugPrint('Signer key page URL: ${request.signerKeyPageUrl}');
      debugPrint('Public key hashes: ${request.publicKeyHashes}');

      // Get the raw Ed25519KeypairSigner for the signing key page (like SDK example)
      final rawSigner = await _keyService.getADIPrivateKeySigner(request.signerKeyPageUrl);
      if (rawSigner == null) {
        return AccumulateResponse.failure('Could not get private key signer for key page: ${request.signerKeyPageUrl}');
      }

      // Create TxSigner with the signing key page URL and raw signer (following SDK pattern)
      var txSigner = TxSigner(request.signerKeyPageUrl, rawSigner);

      // Query for current version (critical for key operations)
      debugPrint('Querying signer key page version...');
      final versionResponse = await _acmeClient.queryUrl(txSigner.url);
      if (versionResponse['result'] != null && versionResponse['result']['data'] != null) {
        final version = versionResponse['result']['data']['version'] ?? 1;
        debugPrint('Signer key page version: $version');
        txSigner = TxSigner.withNewVersion(txSigner, version);
      }

      // Create key page parameters (SDK uses public keys, not hashes)
      final createKeyPageParam = CreateKeyPageParam();
      createKeyPageParam.keys = request.publicKeyHashes
          .map((hash) => Uint8List.fromList(hex.decode(hash)))
          .toList();

      debugPrint('Key page params:');
      debugPrint('  - New key page URL: ${request.keyPageUrl}');
      debugPrint('  - Number of keys: ${createKeyPageParam.keys.length}');

      // Execute transaction
      debugPrint('Sending createKeyPage request...');
      final response = await _acmeClient.createKeyPage(
        request.keyBookUrl,
        createKeyPageParam,
        txSigner,
      );

      debugPrint('Create key page response: $response');
      return _parseResponse(response);
    } catch (e) {
      debugPrint(' Error creating key page: ${e.toString()}');
      return AccumulateResponse.failure('Error creating key page: ${e.toString()}');
    }
  }

  /// Create a custom token
  Future<AccumulateResponse> createCustomToken(CreateCustomTokenRequest request) async {
    try {
      // Get signing key page
      final signer = await _keyService.createADISigner(request.keyPageUrl);
      if (signer == null) {
        return AccumulateResponse.failure('Could not create signer for key page');
      }

      // Create token parameters
      final createTokenParam = CreateTokenParam();
      createTokenParam.url = request.tokenUrl;
      createTokenParam.symbol = request.symbol;
      createTokenParam.precision = request.precision;

      // Execute transaction
      final response = await _acmeClient.createToken(
        request.identityUrl,
        createTokenParam,
        signer,
      );

      return _parseResponse(response);
    } catch (e) {
      return AccumulateResponse.failure('Error creating custom token: ${e.toString()}');
    }
  }

  /// Mint tokens
  Future<AccumulateResponse> mintTokens(MintTokensRequest request) async {
    try {
      // Get signing key page
      final signer = await _keyService.createADISigner(request.keyPageUrl);
      if (signer == null) {
        return AccumulateResponse.failure('Could not create signer for key page');
      }

      // Create mint parameters
      final tokenRecipientParam = TokenRecipientParam();
      tokenRecipientParam.amount = request.amount;
      tokenRecipientParam.url = request.recipientUrl;

      final issueTokensParam = IssueTokensParam();
      issueTokensParam.to = [tokenRecipientParam];

      // Execute transaction
      final response = await _acmeClient.issueTokens(
        request.tokenUrl,
        issueTokensParam,
        signer,
      );

      return _parseResponse(response);
    } catch (e) {
      return AccumulateResponse.failure('Error minting tokens: ${e.toString()}');
    }
  }

  /// Burn tokens
  Future<AccumulateResponse> burnTokens(BurnTokensRequest request) async {
    try {
      // Get signing key page
      final signer = await _keyService.createADISigner(request.keyPageUrl);
      if (signer == null) {
        return AccumulateResponse.failure('Could not create signer for key page');
      }

      // Create burn parameters
      final burnTokensParam = BurnTokensParam();
      burnTokensParam.amount = request.amount;

      // Execute transaction
      final response = await _acmeClient.burnTokens(
        request.tokenAccountUrl,
        burnTokensParam,
        signer,
      );

      return _parseResponse(response);
    } catch (e) {
      return AccumulateResponse.failure('Error burning tokens: ${e.toString()}');
    }
  }

  /// Query if identity exists
  Future<bool> _checkIdentityExists(String identityUrl) async {
    try {
      await _acmeClient.queryUrl(identityUrl);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate identity name format
  bool _isValidIdentityName(String name) {
    // Allow letters, numbers, and hyphens only
    final RegExp validName = RegExp(r'^[a-zA-Z0-9-]+$');
    return validName.hasMatch(name) && name.isNotEmpty && name.length <= 64;
  }

  /// Parse API response to standardized format
  AccumulateResponse _parseResponse(Map<String, dynamic> response) {
    try {
      debugPrint('Parsing response: $response');
      final result = response['result'];

      if (result != null) {
        // Check for transaction result format
        if (result is List && result.isNotEmpty) {
          // Handle array format responses
          final firstItem = result[0];
          if (firstItem is Map && firstItem.containsKey('failed') && firstItem['failed'] == true) {
            final error = firstItem['error']?['message'] ?? 'Transaction failed';
            return AccumulateResponse.failure(error);
          }
        }

        // For key page/key book creation, check if it has a result array indicating success
        if (result is Map) {
          final resultArray = result['result'];
          if (resultArray is List && resultArray.isNotEmpty) {
            // Check if all transactions in the result array are successful
            bool hasFailures = false;
            for (final item in resultArray) {
              if (item is Map && item['code'] != 'ok') {
                hasFailures = true;
                break;
              }
            }

            if (!hasFailures) {
              // All transactions successful
              final txId = result['txid'] ?? result['transactionId'] ?? result['transactionHash'];
              final hash = result['hash'] ?? result['transactionHash'] ?? result['simpleHash'];

              debugPrint(' All transactions successful, txId: $txId');
              return AccumulateResponse.success(
                transactionId: txId?.toString(),
                hash: hash?.toString(),
                data: Map<String, dynamic>.from(result),
              );
            }
          }
        }

        // Extract transaction ID (try multiple field names)
        final txId = result['txid'] ??
                    result['transactionId'] ??
                    result['transactionHash'];
        final hash = result['hash'] ??
                    result['transactionHash'] ??
                    result['simpleHash'];

        if (txId != null) {
          debugPrint(' Transaction successful, txId: $txId');
          return AccumulateResponse.success(
            transactionId: txId.toString(),
            hash: hash?.toString(),
            data: result is Map ? Map<String, dynamic>.from(result) : null,
          );
        }
      }

      // Check for error in response
      final error = response['error'];
      if (error != null) {
        final message = error['message'] ?? error.toString();
        debugPrint(' API error: $message');
        return AccumulateResponse.failure(message);
      }

      debugPrint(' Unknown response format');
      return AccumulateResponse.failure('Unknown response format');
    } catch (e) {
      debugPrint(' Error parsing response: ${e.toString()}');
      return AccumulateResponse.failure('Error parsing response: ${e.toString()}');
    }
  }

  /// Get network fee schedule for cost estimation
  Future<Map<String, int>> getNetworkFees() async {
    try {
      final response = await _acmeClient.describe();
      final globals = response['result']?['values']?['globals'];

      if (globals != null) {
        final feeSchedule = globals['feeSchedule'];
        return {
          'createIdentity': feeSchedule?['createIdentity'] ?? 2500000,
          'createKeyBook': feeSchedule?['createKeyBook'] ?? 100000,
          'createKeyPage': feeSchedule?['createKeyPage'] ?? 100000,
          'createTokenAccount': feeSchedule?['createTokenAccount'] ?? 25000,
          'createDataAccount': feeSchedule?['createDataAccount'] ?? 25000,
          'createToken': feeSchedule?['createToken'] ?? 100000,
        };
      }

      // Return default values if unable to fetch
      return {
        'createIdentity': 2500000,
        'createKeyBook': 100000,
        'createKeyPage': 100000,
        'createTokenAccount': 25000,
        'createDataAccount': 25000,
        'createToken': 100000,
      };
    } catch (e) {
      // Return default values on error
      return {
        'createIdentity': 2500000,
        'createKeyBook': 100000,
        'createKeyPage': 100000,
        'createTokenAccount': 25000,
        'createDataAccount': 25000,
        'createToken': 100000,
      };
    }
  }

  /// Get sliding fee for identity names (shorter names cost more)
  Future<int> getIdentityCreationCost(String name) async {
    try {
      final adiSlidingFee = await _acmeClient.getAdiSlidingFee();

      // Determine cutoff based on network (mainnet vs testnet)
      final baseUrl = _acmeClient.toString();
      final cutoffValue = baseUrl.contains('mainnet') ? 8 : 13;

      if (name.length < cutoffValue && name.length <= adiSlidingFee.length) {
        return adiSlidingFee[name.length - 1];
      }

      return 2500000; // Base fee for longer names
    } catch (e) {
      return 2500000; // Default fee on error
    }
  }
}