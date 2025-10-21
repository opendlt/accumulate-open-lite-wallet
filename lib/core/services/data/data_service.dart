import 'package:flutter/foundation.dart';
// Data service for writing and retrieving data entries
import 'dart:convert';
import 'dart:typed_data';
import '../blockchain/enhanced_accumulate_service.dart';
import '../crypto/key_management_service.dart';
import '../storage/database_helper.dart';
import '../../models/accumulate_requests.dart';
import '../../models/local_storage_models.dart';
import 'package:accumulate_api/accumulate_api.dart';

class DataService {
  final DatabaseHelper _dbHelper;
  final KeyManagementService _keyService;
  final EnhancedAccumulateService _accumulateService;

  DataService({
    required DatabaseHelper dbHelper,
    required KeyManagementService keyService,
    required EnhancedAccumulateService accumulateService,
  })  : _dbHelper = dbHelper,
        _keyService = keyService,
        _accumulateService = accumulateService;

  /// Write data to a data account
  Future<DataResponse> writeData(WriteDataRequest request) async {
    try {
      // Validate data entries
      if (request.dataEntries.isEmpty) {
        return DataResponse.failure('At least one data entry is required');
      }

      // Validate data account URL
      if (!_isValidDataAccountUrl(request.dataAccountUrl)) {
        return DataResponse.failure('Invalid data account URL format');
      }

      // Determine signing method based on account type
      var signer = await _createSigner(request.signerUrl);
      if (signer == null) {
        return DataResponse.failure('Unable to create signer for account');
      }

      // Convert string data entries to Uint8List
      final dataEntries = request.dataEntries
          .map((entry) => utf8.encode(entry).asUint8List())
          .toList();

      // Create write data parameters
      final writeDataParam = WriteDataParam();
      writeDataParam.data = dataEntries;
      writeDataParam.scratch = request.scratch;
      writeDataParam.writeToState = request.writeToState;

      if (request.memo != null) {
        writeDataParam.memo = request.memo;
      }

      if (request.metadata != null) {
        writeDataParam.metadata = utf8.encode(jsonEncode(request.metadata)).asUint8List();
      }

      // Execute the transaction
      final client = ACMEClient(_accumulateService.baseUrl);

      // Important: For writeData, we need to ensure the signer has the correct version
      // This matches the working Dart client pattern
      try {
        debugPrint('Writing data to: ${request.dataAccountUrl}');
        debugPrint('Signer URL: ${signer.url}');
        debugPrint('Data entries: ${request.dataEntries.length}');
        debugPrint('Write to state: ${request.writeToState}');
        debugPrint('Scratch: ${request.scratch}');

        // Query current version of signer (key page or lite identity)
        final versionResponse = await client.queryUrl(signer.url);
        if (versionResponse['result'] != null && versionResponse['result']['data'] != null) {
          final currentVersion = versionResponse['result']['data']['version'] ?? 1;
          debugPrint('Current signer version: $currentVersion');

          // Update signer with current version if different
          if (signer.version != currentVersion) {
            signer = TxSigner.withNewVersion(signer, currentVersion);
            debugPrint('⬆️  Updated signer to version: ${signer.version}');
          }
        }
      } catch (e) {
        debugPrint('Warning: Could not query signer version: $e');
        // Continue with current signer version
      }

      final response = await client.writeData(
        request.dataAccountUrl,
        writeDataParam,
        signer!,
      );

      debugPrint('Write data response: $response');

      final result = _parseResponse(response);

      if (result.success && result.transactionId != null) {
        // TODO: Implement DataEntry model and insertDataEntry method
        // Store data entries locally for caching
        // for (int i = 0; i < request.dataEntries.length; i++) {
        //   final dataEntry = DataEntry(
        //     data: request.dataEntries[i],
        //     dataAccountUrl: request.dataAccountUrl,
        //     timestamp: DateTime.now(),
        //     transactionId: result.transactionId,
        //     isState: request.writeToState,
        //     metadata: request.metadata,
        //   );

        //   try {
        //     await _dbHelper.insertDataEntry(dataEntry);
        //   } catch (e) {
        //     // Ignore duplicate key errors for local storage
        //   }
        // }
      }

      return result;
    } catch (e) {
      return DataResponse.failure('Error writing data: ${e.toString()}');
    }
  }

