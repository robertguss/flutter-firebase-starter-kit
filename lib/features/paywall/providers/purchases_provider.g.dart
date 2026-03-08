// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchases_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(purchasesService)
const purchasesServiceProvider = PurchasesServiceProvider._();

final class PurchasesServiceProvider
    extends
        $FunctionalProvider<
          PurchasesService,
          PurchasesService,
          PurchasesService
        >
    with $Provider<PurchasesService> {
  const PurchasesServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'purchasesServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$purchasesServiceHash();

  @$internal
  @override
  $ProviderElement<PurchasesService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PurchasesService create(Ref ref) {
    return purchasesService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PurchasesService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PurchasesService>(value),
    );
  }
}

String _$purchasesServiceHash() => r'c23afbfa6ea941b212f9c39c141e5514d96ec53a';

@ProviderFor(customerInfo)
const customerInfoProvider = CustomerInfoProvider._();

final class CustomerInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<CustomerInfo>,
          CustomerInfo,
          FutureOr<CustomerInfo>
        >
    with $FutureModifier<CustomerInfo>, $FutureProvider<CustomerInfo> {
  const CustomerInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customerInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customerInfoHash();

  @$internal
  @override
  $FutureProviderElement<CustomerInfo> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CustomerInfo> create(Ref ref) {
    return customerInfo(ref);
  }
}

String _$customerInfoHash() => r'1128e75e0fd96170b02ff65ce90adbf1b52501ab';

@ProviderFor(offerings)
const offeringsProvider = OfferingsProvider._();

final class OfferingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Offerings>,
          Offerings,
          FutureOr<Offerings>
        >
    with $FutureModifier<Offerings>, $FutureProvider<Offerings> {
  const OfferingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offeringsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offeringsHash();

  @$internal
  @override
  $FutureProviderElement<Offerings> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Offerings> create(Ref ref) {
    return offerings(ref);
  }
}

String _$offeringsHash() => r'45f12bcfc8b79933968c6815c0c0847dd8ec1dac';
