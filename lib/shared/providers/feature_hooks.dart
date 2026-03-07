import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Async callback for feature lifecycle hooks.
/// [ref] allows reading/invalidating providers. [uid] is the current user's ID.
typedef FeatureHook = Future<void> Function(Ref ref, String uid);

/// Hooks called after sign-in to bootstrap feature state
/// (e.g., RevenueCat login, FCM token save).
final bootstrapHooksProvider = Provider<List<FeatureHook>>((ref) => []);

/// Hooks called during sign-out to clean up feature state
/// (e.g., RevenueCat logout, provider invalidation).
final signOutHooksProvider = Provider<List<FeatureHook>>((ref) => []);

/// Hooks called during account deletion to clean up feature data
/// (e.g., RevenueCat logout).
final deleteAccountHooksProvider = Provider<List<FeatureHook>>((ref) => []);

/// Action to restore purchases. Returns a message to display to the user.
/// Null when paywall is disabled.
final restorePurchasesActionProvider = Provider<Future<String> Function()?>(
  (ref) => null,
);
