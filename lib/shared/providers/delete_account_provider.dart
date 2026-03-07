import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/features/paywall/providers/purchases_provider.dart';
import 'package:flutter_starter_kit/shared/providers/post_auth_bootstrap_provider.dart';

/// Encapsulates the full account deletion sequence:
/// 1. Re-authenticate (validates session is fresh)
/// 2. Delete Firestore profile (while auth token is still valid)
/// 3. RevenueCat logout
/// 4. Delete auth account (point of no return)
/// 5. Invalidate user-specific providers
final deleteAccountProvider = FutureProvider<void>((ref) async {
  final user = ref.read(authStateProvider).valueOrNull;
  if (user == null) return;

  // 1. Re-authenticate first (validates session is fresh)
  await ref.read(authServiceProvider).reauthenticate();

  // 2. Delete Firestore profile FIRST (while auth token is still valid)
  await ref.read(userProfileServiceProvider).deleteProfile(user.uid);

  // 3. RevenueCat logout
  await ref.read(purchasesServiceProvider).logout();

  // 4. Delete auth account LAST (point of no return)
  await ref.read(authServiceProvider).deleteAccount();

  // 5. Invalidate user-specific providers
  ref.invalidate(userProfileProvider);
  ref.invalidate(customerInfoProvider);
  ref.invalidate(postAuthBootstrapProvider);
});