  /// Query data entries from a data account
  Future<DataHistoryResponse> queryDataEntries(QueryDataHistoryRequest request) async {
    try {
      final client = ACMEClient(_accumulateService.baseUrl);

      // Set up pagination parameters
      final pagination = QueryPagination();
      pagination.start = request.start;
      pagination.count = request.count;

      final queryOptions = QueryOptions();
      if (request.expand != null) {
        queryOptions.expand = request.expand;
      }
      if (request.scratch != null) {
        queryOptions.scratch = request.scratch;
      }

      // Query from network
      final response = await client.queryDataSet(
        request.dataAccountUrl,
        pagination,
        queryOptions,
      );

      final entries = <DataEntry>[];

      if (response['result'] != null && response['result']['items'] != null) {
        final items = response['result']['items'] as List;

        for (final item in items) {
          final dataEntry = _parseDataEntryFromNetwork(item);
          if (dataEntry != null) {
            entries.add(dataEntry);

            // Store in local database for caching
            try {
              await _dbHelper.insertDataEntry(dataEntry);
            } catch (e) {
              // Ignore duplicate key errors
            }
          }
        }
      }

      // Also get local entries that might not be on network yet
      final localEntries = await _dbHelper.getDataEntriesByAccount(
        dataAccountUrl: request.dataAccountUrl,
        limit: request.count,
        offset: request.start,
      );

      // Merge and deduplicate entries
      final allEntries = <String, DataEntry>{};

      // Add network entries first (they're more authoritative)
      for (final entry in entries) {
        final key = entry.entryHash ?? '${entry.transactionId}_${entry.data}';
        allEntries[key] = entry;
      }

      // Add local entries that aren't already present
      for (final entry in localEntries) {
        final key = entry.entryHash ?? '${entry.transactionId}_${entry.data}';
        if (!allEntries.containsKey(key)) {
          allEntries[key] = entry;
        }
      }

      // Sort by timestamp descending
      final sortedEntries = allEntries.values.toList();
      sortedEntries.sort((a, b) {
        if (a.timestamp == null && b.timestamp == null) return 0;
        if (a.timestamp == null) return 1;
        if (b.timestamp == null) return -1;
        return b.timestamp!.compareTo(a.timestamp!);
      });

      return DataHistoryResponse.success(
        entries: sortedEntries.take(request.count).toList(),
        totalCount: sortedEntries.length,
      );
    } catch (e) {
      // Fall back to local data on network error
      final localEntries = await _dbHelper.getDataEntriesByAccount(
        dataAccountUrl: request.dataAccountUrl,
        limit: request.count,
        offset: request.start,
      );

      return DataHistoryResponse.success(
        entries: localEntries,
        totalCount: localEntries.length,
      );
    }
  }

  /// Query specific data entry by hash
  Future<DataResponse> queryDataEntry(QueryDataRequest request) async {
    try {
      final client = ACMEClient(_accumulateService.baseUrl);

      final response = await client.queryData(
        request.dataAccountUrl,
        request.entryHash,
      );

      if (response['result'] != null && response['result']['data'] != null) {
        final data = response['result']['data'];
        final dataEntry = DataEntry(
          entryHash: request.entryHash,
          data: data['entry']?.toString() ?? '',
          timestamp: data['timestamp'] != null
              ? DateTime.fromMicrosecondsSinceEpoch(data['timestamp'])
              : null,
        );

        return DataResponse.success(
          entries: [dataEntry],
          data: Map<String, dynamic>.from(data),
        );
      }

      return DataResponse.failure('Data entry not found');
    } catch (e) {
      // Try local storage
      if (request.entryHash != null) {
        final localEntry = await _dbHelper.getDataEntryByHash(request.entryHash!);
        if (localEntry != null) {
          return DataResponse.success(entries: [localEntry]);
        }
      }

      return DataResponse.failure('Error querying data entry: ${e.toString()}');
    }
  }

  /// Query data account information
  Future<DataAccountResponse> queryDataAccount(QueryDataAccountRequest request) async {
    try {
      final client = ACMEClient(_accumulateService.baseUrl);

      final queryOptions = QueryOptions();
      if (request.expand != null) {
        queryOptions.expand = request.expand;
      }

      final response = await client.queryUrl(request.dataAccountUrl, queryOptions);

      if (response['result'] != null) {
        final data = response['result']['data'];
        final type = response['result']['type'];

        if (type == 'dataAccount' || type == 'liteDataAccount') {
          return DataAccountResponse.success(
            url: request.dataAccountUrl,
            accountType: type,
            authorities: data['authorities']?.cast<String>(),
            entryCount: data['entryCount'],
            lastEntryHash: data['lastEntryHash'],
            chainInfo: data != null ? Map<String, dynamic>.from(data) : null,
          );
        }
      }

      return DataAccountResponse.failure('Data account not found');
    } catch (e) {
      return DataAccountResponse.failure('Error querying data account: ${e.toString()}');
    }
  }

  /// Get recent data entries across all accounts
  Future<List<DataEntry>> getRecentDataEntries({int limit = 20}) async {
    return await _dbHelper.getRecentDataEntries(limit: limit);
  }

