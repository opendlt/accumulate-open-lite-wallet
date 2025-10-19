// Core model for pending transactions - no Flutter dependencies

class PendingTransaction {
  final String? txId;
  final String? hash;
  final String? type;

  const PendingTransaction({
    this.txId,
    this.hash,
    this.type,
  });

  Map<String, String> toMap() {
    return {
      if (txId != null) 'txId': txId!,
      if (hash != null) 'hash': hash!,
      if (type != null) 'type': type!,
    };
  }

  factory PendingTransaction.fromMap(Map<String, dynamic> map) {
    return PendingTransaction(
      txId: map['txId']?.toString(),
      hash: map['hash']?.toString(),
      type: map['type']?.toString(),
    );
  }
}

class PathBucket {
  final String signingPath; // "a -> b -> c"
  final String signer; // last hop
  final String priorHop; // immediate predecessor (or self if single hop)
  final List<PendingTransaction> transactions;

  const PathBucket({
    required this.signingPath,
    required this.signer,
    required this.priorHop,
    required this.transactions,
  });
}

class FilteredPendingResponse {
  final int count;
  final List<PathBucket> bySigningPath;

  const FilteredPendingResponse({
    required this.count,
    required this.bySigningPath,
  });
}
