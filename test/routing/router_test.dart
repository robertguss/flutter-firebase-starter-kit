import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/routing/router.dart';
import 'package:flutter_starter_kit/routing/routes.dart';
import 'package:flutter_starter_kit/shared/providers/shared_preferences_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';

void main() {
  group('AppRoutes', () {
    test('auth route is /auth', () {
      expect(AppRoutes.auth, '/auth');
    });

    test('home route is /home', () {
      expect(AppRoutes.home, '/home');
    });

    test('onboarding route is /onboarding', () {
      expect(AppRoutes.onboarding, '/onboarding');
    });
  });

  group('routerRedirect', () {
    test('redirects unauthenticated user to /auth', () {
      expect(
        routerRedirect(user: null, profile: null, location: '/home'),
        AppRoutes.auth,
      );
    });

    test('unauthenticated user on /auth is not redirected', () {
      expect(
        routerRedirect(user: null, profile: null, location: '/auth'),
        isNull,
      );
    });

    test('authenticated user on /auth is redirected to /home', () {
      final mockUser = MockUser();
      final profile = createTestProfile(uid: 'uid-1', onboardingComplete: true);

      expect(
        routerRedirect(user: mockUser, profile: profile, location: '/auth'),
        AppRoutes.home,
      );
    });

    test('authenticated user with incomplete onboarding redirected to /onboarding', () {
      final mockUser = MockUser();
      final profile = createTestProfile(uid: 'uid-1', onboardingComplete: false);

      expect(
        routerRedirect(user: mockUser, profile: profile, location: '/home'),
        AppRoutes.onboarding,
      );
    });

    test('authenticated user with complete onboarding stays on /home', () {
      final mockUser = MockUser();
      final profile = createTestProfile(uid: 'uid-1', onboardingComplete: true);

      expect(
        routerRedirect(user: mockUser, profile: profile, location: '/home'),
        isNull,
      );
    });

    test('authenticated user on /onboarding is not redirected', () {
      final mockUser = MockUser();
      final profile = createTestProfile(uid: 'uid-1', onboardingComplete: false);

      expect(
        routerRedirect(user: mockUser, profile: profile, location: '/onboarding'),
        isNull,
      );
    });
  });

  group('Router instance', () {
    test('GoRouter is created once and reused', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer.test(
        overrides: [
          authStateProvider.overrideWithValue(const AsyncValue.data(null)),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final router1 = container.read(routerProvider);
      final router2 = container.read(routerProvider);
      expect(identical(router1, router2), true);
    });

    test('router does not rebuild on auth state change', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockUser = MockUser();

      final container = ProviderContainer.test(
        overrides: [
          authStateProvider.overrideWithValue(const AsyncValue.data(null)),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final router1 = container.read(routerProvider);

      // Update the auth state
      container.updateOverrides([
        authStateProvider.overrideWithValue(AsyncValue.data(mockUser)),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      await Future<void>.delayed(Duration.zero);

      final router2 = container.read(routerProvider);
      expect(identical(router1, router2), true);
    });
  });
}
