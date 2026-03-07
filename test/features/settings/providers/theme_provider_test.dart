import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/settings/providers/theme_provider.dart';
import 'package:flutter_starter_kit/shared/providers/shared_preferences_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeModeNotifier', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    test('defaults to light mode when no preference saved', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

      final themeMode = container.read(themeModeProvider);
      expect(themeMode, ThemeMode.light);
    });

    test('loads dark mode synchronously when saved', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': true});
      final prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

      // Must be dark immediately — no async race condition
      final themeMode = container.read(themeModeProvider);
      expect(themeMode, ThemeMode.dark);
    });

    test('toggles to dark mode', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

      container.read(themeModeProvider.notifier).toggle();
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('toggles back to light mode', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

      final notifier = container.read(themeModeProvider.notifier);
      notifier.toggle();
      notifier.toggle();
      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    test('persists preference to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

      container.read(themeModeProvider.notifier).toggle();

      // Verify persisted
      expect(prefs.getBool('theme_mode'), true);
    });
  });
}
