// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:news_reader/core/bottom_navigation_bar/widgets/app_bottom_navigation_bar.dart';
import 'package:news_reader/core/storage/secure_storage_service.dart';
import 'package:news_reader/core/theme/app_theme.dart';
import 'package:news_reader/features/login/view/login_screen.dart';

void main() {
  test('bottom sheet surfaces follow the active theme', () {
    final lightTheme = AppTheme.lightTheme;
    final darkTheme = AppTheme.darkTheme;

    expect(
      lightTheme.bottomSheetTheme.modalBackgroundColor,
      lightTheme.colorScheme.surface,
    );
    expect(
      darkTheme.bottomSheetTheme.modalBackgroundColor,
      darkTheme.colorScheme.surface,
    );
  });

  testWidgets('login screen renders the required content', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Newsly'), findsWidgets);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(
      find.text('Sign in to continue reading the latest news.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'bottom navigation stays at the bottom without covering content',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(child: Text('Home content')),
            bottomNavigationBar: AppBottomNavigationBar(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );

      final barRect = tester.getRect(find.byType(AppBottomNavigationBar));
      expect(find.text('Home content'), findsOneWidget);
      expect(barRect.height, lessThan(100));
      expect(barRect.bottom, closeTo(600, 1));
    },
  );

  test('login session persists and is cleared on logout', () async {
    final directory = await Directory.systemTemp.createTemp('news-reader-hive');
    Hive.init(directory.path);
    await Hive.openBox('auth_box');

    try {
      final storage = SecureStorageService();
      await storage.setLoggedIn(true);
      expect(await SecureStorageService.isLoggedIn(), isTrue);

      await Hive.box('auth_box').close();
      await Hive.openBox('auth_box');
      expect(await SecureStorageService.isLoggedIn(), isTrue);

      await storage.clearAuthSession();
      expect(await SecureStorageService.isLoggedIn(), isFalse);
    } finally {
      await Hive.close();
      await directory.delete(recursive: true);
    }
  });
}
