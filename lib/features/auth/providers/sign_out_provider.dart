import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/shared/providers/feature_hooks.dart';
import 'package:flutter_starter_kit/features/auth/providers/post_auth_bootstrap_provider.dart';

/// Encapsulates the full sign-out sequence:
/// 1. Clear FCM token from Firestore (prevent notifications to signed-out device)
/// 2. Run feature-specific cleanup hooks (RevenueCat logout, etc.)
/// 3. Invalidate user-specific providers
/// 4. Auth sign-out (triggers router redirect via refreshListenable)
final signOutProvider = FutureProvider<void>((ref) async {
  final user = ref.read(authStateProvider).valueOrNull;
  if (user == null) return;

  // 1. Clear FCM token from Firestore (best-effort -- don't block sign-out)
  try {
    await ref.read(userProfileServiceProvider).clearFcmToken(user.uid);
  } catch (_) {
    // FCM cleanup failure should not prevent sign-out
  }

  // 2. Run feature-specific cleanup hooks (best-effort)
  for (final hook in ref.read(signOutHooksProvider)) {
    try {
      await hook(ref, user.uid);
    } catch (_) {
      // Feature cleanup failure should not prevent sign-out
    }
  }

  // 3. Invalidate user-specific providers
  ref.invalidate(userProfileProvider);
  ref.invalidate(postAuthBootstrapProvider);

  // 4. Clear Crashlytics user identifier
  if (AppConfig.enableCrashlytics && Firebase.apps.isNotEmpty) {
    await FirebaseCrashlytics.instance.setUserIdentifier('');
  }

  // 5. Sign out (triggers router refresh via refreshListenable)
  // NOTE: Do NOT invalidate routerProvider. Do NOT call context.go().
  await ref.read(authServiceProvider).signOut();
});
