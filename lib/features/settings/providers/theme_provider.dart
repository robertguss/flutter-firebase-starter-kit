import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_starter_kit/shared/providers/shared_preferences_provider.dart';

part 'theme_provider.g.dart';

@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.get(_key);

    if (raw is String) return _fromString(raw);

    // Migrate from legacy boolean format
    if (raw is bool) {
      final migrated = raw ? 'dark' : 'light';
      prefs.remove(_key);
      prefs.setString(_key, migrated);
      return raw ? ThemeMode.dark : ThemeMode.light;
    }

    // Default for new installs
    return ThemeMode.system;
  }

  void setMode(ThemeMode mode) {
    state = mode;
    _saveToPrefs(mode);
  }

  Future<void> _saveToPrefs(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, _toString(mode));
  }

  static ThemeMode _fromString(String value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static String _toString(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }
}
