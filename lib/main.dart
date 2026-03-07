import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/app.dart';
import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:flutter_starter_kit/config/environment.dart';
import 'package:flutter_starter_kit/features/notifications/services/fcm_service.dart';
import 'package:flutter_starter_kit/features/paywall/services/purchases_service.dart';
import 'package:flutter_starter_kit/shared/providers/shared_preferences_provider.dart';
import 'package:flutter_starter_kit/shared/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvironmentConfig.init();
  await FirebaseService.initialize();

  // Pre-initialize SharedPreferences for synchronous access (no theme flash)
  final prefs = await SharedPreferences.getInstance();

  if (AppConfig.enablePaywall) {
    await PurchasesService.initialize();
  }

  if (AppConfig.enableNotifications) {
    await FcmService().initialize();
  }

  // ProviderScope cannot be const — has overrides for SharedPreferences
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const App(),
  ));
}
