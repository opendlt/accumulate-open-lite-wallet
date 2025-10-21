# Developer Quick Start Guide

Welcome to the **Accumulate Open Lite Wallet**! This guide will get you up and running in under 30 minutes with a fully functional Accumulate blockchain wallet.

## What You're Getting

This isn't a prototype or demo—it's a **production-ready mobile wallet** that includes:

**Complete UI**: Dashboard, transactions, multi-sig, settings
**Full Blockchain Integration**: Send tokens, create accounts, manage identities
**Advanced Features**: QR codes, charts, multi-signature support, governance
**Security**: Ed25519 cryptography, secure key storage, encrypted database
**Developer Tools**: Network switching, developer bypass, comprehensive logging

## Prerequisites

Before you start, ensure you have:

- **Flutter 3.3.1+** - [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Dart SDK** (included with Flutter)
- **Git** - For cloning repositories
- **Docker** - For running local DevNet
- **Android Studio/VS Code** - For development
- **Android device/emulator** - For testing

### Platform-Specific Requirements

**Android Development**:
- Android SDK 21+ (Android 5.0)
- Android Studio or VS Code with Flutter extension

**iOS Development** (optional):
- Xcode 14+
- iOS 12+ target
- Apple Developer account (for device testing)

## Step 1: Environment Setup

### 1.1 Clone the Repository

```bash
git clone https://github.com/opendlt/accumulate-open-lite-wallet.git
cd accumulate-open-lite-wallet
```

### 1.2 Install Dependencies

```bash
flutter pub get
```

### 1.3 Verify Flutter Setup

```bash
flutter doctor
```

Ensure no critical issues are reported. Fix any Android/iOS setup issues before proceeding.

## Step 2: DevNet Setup (Required)

The wallet is pre-configured to work with a local Accumulate DevNet. This provides a complete blockchain environment for development and testing.

### 2.1 Clone DevNet Distribution

```bash
cd ..  # Navigate to parent directory
git clone https://github.com/opendlt/accumulate-devnet-distribution.git
cd accumulate-devnet-distribution
```

### 2.2 Start DevNet

Follow the instructions in the DevNet repository to start the local blockchain:

```bash
# Example commands (refer to DevNet repository for exact instructions)
docker-compose up -d
```

### 2.3 Verify DevNet is Running

```bash
# Test API accessibility
curl http://localhost:26660/v2

# Expected response: JSON with API information
```

**Important**: The DevNet must be running on `localhost:26660` for the wallet to function properly.

## Step 3: Run the Wallet

### 3.1 Navigate Back to Wallet Directory

```bash
cd ../accumulate-open-lite-wallet
```

### 3.2 Launch the Application

```bash
flutter run
```

**For Android Emulator**: The app will automatically connect to DevNet via `10.0.2.2:26660`
**For Physical Device**: You may need to adjust network configuration (see troubleshooting)

### 3.3 First Launch Experience

On first launch, you'll see:
1. **Welcome Screen**: Introduction to the wallet
2. **Developer Mode**: Tap the Accumulate logo 5 times to enable developer features
3. **Dashboard**: Main wallet interface with sample accounts

## Step 4: Explore Key Features

### 4.1 Dashboard Overview

- **Account Balance**: Real-time ACME balance with USD conversion
- **Price Chart**: ACME price visualization (demo data initially)
- **Quick Actions**: Send, receive, create accounts

### 4.2 Account Management

**Create Lite Account**:
1. Navigate to "My Accounts" → "Lite Accounts"
2. Tap "Create New Lite Account"
3. Follow the guided process

**Create ADI Identity**:
1. Go to "My Accounts" → "ADI Identities"
2. Tap "Create New Identity"
3. Configure identity and key structure

### 4.3 Transactions

**Send Tokens**:
1. Dashboard → "Send Tokens"
2. Select sender account
3. Enter recipient and amount
4. Sign and submit transaction

**Multi-Signature Workflow**:
1. Dashboard → "Transaction Signing"
2. View pending signatures
3. Sign transactions with appropriate key pages

### 4.4 Developer Features

**Enable Developer Mode**:
- Tap the Accumulate logo 5 times on any screen
- Access developer tools via settings menu

**Developer Tools**:
- Network endpoint configuration
- Transaction debugging
- Key management utilities
- Database inspection

## Step 5: Development Workflow

### 5.1 Project Structure

```
accumulate-open-lite-wallet/
├── lib/
│   ├── core/                 # Business logic (Flutter-independent)
│   │   ├── services/        # Blockchain and wallet services
│   │   ├── models/          # Data models
│   │   └── constants/       # Configuration
│   ├── shared/              # Reusable UI components
│   ├── widgets/             # Custom widgets
│   └── main.dart           # Application entry point
├── docs/                    # Comprehensive documentation
├── assets/                  # Images and resources
└── test/                   # Test suite
```

### 5.2 Making Your First Modification

**Example: Customize App Theme**

1. **Open theme file**:
   ```bash
   # Edit lib/shared/themes/app_theme.dart
   ```

2. **Modify colors**:
   ```dart
   class AppTheme {
     static final ThemeData lightTheme = ThemeData(
       primarySwatch: Colors.blue,  // Change to your brand color
       // ... other theme properties
     );
   }
   ```

3. **Hot reload to see changes**:
   ```bash
   # In your IDE or terminal with flutter run active
   r  # Hot reload
   R  # Hot restart
   ```

### 5.3 Adding Custom Features

**Example: Add Custom Transaction Type**

1. **Create service** in `lib/core/services/`
2. **Register in ServiceLocator** (`lib/core/services/service_locator.dart`)
3. **Add UI components** in appropriate directories
4. **Update models** if needed

## Step 6: Testing & Validation

### 6.1 Run Test Suite

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Test coverage
flutter test --coverage
```

### 6.2 Validate Core Functionality

**DevNet Integration**:
- [ ] Create lite account successfully
- [ ] Send test tokens between accounts
- [ ] Create ADI identity
- [ ] Perform multi-signature transaction

**UI/UX Validation**:
- [ ] Navigate through all screens
- [ ] Verify responsive design
- [ ] Test QR code scanning/generation
- [ ] Validate theme consistency

### 6.3 Performance Testing

```bash
# Profile app performance
flutter run --profile

# Analyze bundle size
flutter build apk --analyze-size
```

## Step 7: Customization & White-Labeling

### 7.1 Branding Customization

**App Name & Icon**:
1. Update `pubspec.yaml` → `name` field
2. Replace icons in `assets/` directory
3. Configure `flutter_launcher_icons` in `pubspec.yaml`

**Color Scheme**:
1. Modify `lib/shared/themes/app_theme.dart`
2. Update primary, secondary, and accent colors
3. Customize Material Design 3 color tokens

### 7.2 Feature Configuration

**Enable/Disable Features**:
```dart
// lib/config/feature_flags.dart
class FeatureFlags {
  static const bool enableGovernance = true;  // Disable if not needed
  static const bool enableMultiSig = true;
  static const bool enableDataAccounts = true;
}
```

**Network Configuration**:
```dart
// lib/core/constants/app_constants.dart
class AppConstants {
  static const String defaultAccumulateDevnetUrl = 'http://your-endpoint:26660/v2';
  // Configure for your deployment environment
}
```

## Step 8: Production Deployment

### 8.1 Build Configuration

**Android Release Build**:
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

**iOS Release Build**:
```bash
flutter build ios --release
```

### 8.2 Production Checklist

- [ ] **Network Configuration**: Update endpoints for production
- [ ] **API Keys**: Configure production API credentials
- [ ] **Code Signing**: Set up platform-specific certificates
- [ ] **Security Review**: Audit cryptographic implementations
- [ ] **Performance Testing**: Load test with realistic data
- [ ] **App Store Assets**: Prepare screenshots and metadata

### 8.3 Deployment Considerations

**Security**:
- Enable certificate pinning for production APIs
- Implement proper key rotation policies
- Set up monitoring and alerting

**Performance**:
- Configure appropriate cache policies
- Implement background sync strategies
- Optimize for low-end devices

## Troubleshooting

### Common Issues

**DevNet Connection Failed**:
```bash
# Check DevNet is running
curl http://localhost:26660/v2

# For physical devices, use your computer's IP instead of localhost
# Update lib/core/constants/app_constants.dart accordingly
```

**Flutter Dependencies**:
```bash
# Clean and reinstall
flutter clean
flutter pub get

# Clear pub cache if needed
flutter pub cache repair
```

**Build Errors**:
```bash
# Update Flutter
flutter upgrade

# Regenerate files
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Getting Help

- **Documentation**: Check `/docs` directory for detailed guides
- **Issues**: Report bugs on GitHub repository
- **Community**: Join Accumulate developer forums
- **Architecture**: Review `docs/ARCHITECTURE.md` for deep understanding

## Next Steps

### Immediate Actions
1. **Explore the codebase**: Understand the service architecture
2. **Review documentation**: Read through `/docs` directory
3. **Customize branding**: Make it your own
4. **Add features**: Extend functionality as needed

### Advanced Topics
- **Custom Authentication**: Integrate your user management system
- **Cloud Integration**: Add backup and sync capabilities
- **Advanced Security**: Implement hardware security modules
- **Enterprise Features**: Multi-user and role-based access

### Additional Resources
- [Architecture Guide](ARCHITECTURE.md) - Deep dive into system design
- [API Reference](API_REFERENCE.md) - Complete service documentation
- [UI Components](UI_COMPONENTS.md) - Widget library reference
- [Security Guide](SECURITY.md) - Cryptographic implementation details

---

**Congratulations!** You now have a fully functional Accumulate wallet. The foundation is solid—build something amazing on top of it!