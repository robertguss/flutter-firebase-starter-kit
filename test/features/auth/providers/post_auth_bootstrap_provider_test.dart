import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/models/user_profile.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/shared/providers/feature_hooks.dart';
import 'package:flutter_starter_kit/features/auth/providers/post_auth_bootstrap_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthService mockAuthService;
  late MockUserProfileService mockProfileService;

  setUp(() {
    mockAuthService = MockAuthService();
    mockProfileService = MockUserProfileService();
  });

  ProviderContainer createContainer({
    AsyncValue<User?> authState = const AsyncValue.data(null),
    List<FeatureHook>? bootstrapHooksList,
  }) {
    return ProviderContainer.test(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
        authStateProvider.overrideWithValue(authState),
        userProfileServiceProvider.overrideWithValue(mockProfileService),
        userProfileProvider.overrideWithValue(const AsyncValue.data(null)),
        if (bootstrapHooksList != null)
          bootstrapHooksProvider.overrideWithValue(bootstrapHooksList),
      ],
    );
  }

  group('postAuthBootstrapProvider', () {
    test('does nothing when user is null', () async {
      final container = createContainer(
        authState: const AsyncValue.data(null),
      );
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
      when(() => mockProfileService.getProfile(any()))
          .thenAnswer((_) async => null);
      when(() => mockProfileService.createOrUpdateProfile(any(), any()))
          .thenAnswer((_) async {});

      final container = createContainer(
        authState: AsyncValue.data(mockUser),
      );
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
      when(() => mockProfileService.getProfile(any()))
          .thenAnswer((_) async => UserProfile(
                uid: 'uid-1',
                email: 'old@example.com',
                createdAt: DateTime(2026, 1, 1),
              ));
      when(() => mockProfileService.createOrUpdateProfile(any(), any()))
          .thenAnswer((_) async {});

      final container = createContainer(
        authState: AsyncValue.data(mockUser),
      );
      await container.read(postAuthBootstrapProvider.future);

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
      when(() => mockProfileService.getProfile(any()))
          .thenAnswer((_) async => null);
      when(() => mockProfileService.createOrUpdateProfile(any(), any()))
          .thenAnswer((_) async {});

      var hookCalled = false;
      final container = createContainer(
        authState: AsyncValue.data(mockUser),
        bootstrapHooksList: [
          (ref, uid) async {
            hookCalled = true;
            expect(uid, 'uid-1');
          },
        ],
      );
      await container.read(postAuthBootstrapProvider.future);

      expect(hookCalled, true);
    });
  });
}
