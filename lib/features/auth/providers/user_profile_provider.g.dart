// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(userProfileService)
const userProfileServiceProvider = UserProfileServiceProvider._();

final class UserProfileServiceProvider
    extends
        $FunctionalProvider<
          UserProfileService,
          UserProfileService,
          UserProfileService
        >
    with $Provider<UserProfileService> {
  const UserProfileServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProfileServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userProfileServiceHash();

  @$internal
  @override
  $ProviderElement<UserProfileService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UserProfileService create(Ref ref) {
    return userProfileService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserProfileService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserProfileService>(value),
    );
  }
}

String _$userProfileServiceHash() =>
    r'ebc0b3bd5ced10297c6403d9d8c675dc58c673ef';

@ProviderFor(userProfile)
const userProfileProvider = UserProfileProvider._();

final class UserProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserProfile?>,
          UserProfile?,
          Stream<UserProfile?>
        >
    with $FutureModifier<UserProfile?>, $StreamProvider<UserProfile?> {
  const UserProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProfileProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userProfileHash();

  @$internal
  @override
  $StreamProviderElement<UserProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<UserProfile?> create(Ref ref) {
    return userProfile(ref);
  }
}

String _$userProfileHash() => r'39ab8d73438419713d3db332f974ab1eac18e1f6';
