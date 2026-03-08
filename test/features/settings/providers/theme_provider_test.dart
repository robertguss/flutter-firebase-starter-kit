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

    test('defaults to system mode when no preference saved', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

      final themeMode = container.read(themeModeProvider);
      expect(themeMode, ThemeMode.system);
    });

    test('loads dark mode from string preference', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

      final themeMode = container.read(themeModeProvider);
      expect(themeMode, ThemeMode.dark);
    });

    test('loads light mode from string preference', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

      final themeMode = container.read(themeModeProvider);
      expect(themeMode, ThemeMode.light);
    });

    test('migrates legacy boolean true to dark', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': true});
      final prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

      final themeMode = container.read(themeModeProvider);
      expect(themeMode, ThemeMode.dark);
      // Verify migration wrote string format
      expect(prefs.getString('theme_mode'), 'dark');
    });

    test('migrates legacy boolean false to light', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': false});
      final prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

      final themeMode = container.read(themeModeProvider);
      expect(themeMode, ThemeMode.light);
      expect(prefs.getString('theme_mode'), 'light');
    });

    test('setMode changes to dark', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

      container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('setMode changes to system', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

      container.read(themeModeProvider.notifier).setMode(ThemeMode.system);
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('persists preference as string to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

      container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
      expect(prefs.getString('theme_mode'), 'dark');
    });
  });
}
