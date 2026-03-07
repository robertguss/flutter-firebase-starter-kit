import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
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

  // Initialize Firebase first (required by Crashlytics)
  await FirebaseService.initialize();

  // Set up Crashlytics error handlers AFTER Firebase init, BEFORE runApp
  if (AppConfig.enableCrashlytics) {
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);

    // Catch Flutter framework errors
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    // Catch async/platform errors not handled by Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Pre-initialize SharedPreferences for synchronous access (no theme flash)
  final prefs = await SharedPreferences.getInstance();

  // Parallelize remaining initialization for faster startup
  await Future.wait([
    if (AppConfig.enablePaywall) PurchasesService().initialize(),
    if (AppConfig.enableNotifications) FcmService().initialize(),
  ]);

  // ProviderScope cannot be const — has overrides for SharedPreferences
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const App(),
  ));
}
