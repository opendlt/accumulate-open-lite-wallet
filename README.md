# Accumulate Lite Wallet - Open Source Core

A stripped-down, open-source foundation for building Accumulate blockchain wallets. This project provides the essential UI components, business logic, and blockchain integration needed to create a functional Accumulate wallet.

## What's Included

### Core Wallet Features
- **Dashboard UI** - Balance display, transaction history, charts
- **Transaction Management** - Send/receive tokens, staking interfaces
- **Multi-Signature Support** - Complete signing workflow and delegation
- **Voting Interface** - Governance participation tools
- **QR Code Integration** - Address scanning and generation
- **Accumulate API** - Full blockchain integration
- **Cryptographic Utilities** - Key management and signing
- **Local Data Persistence** - SQLite database for transaction history and accounts
- **Secure Storage** - Flutter Secure Storage for sensitive data

### Clean Architecture
- **Pure Dart Business Logic** - No Flutter dependencies in core
- **Provider State Management** - Reactive UI updates
- **Service Locator Pattern** - Dependency injection
- **Modular Feature Structure** - Easy to extend and maintain

## What's NOT Included (You Need to Implement)

- **User Authentication** - No login/registration system
- **Background Services** - No automatic polling or sync
- **Push Notifications** - No FCM or notification system
- **User Onboarding** - No account creation flow

## Quick Start

### Prerequisites
- Flutter 3.3.1 or higher
- Dart SDK
- Git
- Docker (for DevNet setup)

### Installation

```bash
git clone <your-repo-url>
cd accumulate-lite-wallet-OS
flutter pub get
flutter run
```

## DevNet Setup (Required for Development)

This wallet is configured to work with Accumulate DevNet running on `localhost:26660`. For development and testing, you'll need to set up a local DevNet instance.

### Using Accumulate DevNet Distribution

1. **Clone the DevNet distribution:**
   ```bash
   git clone https://github.com/opendlt/accumulate-devnet-distribution.git
   cd accumulate-devnet-distribution
   ```

2. **Start the DevNet:**
   ```bash
   # Follow the instructions in the repository to start DevNet
   # This will start Accumulate nodes on localhost:26660
   ```

3. **Verify DevNet is running:**
   ```bash
   # Test that the API is accessible
   curl http://localhost:26660/v2
   ```

4. **Run the wallet:**
   ```bash
   # In your wallet project directory
   flutter run
   ```

### Network Configuration

The wallet is pre-configured for DevNet with:
- **API Endpoint**: `http://10.0.2.2:26660/v2` (Android emulator endpoint)
- **Network Type**: DevNet
- **Faucet**: Built-in faucet integration for test tokens

For production deployment, update `lib/core/constants/app_constants.dart` with appropriate network endpoints.

The app will launch with a placeholder authentication screen showing what needs to be implemented.

## Project Structure

```
lib/
├── core/                   # Pure business logic (ready to use)
│   ├── models/            # Data models
│   ├── services/          # Blockchain services
│   ├── adapters/          # Platform adapters
│   └── utils/             # Utilities
├── shared/                # Reusable UI components (ready to use)
│   ├── themes/            # App styling
│   ├── widgets/           # Custom widgets
│   └── extensions/        # Helper extensions
├── features/              # Main wallet features (ready to use)
│   ├── dashboard/         # Home screen and balances
│   ├── transactions/      # Send/receive/stake
│   ├── signing/           # Multi-sig workflows
│   └── voting/            # Governance features
├── services/              # Essential services (ready to use)
├── config/                # App configuration
└── main.dart              # App entry point
```

## Implementation Guide

### 1. Authentication (Required)
Implement user authentication and identity management:

```dart
// You need to implement:
- User registration/login
- Mnemonic phrase generation
- Key derivation and storage
- Identity creation on Accumulate
```

**See: [docs/AUTHENTICATION.md](docs/AUTHENTICATION.md)**

### 2. Extend Data Storage (Optional)
The wallet includes SQLite database and secure storage. You can extend with:

```dart
// Additional options:
- Cloud backup integration
- Remote database sync
- Additional data models
- Custom encryption layers
```

**See: [docs/PERSISTENCE.md](docs/PERSISTENCE.md) for extension patterns**

### 3. Configuration (Required)
Set up your environment and endpoints:

```dart
// Configure in lib/config/app_config.dart:
- Network endpoints (mainnet/testnet)
- API keys and settings
- Feature flags
```

**See: [docs/CONFIGURATION.md](docs/CONFIGURATION.md)**

### 4. Optional Enhancements
Extend with additional features:

```dart
// Consider adding:
- Background sync
- Push notifications
- Cloud backup
- Multi-device support
```

**See: [docs/SERVICES.md](docs/SERVICES.md)**

## Architecture Overview

This wallet uses a clean architecture pattern:

1. **Core Layer** - Pure Dart business logic
2. **Feature Layer** - UI components organized by feature
3. **Shared Layer** - Reusable components and utilities

### Key Services

- `AccumulateApiService` - Blockchain API integration
- `EnhancedAccumulateService` - Advanced blockchain operations
- `DatabaseHelper` - SQLite database management
- `SecureKeysService` - Secure storage for sensitive data
- `WalletStorageService` - Account and wallet persistence
- `TransactionSigningService` - Transaction signing and submission
- `ServiceLocator` - Dependency injection management

### State Management

Uses Provider pattern for reactive state:
- `DashboardProvider` - Account balances and data
- `TransactionsProvider` - Transaction management
- `PendingTxProvider` - Pending transaction tracking

## Customization

### Theming
Modify `lib/shared/themes/app_theme.dart` to customize appearance.

### Network Configuration
Update `lib/config/app_config.dart` for different networks or endpoints.

### Feature Flags
Use `lib/config/feature_flags.dart` to enable/disable features.

## Documentation

- [Authentication Guide](docs/AUTHENTICATION.md) - Implement user auth
- [Persistence Guide](docs/PERSISTENCE.md) - Add data storage
- [Configuration Guide](docs/CONFIGURATION.md) - Environment setup
- [Services Guide](docs/SERVICES.md) - Extend functionality

## Contributing

This is an open-source foundation. Feel free to:
- Add missing implementations
- Improve existing code
- Submit bug fixes
- Enhance documentation

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### MIT License Summary

- ✅ **Commercial use** - Use this code in commercial projects
- ✅ **Modification** - Modify the code to fit your needs
- ✅ **Distribution** - Distribute the code and your modifications
- ✅ **Private use** - Use the code for private purposes
- ❌ **Warranty** - No warranty provided
- ❌ **Liability** - Authors not liable for any damages

**Attribution Required**: Include the original license notice in any substantial portions of the code.

## Resources

- [Accumulate Protocol](https://accumulate.io)
- [Accumulate API Documentation](https://docs.accumulate.io)
- [Accumulate DevNet Distribution](https://github.com/opendlt/accumulate-devnet-distribution) - Required for development
- [Flutter Documentation](https://flutter.dev/docs)

---

**Ready to build your Accumulate wallet? Start with the [Authentication Guide](docs/AUTHENTICATION.md)!**