// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_account_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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
/// Use with `ref.read(deleteAccountProvider.future)` only. Do not `ref.watch` —
/// the future would re-execute on every widget rebuild.

@ProviderFor(deleteAccount)
const deleteAccountProvider = DeleteAccountProvider._();

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
/// Use with `ref.read(deleteAccountProvider.future)` only. Do not `ref.watch` —
/// the future would re-execute on every widget rebuild.

final class DeleteAccountProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
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
  /// Use with `ref.read(deleteAccountProvider.future)` only. Do not `ref.watch` —
  /// the future would re-execute on every widget rebuild.
  const DeleteAccountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteAccountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteAccountHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return deleteAccount(ref);
  }
}

String _$deleteAccountHash() => r'26f5245de79fb9315fbe7400776cac329782fdba';
