import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_starter_kit/features/settings/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeModeNotifier', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('defaults to light mode', () {
      final themeMode = container.read(themeModeProvider);
      expect(themeMode, ThemeMode.light);
    });

    test('toggles to dark mode', () async {
      container.read(themeModeProvider.notifier).toggle();
      final themeMode = container.read(themeModeProvider);
      expect(themeMode, ThemeMode.dark);
    });

    test('toggles back to light mode', () async {
      final notifier = container.read(themeModeProvider.notifier);
      notifier.toggle();
      notifier.toggle();
      final themeMode = container.read(themeModeProvider);
      expect(themeMode, ThemeMode.light);
    });
  });
}
