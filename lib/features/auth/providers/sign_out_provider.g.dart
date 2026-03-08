// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_out_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Encapsulates the full sign-out sequence:
/// 1. Clear FCM token from Firestore (prevent notifications to signed-out device)
/// 2. Run feature-specific cleanup hooks (RevenueCat logout, etc.)
/// 3. Invalidate user-specific providers
/// 4. Auth sign-out (triggers router redirect via refreshListenable)

@ProviderFor(signOut)
const signOutProvider = SignOutProvider._();

/// Encapsulates the full sign-out sequence:
/// 1. Clear FCM token from Firestore (prevent notifications to signed-out device)
/// 2. Run feature-specific cleanup hooks (RevenueCat logout, etc.)
/// 3. Invalidate user-specific providers
/// 4. Auth sign-out (triggers router redirect via refreshListenable)

final class SignOutProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Encapsulates the full sign-out sequence:
  /// 1. Clear FCM token from Firestore (prevent notifications to signed-out device)
  /// 2. Run feature-specific cleanup hooks (RevenueCat logout, etc.)
  /// 3. Invalidate user-specific providers
  /// 4. Auth sign-out (triggers router redirect via refreshListenable)
  const SignOutProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signOutProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signOutHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return signOut(ref);
  }
}

String _$signOutHash() => r'3eb21bde53a86f6fd027bf0fc366e5a77b572454';
