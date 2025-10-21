import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:convert/convert.dart';
import 'package:accumulate_api/accumulate_api.dart';
import '../crypto/key_management_service.dart';
import '../storage/database_helper.dart';
import '../../models/local_storage_models.dart';

class TransactionSigningService {
  final KeyManagementService _keyService;
  final DatabaseHelper _dbHelper;
  final String _baseUrl;

  TransactionSigningService({
    required KeyManagementService keyService,
    required DatabaseHelper dbHelper,
    required String baseUrl,
  }) : _keyService = keyService,
       _dbHelper = dbHelper,
       _baseUrl = baseUrl;

  /// Sign a transaction using the provided hash and signer key page
  Future<TransactionSigningResult> signTransaction({
    required String transactionHash,
    required String signerKeyPageUrl,
  }) async {
    try {
      final client = ACMEClient(_baseUrl);

      // Step 1: Query transaction by hash
      debugPrint('Querying transaction: $transactionHash');
      final response = await client.queryTx("acc://$transactionHash@unknown");

      if (response['result'] == null || response['result']['transaction'] == null) {
        return TransactionSigningResult.failure('Transaction not found');
      }

      final rawTx = response['result']['transaction'];
      final timestamp = DateTime.now().microsecondsSinceEpoch;

      // Step 2: Parse/unmarshal the transaction
      debugPrint('Parsing transaction...');
      final tx = await _unmarshalTransaction(rawTx, transactionHash, timestamp);

      // Step 3: Create signer info with correct version
      debugPrint('Creating signer info...');
      final signerInfo = await _createSignerInfo(client, signerKeyPageUrl);

      // Step 4: Get private key for signing
      final privateKey = await _getPrivateKeyForSigner(signerKeyPageUrl);
      if (privateKey == null) {
        return TransactionSigningResult.failure('Private key not found for signer');
      }

      // Step 5: Generate signature
      debugPrint(' Generating signature...');
      final signer = Ed25519KeypairSigner.fromKeyRaw(privateKey);
      final preimage = tx.dataForSignature(signerInfo).asUint8List();
      final signatureBytes = signer.signRaw(preimage);
      final signatureHex = hex.encode(signatureBytes);

      // Step 6: Get public key for verification
      final publicKey = await _getPublicKeyForSigner(signerKeyPageUrl);
      if (publicKey == null) {
        return TransactionSigningResult.failure('Public key not found for signer');
      }
      final publicKeyHex = hex.encode(publicKey);

      // Step 7: Submit transaction with signature
      debugPrint('Submitting signed transaction...');
      final submitResponse = await client.call("execute-direct", {
        "envelope": {
          "transaction": [rawTx],
          "signatures": [
            {
              "type": "ed25519",
              "publicKey": publicKeyHex,
              "signature": signatureHex,
              "signer": signerInfo.url.toString(),
              "signerVersion": signerInfo.version,
              "timestamp": timestamp,
              "transactionHash": transactionHash,
            }
          ],
        },
      });

      debugPrint(' Transaction signed and submitted successfully');

      return TransactionSigningResult.success(
        transactionHash: transactionHash,
        signatureHash: signatureHex,
        submitResponse: submitResponse,
      );

    } catch (e, stackTrace) {
      debugPrint(' Error signing transaction: $e');
      debugPrint('Stack trace: $stackTrace');
      return TransactionSigningResult.failure('Error signing transaction: $e');
    }
  }

  /// Unmarshal transaction from raw data
  Future<Transaction> _unmarshalTransaction(
    dynamic rawTx,
    String txHash,
    int timestamp
  ) async {
    final headerData = rawTx["header"];

    final headerOptions = HeaderOptions()
      ..initiator = _maybeDecodeHex(headerData["initiator"])
      ..memo = headerData["memo"]
      ..metadata = _maybeDecodeHex(headerData["metadata"])
      ..timestamp = timestamp;

    final header = Header(headerData["principal"], headerOptions);
    final payload = _decodePayload(rawTx["body"]);
    final tx = Transaction(payload, header);

    // Verify hash matches
    final computedHash = hex.encode(tx.hash());
    if (txHash != computedHash) {
      throw Exception('Transaction hash mismatch: expected $txHash, got $computedHash');
    }

    return tx;
  }

