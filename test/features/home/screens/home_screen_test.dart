import 'package:flutter/material.dart';
import 'package:flutter_starter_kit/features/home/screens/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('HomeShell', () {
    testWidgets('displays two navigation destinations (Home and Profile)', (tester) async {
      // Create a minimal StatefulNavigationShell mock via a real GoRouter
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return HomeShell(navigationShell: navigationShell);
            },
            branches: [
              StatefulShellBranch(routes: [
                GoRoute(
                  path: '/home',
                  builder: (_, __) => const Center(child: Text('Home Content')),
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  path: '/profile',
                  builder: (_, __) => const Center(child: Text('Profile Content')),
                ),
              ]),
            ],
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Explore'), findsNothing);
    });
  });
}
