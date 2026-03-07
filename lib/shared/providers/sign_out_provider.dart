import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/features/notifications/providers/notification_provider.dart';
import 'package:flutter_starter_kit/features/paywall/providers/purchases_provider.dart';
import 'package:flutter_starter_kit/shared/providers/post_auth_bootstrap_provider.dart';

/// Encapsulates the full sign-out sequence:
/// 1. Clear FCM token from Firestore (prevent notifications to signed-out device)
/// 2. RevenueCat logout
/// 3. Invalidate all user-specific providers
/// 4. Auth sign-out (triggers router redirect via refreshListenable)
final signOutProvider = FutureProvider<void>((ref) async {
  final user = ref.read(authStateProvider).valueOrNull;
  if (user == null) return;

  // 1. Clear FCM token from Firestore
  await ref.read(userProfileServiceProvider).clearFcmToken(user.uid);

  // 2. RevenueCat logout
  await ref.read(purchasesServiceProvider).logout();

  // 3. Invalidate all user-specific providers
  ref.invalidate(customerInfoProvider);
  ref.invalidate(offeringsProvider);
  ref.invalidate(userProfileProvider);
  ref.invalidate(postAuthBootstrapProvider);

  // 4. Sign out (triggers router refresh via refreshListenable)
  // NOTE: Do NOT invalidate routerProvider. Do NOT call context.go().
  await ref.read(authServiceProvider).signOut();
});
