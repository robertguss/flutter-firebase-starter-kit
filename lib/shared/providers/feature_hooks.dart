import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feature_hooks.g.dart';

/// Async callback for feature lifecycle hooks.
/// [ref] allows reading/invalidating providers. [uid] is the current user's ID.
typedef FeatureHook = Future<void> Function(Ref ref, String uid);

/// Hooks called after sign-in to bootstrap feature state
/// (e.g., RevenueCat login, FCM token save).
@Riverpod(keepAlive: true)
List<FeatureHook> bootstrapHooks(Ref ref) => [];

/// Hooks called during sign-out to clean up feature state
/// (e.g., RevenueCat logout, provider invalidation).
@Riverpod(keepAlive: true)
List<FeatureHook> signOutHooks(Ref ref) => [];

/// Hooks called during account deletion to clean up feature data
/// (e.g., RevenueCat logout).
@Riverpod(keepAlive: true)
List<FeatureHook> deleteAccountHooks(Ref ref) => [];

/// Action to restore purchases. Returns a message to display to the user.
/// Null when paywall is disabled.
@Riverpod(keepAlive: true)
Future<String> Function()? restorePurchasesAction(Ref ref) => null;
