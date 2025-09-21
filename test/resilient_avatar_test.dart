import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:food_runs_counter/widgets/resilient_avatar.dart';

void main() {
  group('ResilientAvatar Tests', () {
    testWidgets('ResilientAvatar falls back to default asset for null path', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResilientAvatar(avatarPath: null),
          ),
        ),
      );

      // Should render without throwing an exception
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byType(ResilientAvatar), findsOneWidget);
    });

    testWidgets('ResilientAvatar falls back to default asset for empty path', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResilientAvatar(avatarPath: ''),
          ),
        ),
      );

      // Should render without throwing an exception
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byType(ResilientAvatar), findsOneWidget);
    });

    testWidgets('ResilientAvatar falls back to default asset for invalid path', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResilientAvatar(avatarPath: '/nonexistent/path/to/avatar.png'),
          ),
        ),
      );

      // Should render without throwing an exception
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byType(ResilientAvatar), findsOneWidget);
    });

    test('getResilientImageProvider handles null paths', () {
      final provider = getResilientImageProvider(null, isAvatar: true);
      expect(provider, isA<AssetImage>());
      expect((provider as AssetImage).assetName, 'assets/avatars/image001.png');
    });

    test('getResilientImageProvider handles empty paths', () {
      final provider = getResilientImageProvider('', isAvatar: true);
      expect(provider, isA<AssetImage>());
      expect((provider as AssetImage).assetName, 'assets/avatars/image001.png');
    });

    test('getResilientImageProvider handles invalid paths', () {
      final provider = getResilientImageProvider('/invalid/path.png', isAvatar: true);
      expect(provider, isA<AssetImage>());
      expect((provider as AssetImage).assetName, 'assets/avatars/image001.png');
    });

    test('getResilientImageProvider returns correct fallback for non-avatar images', () {
      final provider = getResilientImageProvider(null, isAvatar: false);
      expect(provider, isA<AssetImage>());
      expect((provider as AssetImage).assetName, 'assets/runner.png');
    });
  });
}