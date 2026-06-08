// Basic smoke test: the app builds and renders without throwing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bjs_food_runs/main.dart';
import 'package:bjs_food_runs/app_state.dart';
import 'package:bjs_food_runs/storage.dart';

void main() {
  testWidgets('Food Runs App loads correctly', (WidgetTester tester) async {
    // Provide an in-memory SharedPreferences so Storage works under test.
    SharedPreferences.setMockInitialValues({});
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

    // Verify that the app loads without errors.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
