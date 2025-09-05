// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../lib/main.dart';
import '../lib/app_state.dart';
import '../lib/storage.dart';

void main() {
  testWidgets('Food Runs App loads correctly', (WidgetTester tester) async {
    // Initialize storage for testing
    await Storage.init();
    final appState = AppState();
    await appState.load();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const FoodRunsApp(),
      ),
    );

    // Verify that the app loads without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
