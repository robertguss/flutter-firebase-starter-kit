import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/shared/providers/feature_hooks.dart';

/// Orchestrates all post-sign-in side effects in a defined order.
/// Watched by the App widget to show loading state during bootstrap.
final postAuthBootstrapProvider = FutureProvider<void>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return;

  final profileService = ref.read(userProfileServiceProvider);

  // 1. Create profile if it doesn't exist, update mutable fields only.
  //    Uses set-with-merge so createdAt is only written on first creation.
  final existingProfile = await profileService.getProfile(user.uid);
  if (existingProfile == null) {
    await profileService.createOrUpdateProfile(user.uid, {
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'onboardingComplete': false,
    });
  } else {
    await profileService.createOrUpdateProfile(user.uid, {
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
    });
  }

  // 2. Run feature-specific bootstrap hooks (RevenueCat login, FCM token, etc.)
  for (final hook in ref.read(bootstrapHooksProvider)) {
    await hook(ref, user.uid);
  }

  // 3. Set Crashlytics user identifier for crash report correlation
  if (AppConfig.enableCrashlytics && Firebase.apps.isNotEmpty) {
    await FirebaseCrashlytics.instance.setUserIdentifier(user.uid);
  }

  // 4. Set Analytics user properties for segmentation
  if (AppConfig.enableAnalytics && Firebase.apps.isNotEmpty) {
    FirebaseAnalytics.instance.setUserProperty(
      name: 'auth_provider',
      value: user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : 'unknown',
    );
  }
});
