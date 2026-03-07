import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/paywall/providers/purchases_provider.dart';
import 'package:flutter_starter_kit/shared/widgets/premium_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject({required bool isPremium, Widget? lockedWidget}) {
    return ProviderScope(
      overrides: [isPremiumProvider.overrideWithValue(isPremium)],
      child: MaterialApp(
        home: Scaffold(
          body: PremiumGate(
            lockedWidget: lockedWidget,
            child: const Text('Premium Content'),
          ),
        ),
      ),
    );
  }

  group('PremiumGate', () {
    testWidgets('shows child when user is premium', (tester) async {
      await tester.pumpWidget(buildSubject(isPremium: true));

      expect(find.text('Premium Content'), findsOneWidget);
      expect(find.text('Premium Feature'), findsNothing);
    });

    testWidgets('shows default locked UI when not premium', (tester) async {
      await tester.pumpWidget(buildSubject(isPremium: false));

      expect(find.text('Premium Content'), findsNothing);
      expect(find.text('Premium Feature'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.text('Upgrade'), findsOneWidget);
    });

    testWidgets('shows custom locked widget when provided', (tester) async {
      await tester.pumpWidget(buildSubject(
        isPremium: false,
        lockedWidget: const Text('Custom Lock'),
      ));

      expect(find.text('Premium Content'), findsNothing);
      expect(find.text('Custom Lock'), findsOneWidget);
      expect(find.text('Premium Feature'), findsNothing);
    });
  });
}
