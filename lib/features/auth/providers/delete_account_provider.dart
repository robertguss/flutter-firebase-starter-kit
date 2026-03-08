import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/features/profile/providers/profile_providers.dart';
import 'package:flutter_starter_kit/shared/providers/feature_hooks.dart';
import 'package:flutter_starter_kit/features/auth/providers/post_auth_bootstrap_provider.dart';

part 'delete_account_provider.g.dart';

/// Encapsulates the full account deletion sequence:
/// 1. Re-authenticate (validates session is fresh)
/// 2. Delete Storage avatar (while auth token is still valid)
/// 3. Delete Firestore profile (while auth token is still valid)
/// 4. Run feature-specific cleanup hooks (RevenueCat logout, etc.)
/// 5. Delete auth account (point of no return)
/// 6. Invalidate user-specific providers
///
/// TODO: Firestore does not cascade-delete sub-collections. If your app adds
/// sub-collections under user documents, use a Cloud Function triggered on
/// user deletion to recursively clean up all user data.
@riverpod
Future<void> deleteAccount(Ref ref) async {
  final user = ref.read(authStateProvider).value;
  if (user == null) return;

  // 1. Re-authenticate first (validates session is fresh)
  await ref.read(authServiceProvider).reauthenticate();

  // 2. Delete Storage avatar (best-effort -- don't block deletion)
  try {
    await ref.read(profileStorageServiceProvider).deleteAvatar(user.uid);
  } catch (_) {
    // Storage cleanup failure should not prevent account deletion
  }

  // 3. Delete Firestore profile FIRST (while auth token is still valid)
  await ref.read(userProfileServiceProvider).deleteProfile(user.uid);

  // 4. Run feature-specific cleanup hooks (RevenueCat logout, etc.)
  for (final hook in ref.read(deleteAccountHooksProvider)) {
    await hook(ref, user.uid);
  }

  // 5. Delete auth account LAST (point of no return)
  await ref.read(authServiceProvider).deleteAccount();

  // 6. Invalidate user-specific providers
  ref.invalidate(userProfileProvider);
  ref.invalidate(postAuthBootstrapProvider);
}
