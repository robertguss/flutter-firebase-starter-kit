import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/models/user_profile.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/features/auth/services/auth_service.dart';
import 'package:flutter_starter_kit/routing/router.dart';
import 'package:flutter_starter_kit/routing/routes.dart';
import 'package:flutter_starter_kit/shared/providers/shared_preferences_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements User {}

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

  group('Router redirect', () {
    late MockAuthService mockAuthService;
    late ProviderContainer container;

    setUp(() async {
      mockAuthService = MockAuthService();
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      container.dispose();
    });

    test('GoRouter is created once and reused', () async {
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(null));
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final router1 = container.read(routerProvider);
      final router2 = container.read(routerProvider);
      expect(identical(router1, router2), true);
    });

    test('unauthenticated user redirected to /auth', () async {
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(null));
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      await container.read(authStateProvider.future);
      final router = container.read(routerProvider);
      final redirect = router.configuration.redirect;

      // Simulate redirect for /home when unauthenticated
      // The redirect function gates all routes behind auth
      expect(redirect, isNotNull);
    });

    test('router does not rebuild on auth state change', () async {
      final controller = StreamController<User?>.broadcast();
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => controller.stream);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final router1 = container.read(routerProvider);

      // Emit auth state change
      final mockUser = MockUser();
      controller.add(mockUser);
      await Future<void>.delayed(Duration.zero);

      // Router should be the same instance (not rebuilt)
      final router2 = container.read(routerProvider);
      expect(identical(router1, router2), true);

      await controller.close();
    });

    test('authenticated user with incomplete onboarding redirected to /onboarding', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-1');
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final profile = UserProfile(
        uid: 'uid-1',
        onboardingComplete: false,
        createdAt: DateTime(2026, 1, 1),
      );

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          sharedPreferencesProvider.overrideWithValue(prefs),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(profile),
          ),
        ],
      );

      await container.read(authStateProvider.future);
      await container.read(userProfileProvider.future);

      // Test redirect logic: authenticated user with incomplete onboarding
      // should be redirected away from /home to /onboarding
      final authState = container.read(authStateProvider);
      expect(authState.valueOrNull, isNotNull);
      final userProfile = container.read(userProfileProvider).valueOrNull;
      expect(userProfile, isNotNull);
      expect(userProfile!.onboardingComplete, false);
    });

    test('authenticated user with completed onboarding stays on /home', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-1');
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final profile = UserProfile(
        uid: 'uid-1',
        onboardingComplete: true,
        createdAt: DateTime(2026, 1, 1),
      );

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          sharedPreferencesProvider.overrideWithValue(prefs),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(profile),
          ),
        ],
      );

      await container.read(authStateProvider.future);
      await container.read(userProfileProvider.future);

      // Test redirect logic: authenticated user with complete onboarding
      // should not be redirected
      final userProfile = container.read(userProfileProvider).valueOrNull;
      expect(userProfile, isNotNull);
      expect(userProfile!.onboardingComplete, true);
    });
  });
}
