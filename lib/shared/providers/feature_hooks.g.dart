// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feature_hooks.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Hooks called after sign-in to bootstrap feature state
/// (e.g., RevenueCat login, FCM token save).

@ProviderFor(bootstrapHooks)
const bootstrapHooksProvider = BootstrapHooksProvider._();

/// Hooks called after sign-in to bootstrap feature state
/// (e.g., RevenueCat login, FCM token save).

final class BootstrapHooksProvider
    extends
        $FunctionalProvider<
          List<FeatureHook>,
          List<FeatureHook>,
          List<FeatureHook>
        >
    with $Provider<List<FeatureHook>> {
  /// Hooks called after sign-in to bootstrap feature state
  /// (e.g., RevenueCat login, FCM token save).
  const BootstrapHooksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bootstrapHooksProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bootstrapHooksHash();

  @$internal
  @override
  $ProviderElement<List<FeatureHook>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<FeatureHook> create(Ref ref) {
    return bootstrapHooks(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FeatureHook> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FeatureHook>>(value),
    );
  }
}

String _$bootstrapHooksHash() => r'ab1a081e433d722bd4723ced59cc078824e10b12';

/// Hooks called during sign-out to clean up feature state
/// (e.g., RevenueCat logout, provider invalidation).

@ProviderFor(signOutHooks)
const signOutHooksProvider = SignOutHooksProvider._();

/// Hooks called during sign-out to clean up feature state
/// (e.g., RevenueCat logout, provider invalidation).

final class SignOutHooksProvider
    extends
        $FunctionalProvider<
          List<FeatureHook>,
          List<FeatureHook>,
          List<FeatureHook>
        >
    with $Provider<List<FeatureHook>> {
  /// Hooks called during sign-out to clean up feature state
  /// (e.g., RevenueCat logout, provider invalidation).
  const SignOutHooksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signOutHooksProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signOutHooksHash();

  @$internal
  @override
  $ProviderElement<List<FeatureHook>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<FeatureHook> create(Ref ref) {
    return signOutHooks(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FeatureHook> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FeatureHook>>(value),
    );
  }
}

String _$signOutHooksHash() => r'0d9130513160df1c0b80335bd0be061515384392';

/// Hooks called during account deletion to clean up feature data
/// (e.g., RevenueCat logout).

@ProviderFor(deleteAccountHooks)
const deleteAccountHooksProvider = DeleteAccountHooksProvider._();

/// Hooks called during account deletion to clean up feature data
/// (e.g., RevenueCat logout).

final class DeleteAccountHooksProvider
    extends
        $FunctionalProvider<
          List<FeatureHook>,
          List<FeatureHook>,
          List<FeatureHook>
        >
    with $Provider<List<FeatureHook>> {
  /// Hooks called during account deletion to clean up feature data
  /// (e.g., RevenueCat logout).
  const DeleteAccountHooksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteAccountHooksProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteAccountHooksHash();

  @$internal
  @override
  $ProviderElement<List<FeatureHook>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<FeatureHook> create(Ref ref) {
    return deleteAccountHooks(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FeatureHook> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FeatureHook>>(value),
    );
  }
}

String _$deleteAccountHooksHash() =>
    r'9dde9a765017b76e5379fe616dea421de6d119c7';

/// Action to restore purchases. Returns a message to display to the user.
/// Null when paywall is disabled.

@ProviderFor(restorePurchasesAction)
const restorePurchasesActionProvider = RestorePurchasesActionProvider._();

/// Action to restore purchases. Returns a message to display to the user.
/// Null when paywall is disabled.

final class RestorePurchasesActionProvider
    extends
        $FunctionalProvider<
          Future<String> Function()?,
          Future<String> Function()?,
          Future<String> Function()?
        >
    with $Provider<Future<String> Function()?> {
  /// Action to restore purchases. Returns a message to display to the user.
  /// Null when paywall is disabled.
  const RestorePurchasesActionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restorePurchasesActionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restorePurchasesActionHash();

  @$internal
  @override
  $ProviderElement<Future<String> Function()?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<String> Function()? create(Ref ref) {
    return restorePurchasesAction(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<String> Function()? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<String> Function()?>(value),
    );
  }
}

String _$restorePurchasesActionHash() =>
    r'd10442be963a4c4a4c43645d50cb1be33b0e2041';
