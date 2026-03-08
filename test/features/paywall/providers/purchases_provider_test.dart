import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/paywall/providers/purchases_provider.dart';
import 'package:flutter_starter_kit/shared/providers/premium_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  group('isPremiumProvider', () {
    test('defaults to false', () {
      final container = ProviderContainer.test();

      expect(container.read(isPremiumProvider), false);
    });
  });

  group('customerInfoProvider', () {
    test('returns CustomerInfo from PurchasesService', () async {
      final mockService = MockPurchasesService();
      final mockInfo = MockCustomerInfo();
      when(() => mockService.getCustomerInfo())
          .thenAnswer((_) async => mockInfo);

      final container = ProviderContainer.test(
        overrides: [
          purchasesServiceProvider.overrideWithValue(mockService),
        ],
      );

      final result = await container.read(customerInfoProvider.future);
      expect(result, mockInfo);
    });

    test('propagates error from service', () async {
      final mockService = MockPurchasesService();
      when(() => mockService.getCustomerInfo())
          .thenThrow(Exception('Network error'));

      final container = ProviderContainer.test(
        overrides: [
          purchasesServiceProvider.overrideWithValue(mockService),
          customerInfoProvider
              .overrideWithValue(AsyncValue.error(Exception('Network error'), StackTrace.empty)),
        ],
      );

      final state = container.read(customerInfoProvider);
      expect(state.hasError, true);
    });
  });

  group('isPremium derived from real provider chain', () {
    test('returns true when active entitlement exists', () async {
      final mockInfo = MockCustomerInfo();
      final mockEntitlements = MockEntitlementInfos();
      final premiumEntitlement = MockEntitlementInfo();

      when(() => mockInfo.entitlements).thenReturn(mockEntitlements);
      when(() => mockEntitlements.active)
          .thenReturn({'premium': premiumEntitlement});

      final container = ProviderContainer.test(
        overrides: [
          customerInfoProvider.overrideWithValue(AsyncValue.data(mockInfo)),
          isPremiumProvider.overrideWith((ref) {
            final customerInfo = ref.watch(customerInfoProvider);
            return customerInfo.when(
                  data: (info) =>
                      info.entitlements.active.containsKey('premium'),
                  loading: () => false,
                  error: (_, __) => false,
                );
          }),
        ],
      );

      expect(container.read(isPremiumProvider), true);
    });

    test('returns false when no active entitlements', () async {
      final mockInfo = MockCustomerInfo();
      final mockEntitlements = MockEntitlementInfos();

      when(() => mockInfo.entitlements).thenReturn(mockEntitlements);
      when(() => mockEntitlements.active).thenReturn({});

      final container = ProviderContainer.test(
        overrides: [
          customerInfoProvider.overrideWithValue(AsyncValue.data(mockInfo)),
          isPremiumProvider.overrideWith((ref) {
            final customerInfo = ref.watch(customerInfoProvider);
            return customerInfo.when(
                  data: (info) =>
                      info.entitlements.active.containsKey('premium'),
                  loading: () => false,
                  error: (_, __) => false,
                );
          }),
        ],
      );

      expect(container.read(isPremiumProvider), false);
    });
  });
}
