// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_auth_bootstrap_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Orchestrates all post-sign-in side effects in a defined order.
/// Watched by the App widget to show loading state during bootstrap.

@ProviderFor(postAuthBootstrap)
const postAuthBootstrapProvider = PostAuthBootstrapProvider._();

/// Orchestrates all post-sign-in side effects in a defined order.
/// Watched by the App widget to show loading state during bootstrap.

final class PostAuthBootstrapProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Orchestrates all post-sign-in side effects in a defined order.
  /// Watched by the App widget to show loading state during bootstrap.
  const PostAuthBootstrapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postAuthBootstrapProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postAuthBootstrapHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return postAuthBootstrap(ref);
  }
}

String _$postAuthBootstrapHash() => r'6c39ab6e9238f42845ade06f9ea9b8c28981b084';