  /// Create signer info with correct version from key page
  Future<SignerInfo> _createSignerInfo(ACMEClient client, String keyPageUrl) async {
    // Get signer version from key page
    final response = await client.queryUrl(keyPageUrl);
    final version = response["result"]["data"]["version"] ?? 1;

    // Get public key for this signer
    final publicKey = await _getPublicKeyForSigner(keyPageUrl);

    final signerInfo = SignerInfo();
    signerInfo.type = SignatureType.signatureTypeED25519;
    signerInfo.url = AccURL(keyPageUrl);
    signerInfo.version = version;
    signerInfo.publicKey = publicKey;

    return signerInfo;
  }

  /// Get private key for signer from secure storage
  Future<Uint8List?> _getPrivateKeyForSigner(String signerUrl) async {
    try {
      return await _keyService.getPrivateKeyBytes(signerUrl);
    } catch (e) {
      debugPrint('Error getting private key for signer: $e');
      return null;
    }
  }

  /// Get public key for signer
  Future<Uint8List?> _getPublicKeyForSigner(String signerUrl) async {
    try {
      return await _keyService.getPublicKeyBytes(signerUrl);
    } catch (e) {
      debugPrint('Error getting public key for signer: $e');
      return null;
    }
  }

  /// Convert hex string to bytes
  Uint8List _hexToBytes(String hexString) {
    return Uint8List.fromList(hex.decode(hexString));
  }

  /// Decode transaction payload based on type
  Payload _decodePayload(dynamic data) {
    final type = data["type"] as String;
    debugPrint('Decoding payload type: $type');

    switch (type.toLowerCase()) {
      case "sendtokens":
        return _decodeSendTokens(data);
      case "writedata":
        return _decodeWriteData(data);
      case "writedatato":
        return _decodeWriteDataTo(data);
      case "updatekeypage":
        return _decodeUpdateKeyPage(data);
      case "createidentity":
        return _decodeCreateIdentity(data);
      case "createtokenaccount":
        return _decodeCreateTokenAccount(data);
      case "createtoken":
        return _decodeCreateToken(data);
      case "issuetokens":
        return _decodeIssueTokens(data);
      case "addcredits":
        return _decodeAddCredits(data);
      case "updateaccountauth":
        return _decodeUpdateAccountAuth(data);
      case "updatekey":
        return _decodeUpdateKey(data);
      case "burntokens":
        return _decodeBurnTokens(data);
      case "createkeybook":
        return _decodeCreateKeyBook(data);
      case "createdataaccount":
        return _decodeCreateDataAccount(data);
      case "createkeypage":
        return _decodeCreateKeyPage(data);
      default:
        throw Exception('Unsupported transaction type: $type');
    }
  }

  /// Decode SendTokens payload
  Payload _decodeSendTokens(dynamic data) {
    final toList = data["to"] as List<dynamic>;
    final recipients = toList.map((recipientData) {
      final recipient = TokenRecipientParam();
      recipient.url = recipientData["url"] as String;
      recipient.amount = recipientData["amount"] as String;
      return recipient;
    }).toList();

    final param = SendTokensParam()
      ..to = recipients
      ..memo = data["memo"] as String?
      ..metadata = _maybeDecodeHex(data["metadata"]);

    return SendTokens(param);
  }

  /// Decode WriteData payload
  Payload _decodeWriteData(dynamic data) {
    if (data["entry"]["type"] != "doubleHash") {
      throw Exception("Unsupported data entry type");
    }

    final param = WriteDataParam()
      ..scratch = data["scratch"] ?? false
      ..writeToState = data["writeToState"] ?? false
      ..data = (data["entry"]["data"] as List<dynamic>?)
          ?.map((s) => hex.decode(s as String))
          .cast<Uint8List>()
          .toList() ?? [];

    return WriteData(param);
  }

  /// Decode WriteDataTo payload
  Payload _decodeWriteDataTo(dynamic data) {
    if (data["entry"]["type"] != "doubleHash") {
      throw Exception("Unsupported data entry type");
    }

    final param = WriteDataToParam(
      recipient: data["recipient"],
      data: (data["entry"]["data"] as List<dynamic>?)
          ?.map((s) => hex.decode(s as String))
          .cast<Uint8List>()
          .toList() ?? [],
    );

    return WriteDataTo(param);
  }

  /// Decode UpdateKeyPage payload
  Payload _decodeUpdateKeyPage(dynamic data) {
    final operationsData = data["operation"] as List<dynamic>?;
    final operations = operationsData?.map((op) {
      final keyOperation = KeyOperation()
        ..type = _parseOperationType(op["type"] as String?)
        ..key = (op["entry"] != null
            ? (KeySpec()..delegate = op["entry"]["delegate"])
            : null);
      return keyOperation;
    }).toList() ?? [];

    final param = UpdateKeyPageParam()
      ..operations = operations
      ..memo = data["memo"] as String?
      ..metadata = _maybeDecodeHex(data["metadata"]);

    return UpdateKeyPage(param);
  }

