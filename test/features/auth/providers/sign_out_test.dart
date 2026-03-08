import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/post_auth_bootstrap_provider.dart';
import 'package:flutter_starter_kit/shared/providers/feature_hooks.dart';
import 'package:flutter_starter_kit/features/auth/providers/sign_out_provider.dart';
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
    List<FeatureHook>? signOutHooks,
  }) {
    return ProviderContainer.test(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
        authStateProvider.overrideWithValue(authState),
        userProfileServiceProvider.overrideWithValue(mockProfileService),
        userProfileProvider.overrideWithValue(const AsyncValue.data(null)),
        postAuthBootstrapProvider.overrideWithValue(const AsyncValue.data(null)),
        if (signOutHooks != null)
          signOutHooksProvider.overrideWithValue(signOutHooks),
      ],
    );
  }

  group('signOutProvider', () {
    test('clears FCM token before sign-out', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-1');
      when(() => mockProfileService.clearFcmToken(any()))
          .thenAnswer((_) async {});
      when(() => mockAuthService.signOut()).thenAnswer((_) async {});

      final container = createContainer(
        authState: AsyncValue.data(mockUser),
      );
      await container.read(signOutProvider.future);

      verify(() => mockProfileService.clearFcmToken('uid-1')).called(1);
    });

    test('runs sign-out hooks', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-1');
      when(() => mockProfileService.clearFcmToken(any()))
          .thenAnswer((_) async {});
      when(() => mockAuthService.signOut()).thenAnswer((_) async {});

      var hookCalled = false;
      final container = createContainer(
        authState: AsyncValue.data(mockUser),
        signOutHooks: [
          (ref, uid) async {
            hookCalled = true;
            expect(uid, 'uid-1');
          },
        ],
      );
      await container.read(signOutProvider.future);

      expect(hookCalled, true);
    });

    test('calls auth signOut last', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-1');
      when(() => mockProfileService.clearFcmToken(any()))
          .thenAnswer((_) async {});
      when(() => mockAuthService.signOut()).thenAnswer((_) async {});

      final container = createContainer(
        authState: AsyncValue.data(mockUser),
      );
      await container.read(signOutProvider.future);

      verify(() => mockAuthService.signOut()).called(1);
    });

    test('does nothing when user is null', () async {
      final container = createContainer(
        authState: const AsyncValue.data(null),
      );
      await container.read(signOutProvider.future);

      verifyNever(() => mockProfileService.clearFcmToken(any()));
      verifyNever(() => mockAuthService.signOut());
    });
  });
}
