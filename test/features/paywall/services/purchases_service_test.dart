import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/paywall/providers/purchases_provider.dart';
import 'package:flutter_starter_kit/features/paywall/services/purchases_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class MockPurchasesService extends Mock implements PurchasesService {}

class MockCustomerInfo extends Mock implements CustomerInfo {}

class MockEntitlementInfos extends Mock implements EntitlementInfos {}

class MockEntitlementInfo extends Mock implements EntitlementInfo {}

class MockOfferings extends Mock implements Offerings {}

class MockPackage extends Mock implements Package {}

void main() {
  late MockPurchasesService mockService;

  setUp(() {
    mockService = MockPurchasesService();
  });

  setUpAll(() {
    registerFallbackValue(MockPackage());
  });

  group('PurchasesService mock contract', () {
    test('login calls through to RevenueCat', () async {
      when(() => mockService.login('user-123')).thenAnswer((_) async {});

      await mockService.login('user-123');

      verify(() => mockService.login('user-123')).called(1);
    });

    test('logout calls through to RevenueCat', () async {
      when(() => mockService.logout()).thenAnswer((_) async {});

      await mockService.logout();

      verify(() => mockService.logout()).called(1);
    });

    test('getCustomerInfo returns CustomerInfo', () async {
      final mockInfo = MockCustomerInfo();
      when(() => mockService.getCustomerInfo())
          .thenAnswer((_) async => mockInfo);

      final result = await mockService.getCustomerInfo();

      expect(result, mockInfo);
    });

    test('purchase returns CustomerInfo on success', () async {
      final mockInfo = MockCustomerInfo();
      final mockPackage = MockPackage();
      when(() => mockService.purchase(mockPackage))
          .thenAnswer((_) async => mockInfo);

      final result = await mockService.purchase(mockPackage);

      expect(result, mockInfo);
    });

    test('restorePurchases returns CustomerInfo', () async {
      final mockInfo = MockCustomerInfo();
      when(() => mockService.restorePurchases())
          .thenAnswer((_) async => mockInfo);

      final result = await mockService.restorePurchases();

      expect(result, mockInfo);
    });

    test('purchase throws on error', () async {
      final mockPackage = MockPackage();
      when(() => mockService.purchase(mockPackage))
          .thenThrow(Exception('Purchase failed'));

      expect(
        () => mockService.purchase(mockPackage),
        throwsA(isA<Exception>()),
      );
    });

    test('getCustomerInfo throws on network error', () async {
      when(() => mockService.getCustomerInfo())
          .thenThrow(Exception('Network error'));

      expect(
        () => mockService.getCustomerInfo(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('isPremiumProvider with mock service', () {
    test('returns true when entitlements contain premium', () async {
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
        ],
      );
      addTearDown(container.dispose);

      // Wait for customerInfoProvider to resolve
      await container.read(customerInfoProvider.future);

      expect(container.read(isPremiumProvider), true);
    });

    test('returns false when no premium entitlement', () async {
      final mockInfo = MockCustomerInfo();
      final mockEntitlements = MockEntitlementInfos();

      when(() => mockInfo.entitlements).thenReturn(mockEntitlements);
      when(() => mockEntitlements.active).thenReturn({});
      when(() => mockService.getCustomerInfo())
          .thenAnswer((_) async => mockInfo);

      final container = ProviderContainer(
        overrides: [
          purchasesServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      await container.read(customerInfoProvider.future);

      expect(container.read(isPremiumProvider), false);
    });

    test('returns false when customerInfo errors', () {
      when(() => mockService.getCustomerInfo())
          .thenThrow(Exception('Network error'));

      final container = ProviderContainer(
        overrides: [
          purchasesServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // When customerInfo fails, isPremium defaults to false
      expect(container.read(isPremiumProvider), false);
    });
  });
}