  /// Search data entries by content
  Future<List<DataEntry>> searchDataEntries({
    String? query,
    String? dataAccountUrl,
    int limit = 50,
  }) async {
    return await _dbHelper.searchDataEntries(
      query: query,
      dataAccountUrl: dataAccountUrl,
      limit: limit,
    );
  }

  /// Get data entry count for an account
  Future<int> getDataEntryCount(String dataAccountUrl) async {
    return await _dbHelper.getDataEntryCount(dataAccountUrl);
  }

  /// Get data statistics
  Future<Map<String, int>> getDataStats() async {
    return await _dbHelper.getDataStats();
  }

  /// Validate data account URL
  bool isValidDataAccountUrl(String url) {
    return _isValidDataAccountUrl(url);
  }

  /// Get available data accounts for dropdown
  Future<List<Map<String, dynamic>>> getDataAccountsForDropdown() async {
    final dataAccounts = await _dbHelper.getAllDataAccounts();
    return dataAccounts.map((account) {
      return {
        'type': 'data_account',
        'url': account.url,
        'name': account.name,
        'displayName': '${account.name} (${_shortenUrl(account.url)})',
      };
    }).toList();
  }

  /// Export data entries for backup
  Future<List<Map<String, dynamic>>> exportDataEntries({
    String? dataAccountUrl,
  }) async {
    List<DataEntry> entries;
    if (dataAccountUrl != null) {
      entries = await _dbHelper.getDataEntriesByAccount(
        dataAccountUrl: dataAccountUrl,
        limit: 10000, // Large limit for export
      );
    } else {
      entries = await _dbHelper.getRecentDataEntries(limit: 10000);
    }

    return entries.map((entry) => entry.toMap()).toList();
  }

  /// Clear data entries for an account
  Future<void> clearDataEntriesForAccount(String dataAccountUrl) async {
    await _dbHelper.deleteDataEntriesForAccount(dataAccountUrl);
  }

  /// Create appropriate signer based on account URL
  Future<TxSigner?> _createSigner(String accountUrl) async {
    try {
      if (accountUrl.contains('.acme')) {
        // ADI account - use key page signer
        return await _keyService.createADISigner(accountUrl);
      } else {
        // Lite account - use lite identity signer
        // Extract base lite identity from token account URL if needed
        String baseLiteIdentity = accountUrl;
        if (accountUrl.endsWith('/ACME')) {
          baseLiteIdentity = accountUrl.substring(0, accountUrl.length - 5);
        }

        debugPrint('🔐 Creating lite identity signer for: $baseLiteIdentity');
        return await _keyService.createLiteIdentitySigner(baseLiteIdentity);
      }
    } catch (e) {
      debugPrint(' Error creating signer: $e');
      return null;
    }
  }

  /// Parse data entry from network response
  DataEntry? _parseDataEntryFromNetwork(Map<String, dynamic> item) {
    try {
      final data = item['data'];
      if (data == null) return null;

      return DataEntry(
        entryHash: item['entryHash'],
        data: data['entry']?.toString() ?? '',
        timestamp: item['timestamp'] != null
            ? DateTime.fromMicrosecondsSinceEpoch(item['timestamp'])
            : null,
        transactionId: item['txid'],
        isState: item['type'] == 'AccumulateDataEntry',
      );
    } catch (e) {
      return null;
    }
  }

  /// Validate data account URL format
  bool _isValidDataAccountUrl(String url) {
    // Basic validation for Accumulate URL format
    final RegExp urlPattern = RegExp(r'^acc://[a-zA-Z0-9\-\.\/]+$');
    return urlPattern.hasMatch(url) && url.length > 6;
  }

  /// Shorten URL for display
  String _shortenUrl(String url) {
    if (url.length <= 30) return url;
    return '${url.substring(0, 15)}...${url.substring(url.length - 10)}';
  }

  /// Parse API response to standardized format
  DataResponse _parseResponse(Map<String, dynamic> response) {
    try {
      final result = response['result'];

      if (result != null) {
        // Check for transaction result format
        if (result is List && result.isNotEmpty) {
          // Handle array format responses
          final firstItem = result[0];
          if (firstItem is Map && firstItem.containsKey('failed') && firstItem['failed'] == true) {
            final error = firstItem['error']?['message'] ?? 'Transaction failed';
            return DataResponse.failure(error);
          }
        }

        // Extract transaction ID
        final txId = response['result']?['txid'] ?? response['result']?['transactionId'];
        final hash = response['result']?['hash'];

        if (txId != null) {
          return DataResponse.success(
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
        return DataResponse.failure(message);
      }

      return DataResponse.failure('Unknown response format');
    } catch (e) {
      return DataResponse.failure('Error parsing response: ${e.toString()}');
    }
  }
}