  /// Decode CreateIdentity payload
  Payload _decodeCreateIdentity(dynamic data) {
    final param = CreateIdentityParam()
      ..url = data["url"] as String?
      ..keyHash = _maybeDecodeHex(data["keyHash"])
      ..keyBookUrl = data["keyBookUrl"] as String?
      ..memo = data["memo"] as String?
      ..metadata = _maybeDecodeHex(data["metadata"]);

    return CreateIdentity(param);
  }

  /// Decode CreateTokenAccount payload
  Payload _decodeCreateTokenAccount(dynamic data) {
    final authorities = (data["authorities"] as List<dynamic>?)
        ?.map((authUrl) => AccURL.toAccURL(authUrl))
        .toList();

    final param = CreateTokenAccountParam()
      ..url = data["url"] as String?
      ..tokenUrl = data["tokenUrl"] as String?
      ..memo = data["memo"] as String?
      ..metadata = _maybeDecodeHex(data["metadata"])
      ..authorities = authorities;

    return CreateTokenAccount(param);
  }

  /// Decode CreateToken payload
  Payload _decodeCreateToken(dynamic data) {
    final authorities = (data["authorities"] as List<dynamic>?)
        ?.map((authUrl) => AccURL.toAccURL(authUrl))
        .toList();

    final param = CreateTokenParam()
      ..url = data["url"] as String?
      ..symbol = data["symbol"] as String? ?? ""
      ..precision = data["precision"] as int? ?? 0
      ..properties = data["properties"] != null ? AccURL.toAccURL(data["properties"]) : null
      ..supplyLimit = data["supplyLimit"]
      ..authorities = authorities
      ..memo = data["memo"] as String?
      ..metadata = _maybeDecodeHex(data["metadata"]);

    return CreateToken(param);
  }

  /// Decode IssueTokens payload
  Payload _decodeIssueTokens(dynamic data) {
    final toList = data["to"] as List<dynamic>;
    final recipients = toList.map((recipientData) {
      final recipient = TokenRecipientParam();
      recipient.url = recipientData["url"] as String;
      recipient.amount = int.parse(recipientData["amount"] as String);
      return recipient;
    }).toList();

    final param = IssueTokensParam()
      ..to = recipients
      ..memo = data["memo"] as String?
      ..metadata = _maybeDecodeHex(data["metadata"]);

    return IssueTokens(param);
  }

  /// Decode AddCredits payload
  Payload _decodeAddCredits(dynamic data) {
    final param = AddCreditsParam()
      ..recipient = data["recipient"] as String
      ..amount = int.parse(data["amount"] as String)
      ..oracle = data["oracle"] as int
      ..memo = data["memo"] as String?
      ..metadata = _maybeDecodeHex(data["metadata"]);

    return AddCredits(param);
  }

  /// Decode UpdateAccountAuth payload
  Payload _decodeUpdateAccountAuth(dynamic data) {
    final operationsData = data["operations"] as List<dynamic>;
    final operations = operationsData.map((opData) {
      final op = UpdateAccountAuthOperation();
      op.type = _parseAccountAuthOperationType(opData["type"] as String);
      op.authority = opData["authority"] as String;
      return op;
    }).toList();

    final param = UpdateAccountAuthParam()
      ..operations = operations
      ..memo = data["memo"] as String?
      ..metadata = _maybeDecodeHex(data["metadata"]);

    return UpdateAccountAuth(param);
  }

  /// Decode UpdateKey payload
  Payload _decodeUpdateKey(dynamic data) {
    final newKeyHashStr = data["newKeyHash"] as String?;
    if (newKeyHashStr == null) {
      throw Exception("newKeyHash is missing from the payload");
    }

    final param = UpdateKeyParam()
      ..newKeyHash = hex.decode(newKeyHashStr) as Uint8List
      ..memo = data["memo"] as String?
      ..metadata = _maybeDecodeHex(data["metadata"]);

    return UpdateKey(param);
  }

  /// Decode BurnTokens payload
  Payload _decodeBurnTokens(dynamic data) {
    final amountStr = data["amount"] as String?;
    if (amountStr == null) {
      throw Exception("Amount is missing from the burnTokens payload");
    }

    final param = BurnTokensParam()
      ..amount = int.parse(amountStr)
      ..memo = data["memo"] as String?
      ..metadata = _maybeDecodeHex(data["metadata"]);

    return BurnTokens(param);
  }

