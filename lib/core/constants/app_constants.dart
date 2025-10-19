// Core application constants - no Flutter dependencies

class AppConstants {
  // Network URLs
  static const String defaultAccumulateTestnetUrl =
      'https://testnet.accumulatenetwork.io/v3';
  static const String defaultMainnetUrl =
      'https://mainnet.accumulatenetwork.io/v3';

  // Explorer URLs
  static const String testnetExplorerBaseUrl =
      'https://explorer.testnet.accumulatenetwork.io';
  static const String mainnetExplorerBaseUrl =
      'https://explorer.accumulatenetwork.io';

  // Polling intervals
  static const Duration defaultPendingTxPollingInterval = Duration(seconds: 45);
  static const Duration badgeRefreshInterval = Duration(minutes: 30);

  // Token types
  static const String acmeTokenType = 'ACME';

  // Account types
  static const String defaultBookPath = '/book/1';

  // Storage keys
  static const String userIdKey = 'userId';
  static const String addTxMemosKey = 'add_tx_memos';
}

class NetworkType {
  static const String testnet = 'testnet';
  static const String mainnet = 'mainnet';
}

class TransactionTypes {
  static const String createDataAccount = 'createDataAccount';
  static const String writeData = 'writeData';
  static const String createTokenAccount = 'createTokenAccount';
  static const String sendTokens = 'sendTokens';
  static const String createKeyPage = 'createKeyPage';
  static const String createKeyBook = 'createKeyBook';
  static const String addCredits = 'addCredits';
  static const String updateKey = 'updateKey';
}
