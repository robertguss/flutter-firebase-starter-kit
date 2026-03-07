import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Must be overridden in ProviderScope with a pre-initialized instance.
// This ensures synchronous access throughout the app (no async race conditions).
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});
