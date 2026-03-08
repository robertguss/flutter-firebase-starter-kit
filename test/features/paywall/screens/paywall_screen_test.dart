import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/paywall/providers/purchases_provider.dart';
import 'package:flutter_starter_kit/features/paywall/screens/paywall_screen.dart';
import 'package:flutter_starter_kit/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

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

  Widget createApp({required ProviderContainer container}) {
    final router = GoRouter(
      initialLocation: '/paywall',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/paywall', builder: (_, __) => const PaywallScreen()),
      ],
    );

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
      ),
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

      final container = ProviderContainer(
        overrides: [
          purchasesServiceProvider.overrideWithValue(mockService),
          offeringsProvider.overrideWith((ref) => mockOfferings),
          customerInfoProvider.overrideWith((ref) async => mockCustomerInfo),
        ],
      );

      await tester.pumpWidget(createApp(container: container));
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

      container.dispose();
    });

    testWidgets('restore does not expose error.toString()', (tester) async {
      when(() => mockService.restorePurchases()).thenThrow(
        Exception('raw internal error'),
      );

      final mockOfferings = MockOfferings();
      when(() => mockOfferings.current).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          purchasesServiceProvider.overrideWithValue(mockService),
          offeringsProvider.overrideWith((ref) => mockOfferings),
          customerInfoProvider.overrideWith((ref) async => mockCustomerInfo),
        ],
      );

      await tester.pumpWidget(createApp(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Restore Purchases'));
      await tester.pumpAndSettle();

      expect(find.textContaining('raw internal error'), findsNothing);
      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );

      container.dispose();
    });
  });
}
