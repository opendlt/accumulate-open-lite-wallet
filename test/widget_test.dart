// Basic widget test for Accumulate Lite Wallet

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:accumulate_lite_wallet/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AccumulateLiteWalletApp());

    // Verify that the welcome screen is displayed
    expect(find.text('Welcome to Accumulate Lite Wallet'), findsOneWidget);
    expect(find.text('This is the open-source core wallet.'), findsOneWidget);

    // Verify that developer instructions are shown
    expect(find.text('DEVELOPER TODO:'), findsOneWidget);
    expect(find.text('• Implement user authentication'), findsOneWidget);
  });

  testWidgets('Loading state test', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const AccumulateLiteWalletApp());

    // Initially should show loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading wallet...'), findsOneWidget);

    // Wait for the loading to complete
    await tester.pumpAndSettle();

    // Should now show the welcome screen
    expect(find.text('Welcome to Accumulate Lite Wallet'), findsOneWidget);
  });
}
