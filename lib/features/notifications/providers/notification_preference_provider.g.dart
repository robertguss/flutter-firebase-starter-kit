// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_preference_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NotificationPreference)
const notificationPreferenceProvider = NotificationPreferenceProvider._();

final class NotificationPreferenceProvider
    extends $NotifierProvider<NotificationPreference, bool> {
  const NotificationPreferenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationPreferenceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationPreferenceHash();

  @$internal
  @override
  NotificationPreference create() => NotificationPreference();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$notificationPreferenceHash() =>
    r'121f49286c98da5f26c3706838f110582bbdd256';

abstract class _$NotificationPreference extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
