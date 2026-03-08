import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/routing/router.dart';
import 'package:flutter_starter_kit/routing/routes.dart';
import 'package:flutter_starter_kit/shared/providers/shared_preferences_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
    late MockAuthService mockAuthService;
    late ProviderContainer container;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    tearDown(() {
      container.dispose();
    });

    ProviderContainer createContainer({
      User? user,
      bool onboardingComplete = true,
    }) {
      when(() => mockAuthService.authStateChanges).thenAnswer(
        (_) => Stream.value(user),
      );

      final overrides = <Override>[
        authServiceProvider.overrideWithValue(mockAuthService),
      ];

      if (user != null) {
        final profile = createTestProfile(
          uid: user.uid,
          onboardingComplete: onboardingComplete,
        );
        overrides.add(
          userProfileProvider.overrideWith((_) => Stream.value(profile)),
        );
      }

      return ProviderContainer(overrides: overrides);
    }

    test('redirects unauthenticated user to /auth', () async {
      container = createContainer(user: null);
      await container.read(authStateProvider.future);

      expect(routerRedirect(_TestRef(container), '/home'), AppRoutes.auth);
    });

    test('unauthenticated user on /auth is not redirected', () async {
      container = createContainer(user: null);
      await container.read(authStateProvider.future);

      expect(routerRedirect(_TestRef(container), '/auth'), isNull);
    });

    test('authenticated user on /auth is redirected to /home', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-1');
      container = createContainer(user: mockUser);
      await container.read(authStateProvider.future);
      await container.read(userProfileProvider.future);

      expect(routerRedirect(_TestRef(container), '/auth'), AppRoutes.home);
    });

    test('authenticated user with incomplete onboarding redirected to /onboarding', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-1');
      container = createContainer(user: mockUser, onboardingComplete: false);
      await container.read(authStateProvider.future);
      await container.read(userProfileProvider.future);

      expect(
        routerRedirect(_TestRef(container), '/home'),
        AppRoutes.onboarding,
      );
    });

    test('authenticated user with complete onboarding stays on /home', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-1');
      container = createContainer(user: mockUser, onboardingComplete: true);
      await container.read(authStateProvider.future);
      await container.read(userProfileProvider.future);

      expect(routerRedirect(_TestRef(container), '/home'), isNull);
    });

    test('authenticated user on /onboarding is not redirected', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-1');
      container = createContainer(user: mockUser, onboardingComplete: false);
      await container.read(authStateProvider.future);
      await container.read(userProfileProvider.future);

      expect(routerRedirect(_TestRef(container), '/onboarding'), isNull);
    });
  });

  group('Router instance', () {
    test('GoRouter is created once and reused', () async {
      final mockAuthService = MockAuthService();
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(null));
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final router1 = container.read(routerProvider);
      final router2 = container.read(routerProvider);
      expect(identical(router1, router2), true);

      container.dispose();
    });

    test('router does not rebuild on auth state change', () async {
      final controller = StreamController<User?>.broadcast();
      final mockAuthService = MockAuthService();
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => controller.stream);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final router1 = container.read(routerProvider);

      final mockUser = MockUser();
      controller.add(mockUser);
      await Future<void>.delayed(Duration.zero);

      final router2 = container.read(routerProvider);
      expect(identical(router1, router2), true);

      container.dispose();
      await controller.close();
    });
  });
}

/// Minimal Ref adapter that delegates reads to a ProviderContainer.
/// This allows testing routerRedirect without needing a full widget tree.
class _TestRef implements Ref {
  _TestRef(this._container);
  final ProviderContainer _container;

  @override
  T read<T>(ProviderListenable<T> provider) => _container.read(provider);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Only read() is supported in test ref');
}
