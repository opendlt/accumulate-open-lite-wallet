# Shared Components - Ready to Use ✅

This directory contains reusable UI components, themes, and utilities that are used throughout the wallet application. **All components are ready to use without modification.**

## What's Included ✅

### Themes (`themes/`)
- `app_theme.dart` - Complete light theme with Accumulate branding
- Professional color scheme and typography
- Consistent styling for all UI components

### Widgets (`widgets/`)
- `custom_nav_bar.dart` - Bottom navigation bar component
- `custom_menu_button_widget.dart` - Styled menu buttons
- `app_icon_badge_bridge.dart` - Icon with badge functionality
- `widgets.dart` - Widget exports

### Extensions (`extensions/`)
- `string_extensions.dart` - Useful string manipulation helpers
- Additional utility extensions

## Usage Examples

### Using App Theme
```dart
MaterialApp(
  theme: AppTheme.lightTheme,
  // Your app content
)
```

### Using Custom Widgets
```dart
import 'package:accumulate_lite_wallet/shared/widgets/widgets.dart';

CustomNavBar(
  items: ['Home', 'Transactions', 'Settings'],
  onItemSelected: (index) => _handleNavigation(index),
)
```

### Using Extensions
```dart
import 'package:accumulate_lite_wallet/shared/extensions/string_extensions.dart';

final formatted = "acc://user.acme/tokens".toDisplayUrl();
final truncated = "very_long_address_here".truncateMiddle(20);
```

## Customization

### Modifying Theme
```dart
// lib/shared/themes/app_theme.dart
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    primarySwatch: Colors.blue, // Change primary color
    // Modify other theme properties
  );
}
```

### Custom Widgets
All widgets follow Flutter conventions and can be easily customized:
- Extend existing widgets for additional functionality
- Override styling through theme or direct properties
- Add new widgets following the same patterns

## Benefits

1. **Consistent Design** - Uniform appearance across the app
2. **Reusability** - DRY principle for UI components
3. **Maintainability** - Central location for styling changes
4. **Professional Look** - Accumulate-branded design

## Extension Points

You may want to add:

1. **Dark Theme** - `AppTheme.darkTheme` for dark mode support
2. **Additional Widgets** - App-specific reusable components
3. **Animation Utilities** - Common animation helpers
4. **Responsive Helpers** - Screen size and orientation utilities

## Developer Notes

- All widgets are stateless where possible for better performance
- Theme follows Material Design 3 guidelines
- Colors and typography are consistent with Accumulate branding
- Widgets are designed to be composable and flexible

No implementation required - use these components directly in your UI.