import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/paywall/providers/purchases_provider.dart';
import 'package:flutter_starter_kit/features/paywall/screens/paywall_screen.dart';
import 'package:flutter_starter_kit/features/paywall/services/purchases_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class MockPurchasesService extends Mock implements PurchasesService {}

class MockCustomerInfo extends Mock implements CustomerInfo {}

class MockEntitlementInfos extends Mock implements EntitlementInfos {}

class MockOfferings extends Mock implements Offerings {}

class MockOffering extends Mock implements Offering {}

class MockPackage extends Mock implements Package {}

class MockStoreProduct extends Mock implements StoreProduct {}

void main() {
  late MockPurchasesService mockService;
  late MockCustomerInfo mockCustomerInfo;
  late MockEntitlementInfos mockEntitlements;

  setUp(() {
    mockService = MockPurchasesService();
    mockCustomerInfo = MockCustomerInfo();
    mockEntitlements = MockEntitlementInfos();

    when(() => mockCustomerInfo.entitlements).thenReturn(mockEntitlements);
    when(() => mockEntitlements.active).thenReturn({});
  });

  Widget createApp({required List<Override> overrides}) {
    final router = GoRouter(
      initialLocation: '/paywall',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/paywall', builder: (_, __) => const PaywallScreen()),
      ],
    );

    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('PaywallScreen error sanitization', () {
    testWidgets('restore shows friendly message on PlatformException', (
      tester,
    ) async {
      when(() => mockService.restorePurchases()).thenThrow(
        PlatformException(
          code: 'PURCHASE_ERROR',
          message: 'internal RevenueCat details',
        ),
      );

      // Provide empty offerings so the screen renders
      final mockOfferings = MockOfferings();
      when(() => mockOfferings.current).thenReturn(null);

      await tester.pumpWidget(
        createApp(
          overrides: [
            purchasesServiceProvider.overrideWithValue(mockService),
            offeringsProvider.overrideWith((ref) => mockOfferings),
            customerInfoProvider.overrideWith((ref) async => mockCustomerInfo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap restore purchases
      await tester.tap(find.text('Restore Purchases'));
      await tester.pumpAndSettle();

      // Should show friendly message, not raw error
      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('internal RevenueCat details'), findsNothing);
    });

    testWidgets('restore does not expose error.toString()', (tester) async {
      when(() => mockService.restorePurchases()).thenThrow(
        Exception('raw internal error'),
      );

      final mockOfferings = MockOfferings();
      when(() => mockOfferings.current).thenReturn(null);

      await tester.pumpWidget(
        createApp(
          overrides: [
            purchasesServiceProvider.overrideWithValue(mockService),
            offeringsProvider.overrideWith((ref) => mockOfferings),
            customerInfoProvider.overrideWith((ref) async => mockCustomerInfo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Restore Purchases'));
      await tester.pumpAndSettle();

      expect(find.textContaining('raw internal error'), findsNothing);
      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
    });
  });
}
