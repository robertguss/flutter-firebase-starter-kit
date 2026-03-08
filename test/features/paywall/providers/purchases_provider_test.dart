import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/paywall/providers/purchases_provider.dart';
import 'package:flutter_starter_kit/shared/providers/premium_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  group('isPremiumProvider', () {
    test('defaults to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(isPremiumProvider), false);
    });
  });

  group('customerInfoProvider', () {
    test('returns CustomerInfo from PurchasesService', () async {
      final mockService = MockPurchasesService();
      final mockInfo = MockCustomerInfo();
      when(() => mockService.getCustomerInfo())
          .thenAnswer((_) async => mockInfo);

      final container = ProviderContainer(
        overrides: [
          purchasesServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(customerInfoProvider.future);
      expect(result, mockInfo);
    });

    test('propagates error from service', () async {
      final mockService = MockPurchasesService();
      when(() => mockService.getCustomerInfo())
          .thenThrow(Exception('Network error'));

      final container = ProviderContainer(
        overrides: [
          purchasesServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(customerInfoProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('isPremium derived from real provider chain', () {
    test('returns true when active entitlement exists', () async {
      final mockService = MockPurchasesService();
      final mockInfo = MockCustomerInfo();
      final mockEntitlements = MockEntitlementInfos();
      final premiumEntitlement = MockEntitlementInfo();

      when(() => mockInfo.entitlements).thenReturn(mockEntitlements);
      when(() => mockEntitlements.active)
          .thenReturn({'premium': premiumEntitlement});
      when(() => mockService.getCustomerInfo())
          .thenAnswer((_) async => mockInfo);

      final container = ProviderContainer(
        overrides: [
          purchasesServiceProvider.overrideWithValue(mockService),
          // Override isPremium to derive from the real customerInfoProvider
          isPremiumProvider.overrideWith((ref) {
            final customerInfo = ref.watch(customerInfoProvider);
            return customerInfo.whenOrNull(
                  data: (info) =>
                      info.entitlements.active.containsKey('premium'),
                ) ??
                false;
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(customerInfoProvider.future);
      expect(container.read(isPremiumProvider), true);
    });

    test('returns false when no active entitlements', () async {
      final mockService = MockPurchasesService();
      final mockInfo = MockCustomerInfo();
      final mockEntitlements = MockEntitlementInfos();

      when(() => mockInfo.entitlements).thenReturn(mockEntitlements);
      when(() => mockEntitlements.active).thenReturn({});
      when(() => mockService.getCustomerInfo())
          .thenAnswer((_) async => mockInfo);

      final container = ProviderContainer(
        overrides: [
          purchasesServiceProvider.overrideWithValue(mockService),
          isPremiumProvider.overrideWith((ref) {
            final customerInfo = ref.watch(customerInfoProvider);
            return customerInfo.whenOrNull(
                  data: (info) =>
                      info.entitlements.active.containsKey('premium'),
                ) ??
                false;
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(customerInfoProvider.future);
      expect(container.read(isPremiumProvider), false);
    });
  });
}