  /// Decode CreateKeyBook payload
  Payload _decodeCreateKeyBook(dynamic data) {
    final url = data["url"] as String?;
    if (url == null) {
      throw Exception("URL is missing from the createKeyBook payload");
    }

    final publicKeyHashHex = data["publicKeyHash"] as String?;
    if (publicKeyHashHex == null) {
      throw Exception("Public key hash is missing from the createKeyBook payload");
    }

    final authoritiesData = data["authorities"] as List<dynamic>?;
    final authorities = authoritiesData
        ?.map((authUrl) => AccURL.toAccURL(authUrl as String))
        .toList();

    final param = CreateKeyBookParam()
      ..url = url
      ..publicKeyHash = hex.decode(publicKeyHashHex) as Uint8List
      ..memo = data["memo"] as String?
      ..metadata = _maybeDecodeHex(data["metadata"])
      ..authorities = authorities;

    return CreateKeyBook(param);
  }

  /// Decode CreateDataAccount payload
  Payload _decodeCreateDataAccount(dynamic data) {
    final authoritiesData = data["authorities"] as List<dynamic>?;
    final authorities = authoritiesData
        ?.map((authUrl) => AccURL.toAccURL(authUrl as String))
        .toList();

    final param = CreateDataAccountParam()
      ..url = data["url"] as String?
      ..authorities = authorities
      ..memo = data["memo"] as String?
      ..metadata = _maybeDecodeHex(data["metadata"]);

    return CreateDataAccount(param);
  }

  /// Decode CreateKeyPage payload
  Payload _decodeCreateKeyPage(dynamic data) {
    final keysData = data["keys"] as List<dynamic>?;
    if (keysData == null) {
      throw Exception("Keys data is missing in the createKeyPage payload");
    }

    final keys = <Uint8List>[];
    for (final keyData in keysData) {
      final keyHash = keyData["keyHash"] as String?;
      if (keyHash == null) {
        throw Exception("Key hash is missing from a key data entry");
      }
      keys.add(hex.decode(keyHash) as Uint8List);
    }

    final param = CreateKeyPageParam()
      ..keys = keys
      ..memo = data["memo"] as String?
      ..metadata = _maybeDecodeHex(data["metadata"]);

    return CreateKeyPage(param);
  }

  /// Parse operation type for key page operations
  int? _parseOperationType(String? operationType) {
    if (operationType == null) return null;

    switch (operationType.toLowerCase()) {
      case 'update':
        return KeyPageOperationType.Update;
      case 'remove':
        return KeyPageOperationType.Remove;
      case 'add':
        return KeyPageOperationType.Add;
      case 'setthreshold':
        return KeyPageOperationType.SetThreshold;
      case 'updateallowed':
        return KeyPageOperationType.UpdateAllowed;
      default:
        debugPrint("Unknown operation type: $operationType");
        return null;
    }
  }

  /// Parse account auth operation type
  int _parseAccountAuthOperationType(String operationType) {
    switch (operationType.toLowerCase()) {
      case 'enable':
        return UpdateAccountAuthActionType.Enable;
      case 'disable':
        return UpdateAccountAuthActionType.Disable;
      case 'addauthority':
        return UpdateAccountAuthActionType.AddAuthority;
      case 'removeauthority':
        return UpdateAccountAuthActionType.RemoveAuthority;
      default:
        debugPrint("Unknown operation type: $operationType, defaulting to Disable");
        return UpdateAccountAuthActionType.Disable;
    }
  }

  /// Maybe decode hex string to bytes
  Uint8List? _maybeDecodeHex(String? hexString) {
    if (hexString == null) return null;
    try {
      return Uint8List.fromList(hex.decode(hexString));
    } catch (e) {
      debugPrint("Failed to decode hex: $e");
      return null;
    }
  }
}

/// Result of transaction signing operation
class TransactionSigningResult {
  final bool success;
  final String? transactionHash;
  final String? signatureHash;
  final dynamic submitResponse;
  final String? error;

  TransactionSigningResult._({
    required this.success,
    this.transactionHash,
    this.signatureHash,
    this.submitResponse,
    this.error,
  });

  factory TransactionSigningResult.success({
    required String transactionHash,
    required String signatureHash,
    required dynamic submitResponse,
  }) {
    return TransactionSigningResult._(
      success: true,
      transactionHash: transactionHash,
      signatureHash: signatureHash,
      submitResponse: submitResponse,
    );
  }

  factory TransactionSigningResult.failure(String error) {
    return TransactionSigningResult._(
      success: false,
      error: error,
    );
  }
}