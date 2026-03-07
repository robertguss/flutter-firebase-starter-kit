import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/shared/providers/shared_preferences_provider.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final isDark = prefs.getBool(_key) ?? false;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void toggle() {
    final isDark = state == ThemeMode.light;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    _saveToPrefs(isDark);
  }

  Future<void> _saveToPrefs(bool isDark) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_key, isDark);
  }
}
