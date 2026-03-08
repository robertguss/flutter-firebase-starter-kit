import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/models/user_profile.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/features/auth/services/auth_service.dart';
import 'package:flutter_starter_kit/features/auth/services/user_profile_service.dart';
import 'package:flutter_starter_kit/shared/providers/feature_hooks.dart';
import 'package:flutter_starter_kit/features/auth/providers/post_auth_bootstrap_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements User {}

class MockUserProfileService extends Mock implements UserProfileService {}

void main() {
  late MockAuthService mockAuthService;
  late MockUserProfileService mockProfileService;
  late ProviderContainer container;

  setUp(() {
    mockAuthService = MockAuthService();
    mockProfileService = MockUserProfileService();
  });

  tearDown(() {
    container.dispose();
  });

  group('postAuthBootstrapProvider', () {
    test('does nothing when user is null', () async {
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(null));

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          userProfileServiceProvider.overrideWithValue(mockProfileService),
        ],
      );

      await container.read(authStateProvider.future);
      await container.read(postAuthBootstrapProvider.future);

      verifyNever(() => mockProfileService.createOrUpdateProfile(any(), any()));
    });

    test('creates profile on first sign-in', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-1');
      when(() => mockUser.email).thenReturn('test@example.com');
      when(() => mockUser.displayName).thenReturn('Test User');
      when(() => mockUser.photoURL).thenReturn(null);
      when(() => mockUser.providerData).thenReturn([]);
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));
      when(() => mockProfileService.getProfile(any()))
          .thenAnswer((_) async => null);
      when(() => mockProfileService.createOrUpdateProfile(any(), any()))
          .thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          userProfileServiceProvider.overrideWithValue(mockProfileService),
        ],
      );

      await container.read(authStateProvider.future);
      await container.read(postAuthBootstrapProvider.future);

      verify(() => mockProfileService.createOrUpdateProfile(
            'uid-1',
            any(that: allOf(
              containsPair('email', 'test@example.com'),
              containsPair('onboardingComplete', false),
            )),
          )).called(1);
    });

    test('updates only mutable fields for returning user', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-1');
      when(() => mockUser.email).thenReturn('new@example.com');
      when(() => mockUser.displayName).thenReturn('New Name');
      when(() => mockUser.photoURL).thenReturn(null);
      when(() => mockUser.providerData).thenReturn([]);
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));
      when(() => mockProfileService.getProfile(any()))
          .thenAnswer((_) async => UserProfile(
                uid: 'uid-1',
                email: 'old@example.com',
                createdAt: DateTime(2026, 1, 1),
              ));
      when(() => mockProfileService.createOrUpdateProfile(any(), any()))
          .thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          userProfileServiceProvider.overrideWithValue(mockProfileService),
        ],
      );

      await container.read(authStateProvider.future);
      await container.read(postAuthBootstrapProvider.future);

      // Should NOT include createdAt or onboardingComplete for returning users
      verify(() => mockProfileService.createOrUpdateProfile(
            'uid-1',
            any(that: isNot(contains('createdAt'))),
          )).called(1);
    });

    test('runs bootstrap hooks', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-1');
      when(() => mockUser.email).thenReturn('test@example.com');
      when(() => mockUser.displayName).thenReturn('Test');
      when(() => mockUser.photoURL).thenReturn(null);
      when(() => mockUser.providerData).thenReturn([]);
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));
      when(() => mockProfileService.getProfile(any()))
          .thenAnswer((_) async => null);
      when(() => mockProfileService.createOrUpdateProfile(any(), any()))
          .thenAnswer((_) async {});

      var hookCalled = false;
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          userProfileServiceProvider.overrideWithValue(mockProfileService),
          bootstrapHooksProvider.overrideWithValue([
            (ref, uid) async {
              hookCalled = true;
              expect(uid, 'uid-1');
            },
          ]),
        ],
      );

      await container.read(authStateProvider.future);
      await container.read(postAuthBootstrapProvider.future);

      expect(hookCalled, true);
    });
  });
}
