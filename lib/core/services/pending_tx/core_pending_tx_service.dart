// Core pending transaction service - no Flutter dependencies
import '../blockchain/accumulate_api_service.dart';
import '../../models/pending_transaction.dart';

class CorePendingTxService {
  final AccumulateApiService _apiService;

  CorePendingTxService(this._apiService);

  /// Find all pending transactions for given signing paths
  Future<FilteredPendingResponse> findAllPendingNeedingSignatureForUser({
    required List<String> signingPaths,
    required String baseAdi,
    required String userSignerUrl,
  }) async {
    final List<PathBucket> buckets = [];
    int totalCount = 0;

    for (final signingPath in signingPaths) {
      try {
        final transactions =
            await _apiService.getPendingTransactions(signingPath);

        if (transactions.isNotEmpty) {
          // Extract path components for bucket
          final pathParts = signingPath.split(' -> ');
          final signer = pathParts.last;
          final priorHop =
              pathParts.length > 1 ? pathParts[pathParts.length - 2] : signer;

          buckets.add(PathBucket(
            signingPath: signingPath,
            signer: signer,
            priorHop: priorHop,
            transactions: transactions,
          ));

          totalCount += transactions.length;
        }
      } catch (e) {
        // Log error but continue processing other paths
        continue;
      }
    }

    return FilteredPendingResponse(
      count: totalCount,
      bySigningPath: buckets,
    );
  }

  /// Flatten pending response to simple list
  List<Map<String, String>> flatten(FilteredPendingResponse response) {
    final List<Map<String, String>> result = [];

    for (final bucket in response.bySigningPath) {
      for (final tx in bucket.transactions) {
        result.add(tx.toMap());
      }
    }

    return result;
  }

  /// Get pending count for a specific signer
  Future<int> getPendingCount(String signerUrl) async {
    try {
      final transactions = await _apiService.getPendingTransactions(signerUrl);
      return transactions.length;
    } catch (e) {
      return 0;
    }
  }

  /// Check if there are any pending transactions for user
  Future<bool> hasPendingTransactions(List<String> signingPaths) async {
    for (final path in signingPaths) {
      final count = await getPendingCount(path);
      if (count > 0) return true;
    }
    return false;
  }
}
