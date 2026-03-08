import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/shared/providers/feature_hooks.dart';
import 'package:flutter_starter_kit/features/auth/providers/sign_out_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

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

  group('signOutProvider', () {
    test('clears FCM token before sign-out', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-1');
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));
      when(() => mockProfileService.clearFcmToken(any()))
          .thenAnswer((_) async {});
      when(() => mockAuthService.signOut()).thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          userProfileServiceProvider.overrideWithValue(mockProfileService),
        ],
      );

      await container.read(authStateProvider.future);
      await container.read(signOutProvider.future);

      verify(() => mockProfileService.clearFcmToken('uid-1')).called(1);
    });

    test('runs sign-out hooks', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-1');
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));
      when(() => mockProfileService.clearFcmToken(any()))
          .thenAnswer((_) async {});
      when(() => mockAuthService.signOut()).thenAnswer((_) async {});

      var hookCalled = false;
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          userProfileServiceProvider.overrideWithValue(mockProfileService),
          signOutHooksProvider.overrideWithValue([
            (ref, uid) async {
              hookCalled = true;
              expect(uid, 'uid-1');
            },
          ]),
        ],
      );

      await container.read(authStateProvider.future);
      await container.read(signOutProvider.future);

      expect(hookCalled, true);
    });

    test('calls auth signOut last', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-1');
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));
      when(() => mockProfileService.clearFcmToken(any()))
          .thenAnswer((_) async {});
      when(() => mockAuthService.signOut()).thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          userProfileServiceProvider.overrideWithValue(mockProfileService),
        ],
      );

      await container.read(authStateProvider.future);
      await container.read(signOutProvider.future);

      verify(() => mockAuthService.signOut()).called(1);
    });

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
      await container.read(signOutProvider.future);

      verifyNever(() => mockProfileService.clearFcmToken(any()));
      verifyNever(() => mockAuthService.signOut());
    });
  });
}
