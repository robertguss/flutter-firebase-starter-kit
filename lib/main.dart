import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/app.dart';
import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:flutter_starter_kit/config/environment.dart';
import 'package:flutter_starter_kit/features/notifications/providers/notification_provider.dart';
import 'package:flutter_starter_kit/features/notifications/services/fcm_service.dart';
import 'package:flutter_starter_kit/features/onboarding/providers/onboarding_provider.dart';
import 'package:flutter_starter_kit/features/paywall/providers/purchases_provider.dart';
import 'package:flutter_starter_kit/features/paywall/services/purchases_service.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/shared/providers/feature_hooks.dart';
import 'package:flutter_starter_kit/shared/providers/premium_provider.dart';
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

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

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

  // Build feature hook lists based on enabled features.
  // main.dart is the composition root: it imports features to wire up
  // lifecycle hooks. shared/ never imports from features.
  final bootstrapHooks = <FeatureHook>[];
  final signOutHooks = <FeatureHook>[];
  final deleteAccountHooks = <FeatureHook>[];

  if (AppConfig.enablePaywall) {
    bootstrapHooks.add((ref, uid) async {
      await ref.read(purchasesServiceProvider).login(uid);
    });
    signOutHooks.add((ref, uid) async {
      await ref.read(purchasesServiceProvider).logout();
      ref.invalidate(customerInfoProvider);
      ref.invalidate(offeringsProvider);
    });
    deleteAccountHooks.add((ref, uid) async {
      await ref.read(purchasesServiceProvider).logout();
      ref.invalidate(customerInfoProvider);
    });
  }

  if (AppConfig.enableNotifications) {
    bootstrapHooks.add((ref, uid) async {
      final token = await ref.read(fcmServiceProvider).getToken();
      if (token != null) {
        await ref.read(userProfileServiceProvider).updateFcmToken(uid, token);
      }
    });
  }

  // Onboarding state cleanup on sign-out
  signOutHooks.add((ref, uid) async {
    ref.invalidate(onboardingProvider);
  });

  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      bootstrapHooksProvider.overrideWithValue(bootstrapHooks),
      signOutHooksProvider.overrideWithValue(signOutHooks),
      deleteAccountHooksProvider.overrideWithValue(deleteAccountHooks),
      if (AppConfig.enablePaywall) ...[
        isPremiumProvider.overrideWith((ref) {
          final customerInfo = ref.watch(customerInfoProvider);
          return customerInfo.whenOrNull(
                data: (info) =>
                    info.entitlements.active.containsKey('premium'),
              ) ??
              false;
        }),
        restorePurchasesActionProvider.overrideWith((ref) {
          return () async {
            final service = ref.read(purchasesServiceProvider);
            final info = await service.restorePurchases();
            ref.invalidate(customerInfoProvider);
            final restored =
                info.entitlements.active.containsKey('premium');
            return restored ? 'Purchases restored!' : 'No purchases found';
          };
        }),
      ],
    ],
    child: const App(),
  ));
}
