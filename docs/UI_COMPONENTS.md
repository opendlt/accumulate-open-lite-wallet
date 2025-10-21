# UI Components & Theming Guide

This guide covers the complete UI architecture, theming system, and component library for white-label customization of the Accumulate Open Lite Wallet.

## Table of Contents

- [UI Architecture](#ui-architecture)
- [Theming System](#theming-system)
- [Core UI Components](#core-ui-components)
- [Screen Layouts](#screen-layouts)
- [Custom Widgets](#custom-widgets)
- [White-Label Customization](#white-label-customization)
- [Responsive Design](#responsive-design)
- [Animation & Interactions](#animation--interactions)

## UI Architecture

### Design System Overview

The wallet follows **Material Design 3** principles with a clean, professional interface optimized for financial applications.

#### Key Design Principles
- **Security-First**: Clear visual hierarchy for critical actions
- **Professional**: Enterprise-grade appearance suitable for financial apps
- **Accessibility**: WCAG 2.1 compliant with keyboard navigation support
- **Responsive**: Adaptive layouts for phones, tablets, and foldables
- **Brand-Neutral**: Easy white-label customization

#### Component Hierarchy

```
AccumulateLiteWalletApp (MaterialApp)
└── WalletEntryPoint (StatefulWidget)
    ├── DeveloperAuthenticationPlaceholder (Onboarding)
    └── BasicWalletInterface (Main App)
        ├── Dashboard Screen
        ├── My Accounts Screen
        ├── Send Tokens Screen
        ├── Purchase Credits Screen
        ├── Write Data Screen
        ├── Transaction Signing Screen
        └── Settings Screen
```

### Screen Navigation

**Navigation Pattern**: Bottom Tab Navigation + Modal Screens

```dart
// Main navigation tabs
enum WalletTab {
  dashboard,      // Balance overview, charts, recent activity
  accounts,       // Account management (lite, ADI, token, data)
  transactions,   // Send tokens, purchase credits, write data
  signing,        // Multi-signature transaction management
  settings,       // Configuration, network, developer tools
}
```

## Theming System

### Theme Configuration

**Location**: `lib/shared/themes/app_theme.dart`

#### Light Theme (Default)

```dart
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      // Primary brand colors
      primarySwatch: Colors.blue,
      primaryColor: Colors.blue[600],

      // Background colors
      backgroundColor: Colors.grey[50],
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,

      // Text themes
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.black54,
        ),
      ),

      // Component themes
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),

      cardTheme: CardTheme(
        elevation: 2,
        margin: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue[600],
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Visual density
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
```

#### Dark Theme

```dart
static ThemeData get darkTheme {
  return ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    primaryColor: Colors.blue[400],

    backgroundColor: Colors.grey[900],
    scaffoldBackgroundColor: Colors.black,
    cardColor: Colors.grey[800],

    // Dark theme specific styling...
  );
}
```

### Color Palette

#### Primary Colors

```dart
class WalletColors {
  // Primary brand colors
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryVariant = Color(0xFF1565C0);
  static const Color secondary = Color(0xFF03DAC6);

  // Success/Error/Warning
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);

  // ACME token specific
  static const Color acmeGreen = Color(0xFF2E7D32);
  static const Color acmeGold = Color(0xFFFFB300);

  // Neutral grays
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFE0E0E0);
}
```

### Typography

#### Font Scale

```dart
class WalletTextStyles {
  // Display styles
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
  );

  // Title styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  // Specialized styles
  static const TextStyle balanceDisplay = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: WalletColors.acmeGreen,
  );

  static const TextStyle addressDisplay = TextStyle(
    fontSize: 12,
    fontFamily: 'Courier',
    letterSpacing: 0.5,
  );
}
```

## Core UI Components

### Dashboard Components

#### Account Balance Card

**Purpose**: Primary balance display with USD conversion

```dart
class AccountBalanceCard extends StatelessWidget {
  final double acmeBalance;
  final double usdValue;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Account Balance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (onRefresh != null)
                  IconButton(
                    onPressed: onRefresh,
                    icon: Icon(Icons.refresh),
                  ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              '${acmeBalance.toStringAsFixed(2)} ACME',
              style: WalletTextStyles.balanceDisplay,
            ),
            SizedBox(height: 8),
            Text(
              '≈ \$${usdValue.toStringAsFixed(2)} USD',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
```

#### Chart Widget

**Purpose**: Price visualization and portfolio distribution

**Location**: `lib/widgets/chart_widget.dart`

**Features**:
- Line chart for ACME price history
- Pie chart for portfolio distribution
- Toggle between chart types
- Real-time data integration

```dart
class ChartWidget extends StatefulWidget {
  const ChartWidget({Key? key}) : super(key: key);

  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

// Chart types
enum ChartType { line, pie }

// Usage
ChartWidget(
  chartType: ChartType.line,
  priceData: priceDataList,
  onChartTypeChanged: (type) => setState(() => chartType = type),
)
```

### Account Management Components

#### Account List Tile

**Purpose**: Consistent account display across screens

```dart
class AccountListTile extends StatelessWidget {
  final AccumulateAccount account;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showBalance;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getAccountTypeColor(account.accountType),
        child: Icon(_getAccountTypeIcon(account.accountType)),
      ),
      title: Text(
        account.name,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppConstants.formatLiteAccountAddress(account.address),
            style: WalletTextStyles.addressDisplay,
          ),
          if (showBalance && account.balance != null)
            Text(
              '${account.balance!.toStringAsFixed(2)} ACME',
              style: TextStyle(
                color: WalletColors.acmeGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
```

#### Account Type Badges

```dart
class AccountTypeBadge extends StatelessWidget {
  final String accountType;

  static const Map<String, Color> typeColors = {
    'lite_account': Colors.blue,
    'token_account': Colors.green,
    'data_account': Colors.orange,
    'identity': Colors.purple,
    'key_page': Colors.indigo,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: typeColors[accountType]?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: typeColors[accountType] ?? Colors.grey,
          width: 1,
        ),
      ),
      child: Text(
        accountType.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: typeColors[accountType],
        ),
      ),
    );
  }
}
```

### Transaction Components

#### Transaction Form Fields

```dart
class WalletFormField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
```

#### Amount Input Field

```dart
class AmountInputField extends StatelessWidget {
  final TextEditingController controller;
  final String tokenSymbol;
  final double? maxAmount;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return WalletFormField(
      label: 'Amount',
      hint: '0.00',
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tokenSymbol,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          if (maxAmount != null)
            TextButton(
              onPressed: () => controller.text = maxAmount!.toStringAsFixed(8),
              child: Text('MAX'),
            ),
        ],
      ),
      validator: validator ?? _defaultAmountValidator,
    );
  }
}
```

### QR Code Components

#### QR Code Display

```dart
class QRCodeDisplay extends StatelessWidget {
  final String data;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: QrImage(
        data: data,
        version: QrVersions.auto,
        size: size,
        foregroundColor: foregroundColor ?? Colors.black,
        backgroundColor: backgroundColor ?? Colors.white,
      ),
    );
  }
}
```

#### QR Code Scanner

```dart
class QRCodeScanner extends StatefulWidget {
  final Function(String) onScanned;
  final String? overlayText;

  @override
  State<QRCodeScanner> createState() => _QRCodeScannerState();
}

// Usage
QRCodeScanner(
  onScanned: (data) {
    // Handle scanned QR code
    Navigator.pop(context, data);
  },
  overlayText: 'Scan account address or transaction QR code',
)
```

### Multi-Signature Components

#### Signature Status Indicator

```dart
class SignatureStatusIndicator extends StatelessWidget {
  final int requiredSignatures;
  final int currentSignatures;
  final List<String> signers;

  @override
  Widget build(BuildContext context) {
    final isComplete = currentSignatures >= requiredSignatures;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isComplete ? WalletColors.success.withOpacity(0.1) : WalletColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isComplete ? WalletColors.success : WalletColors.warning,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.pending,
            color: isComplete ? WalletColors.success : WalletColors.warning,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signatures: $currentSignatures / $requiredSignatures',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                if (!isComplete)
                  Text(
                    'Waiting for ${requiredSignatures - currentSignatures} more signature(s)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## Screen Layouts

### Dashboard Screen Layout

```
┌─────────────────────────────────────┐
│ AppBar (Accumulate, Settings)       │
├─────────────────────────────────────┤
│ Account Balance Card                │
│ ┌─ Balance: 1,234.56 ACME         │
│ │  ≈ $308.64 USD                  │
│ │  [Refresh]                      │
│ └─────────────────────────────────  │
├─────────────────────────────────────┤
│ Chart Widget (Price/Portfolio)      │
│ ┌─ [Line] [Pie] Chart Toggle      │
│ │  Chart Visualization             │
│ │                                  │
│ └─────────────────────────────────  │
├─────────────────────────────────────┤
│ Quick Actions Row                   │
│ [Send] [Receive] [Credits] [More]   │
├─────────────────────────────────────┤
│ Recent Activity                     │
│ • Transaction 1                     │
│ • Transaction 2                     │
│ • Transaction 3                     │
└─────────────────────────────────────┘
```

### Transaction Form Layout

```
┌─────────────────────────────────────┐
│ AppBar (Back, Title)                │
├─────────────────────────────────────┤
│ Form Fields                         │
│ ┌─ From Account [Dropdown]         │
│ ├─ To Account [Input/QR]           │
│ ├─ Amount [Input] ACME             │
│ ├─ Memo [Input] (Optional)         │
│ └─ Credit Payer [Dropdown]         │
├─────────────────────────────────────┤
│ Transaction Summary                 │
│ • Amount: 100.00 ACME               │
│ • Fee: ~0.01 ACME                   │
│ • Total: 100.01 ACME                │
├─────────────────────────────────────┤
│ [Cancel] [Submit Transaction]       │
└─────────────────────────────────────┘
```

## Custom Widgets

### Navigation Components

#### Custom Navigation Bar

**Location**: `lib/shared/widgets/custom_nav_bar.dart`

```dart
class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavBarItem> items;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      items: items.map((item) => BottomNavigationBarItem(
        icon: Icon(item.icon),
        activeIcon: Icon(item.activeIcon ?? item.icon),
        label: item.label,
      )).toList(),
    );
  }
}

class NavBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const NavBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}
```

### Loading Components

#### Loading Overlay

```dart
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      if (message != null) ...[
                        SizedBox(height: 16),
                        Text(message!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
```

### Status Components

#### Connection Status Indicator

```dart
class ConnectionStatusIndicator extends StatelessWidget {
  final bool isConnected;
  final String? networkName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isConnected ? WalletColors.success.withOpacity(0.1) : WalletColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            size: 16,
            color: isConnected ? WalletColors.success : WalletColors.error,
          ),
          SizedBox(width: 4),
          Text(
            networkName ?? (isConnected ? 'Connected' : 'Offline'),
            style: TextStyle(
              fontSize: 12,
              color: isConnected ? WalletColors.success : WalletColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
```

## White-Label Customization

### Brand Customization

#### 1. Color Scheme

**Replace primary colors**:

```dart
// lib/shared/themes/app_theme.dart
class BrandColors {
  // Your brand colors
  static const Color primary = Color(0xFF YOUR_COLOR);
  static const Color secondary = Color(0xFF YOUR_COLOR);
  static const Color accent = Color(0xFF YOUR_COLOR);

  // Update WalletColors class
  static const Color acmeGreen = primary;  // Use your brand color
}
```

#### 2. Typography

**Custom font family**:

```dart
// pubspec.yaml
flutter:
  fonts:
    - family: YourBrandFont
      fonts:
        - asset: assets/fonts/YourBrandFont-Regular.ttf
        - asset: assets/fonts/YourBrandFont-Bold.ttf
          weight: 700

// Theme configuration
textTheme: TextTheme(
  fontFamily: 'YourBrandFont',
  // ... other styles
),
```

#### 3. Logo and Branding

**Replace app icon and splash**:

```yaml
# pubspec.yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/your_logo.png"

# Replace assets/logo.png with your brand logo
```

#### 4. App Name and Metadata

```yaml
# pubspec.yaml
name: your_wallet_name
description: "Your wallet description"

# Android: android/app/src/main/AndroidManifest.xml
<application android:label="Your Wallet Name">

# iOS: ios/Runner/Info.plist
<key>CFBundleName</key>
<string>Your Wallet Name</string>
```

### Feature Customization

#### Feature Flags

```dart
// lib/config/feature_flags.dart
class FeatureFlags {
  static const bool enableGovernance = true;
  static const bool enableMultiSignature = true;
  static const bool enableDataAccounts = true;
  static const bool enableDeveloperMode = false;  // Disable for production
  static const bool enableFaucet = true;          // Only for testnet/devnet
}
```

#### Custom Network Configuration

```dart
// lib/core/constants/app_constants.dart
class AppConstants {
  static const String defaultAccumulateDevnetUrl = 'https://your-endpoint.com/v2';
  static const String appName = 'Your Wallet Name';
  static const String supportEmail = 'support@yourcompany.com';
}
```

## Responsive Design

### Breakpoints

```dart
class ScreenBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }
}
```

### Adaptive Layouts

```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    if (ScreenBreakpoints.isMobile(context)) {
      return mobile;
    } else if (ScreenBreakpoints.isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return desktop ?? tablet ?? mobile;
    }
  }
}
```

## Animation & Interactions

### Transitions

```dart
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlidePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: Offset(1.0, 0.0), end: Offset.zero),
              ),
              child: child,
            );
          },
        );
}
```

### Loading Animations

```dart
class PulseAnimation extends StatefulWidget {
  final Widget child;

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Transform.scale(
        scale: _animation.value,
        child: widget.child,
      ),
    );
  }
}
```

---

This comprehensive UI guide provides everything needed to understand, customize, and extend the wallet's user interface. The modular component architecture makes it easy to white-label the application while maintaining professional quality and user experience standards.