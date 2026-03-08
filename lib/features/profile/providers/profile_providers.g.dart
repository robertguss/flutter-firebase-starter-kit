// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(profileStorageService)
const profileStorageServiceProvider = ProfileStorageServiceProvider._();

final class ProfileStorageServiceProvider
    extends
        $FunctionalProvider<
          ProfileStorageService,
          ProfileStorageService,
          ProfileStorageService
        >
    with $Provider<ProfileStorageService> {
  const ProfileStorageServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileStorageServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileStorageServiceHash();

  @$internal
  @override
  $ProviderElement<ProfileStorageService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileStorageService create(Ref ref) {
    return profileStorageService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileStorageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileStorageService>(value),
    );
  }
}

String _$profileStorageServiceHash() =>
    r'e2ce506ced21cfaa894d883e59c6f895fc8eb4b3';
