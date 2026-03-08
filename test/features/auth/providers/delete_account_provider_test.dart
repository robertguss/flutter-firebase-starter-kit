import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/post_auth_bootstrap_provider.dart';
import 'package:flutter_starter_kit/features/profile/providers/profile_providers.dart';
import 'package:flutter_starter_kit/shared/providers/feature_hooks.dart';
import 'package:flutter_starter_kit/features/auth/providers/delete_account_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthService mockAuthService;
  late MockUserProfileService mockProfileService;
  late MockProfileStorageService mockStorageService;
  late MockUser mockUser;

  setUp(() {
    mockAuthService = MockAuthService();
    mockProfileService = MockUserProfileService();
    mockStorageService = MockProfileStorageService();
    mockUser = MockUser();

    when(() => mockUser.uid).thenReturn('uid-1');
    when(() => mockAuthService.reauthenticate()).thenAnswer((_) async {});
    when(() => mockAuthService.deleteAccount()).thenAnswer((_) async {});
    when(() => mockProfileService.deleteProfile(any()))
        .thenAnswer((_) async {});
    when(() => mockStorageService.deleteAvatar(any()))
        .thenAnswer((_) async {});
  });

  ProviderContainer createContainer({
    AsyncValue<User?> authState = const AsyncValue.data(null),
    List<FeatureHook>? deleteHooks,
  }) {
    return ProviderContainer.test(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
        authStateProvider.overrideWithValue(authState),
        userProfileServiceProvider.overrideWithValue(mockProfileService),
        profileStorageServiceProvider.overrideWithValue(mockStorageService),
        userProfileProvider.overrideWithValue(const AsyncValue.data(null)),
        postAuthBootstrapProvider.overrideWithValue(const AsyncValue.data(null)),
        if (deleteHooks != null)
          deleteAccountHooksProvider.overrideWithValue(deleteHooks),
      ],
    );
  }

  group('deleteAccountProvider', () {
    test('calls reauthenticate first', () async {
      final container = createContainer(
        authState: AsyncValue.data(mockUser),
      );
      await container.read(deleteAccountProvider.future);

      verify(() => mockAuthService.reauthenticate()).called(1);
    });

    test('deletes Firestore profile before auth account', () async {
      final callOrder = <String>[];
      when(() => mockProfileService.deleteProfile(any())).thenAnswer((_) async {
        callOrder.add('firestore_delete');
      });
      when(() => mockAuthService.deleteAccount()).thenAnswer((_) async {
        callOrder.add('auth_delete');
      });

      final container = createContainer(
        authState: AsyncValue.data(mockUser),
      );
      await container.read(deleteAccountProvider.future);

      expect(callOrder, ['firestore_delete', 'auth_delete']);
    });

    test('runs delete account hooks before auth delete', () async {
      final callOrder = <String>[];
      when(() => mockAuthService.deleteAccount()).thenAnswer((_) async {
        callOrder.add('auth_delete');
      });

      final container = createContainer(
        authState: AsyncValue.data(mockUser),
        deleteHooks: [
          (ref, uid) async {
            callOrder.add('hook_cleanup');
          },
        ],
      );
      await container.read(deleteAccountProvider.future);

      expect(callOrder, ['hook_cleanup', 'auth_delete']);
    });

    test('deletes auth account last', () async {
      final callOrder = <String>[];
      when(() => mockAuthService.reauthenticate()).thenAnswer((_) async {
        callOrder.add('reauth');
      });
      when(() => mockProfileService.deleteProfile(any())).thenAnswer((_) async {
        callOrder.add('firestore_delete');
      });
      when(() => mockAuthService.deleteAccount()).thenAnswer((_) async {
        callOrder.add('auth_delete');
      });

      final container = createContainer(
        authState: AsyncValue.data(mockUser),
      );
      await container.read(deleteAccountProvider.future);

      expect(callOrder, ['reauth', 'firestore_delete', 'auth_delete']);
    });

    test('does nothing when user is null', () async {
      final container = createContainer(
        authState: const AsyncValue.data(null),
      );
      await container.read(deleteAccountProvider.future);

      verifyNever(() => mockAuthService.reauthenticate());
      verifyNever(() => mockProfileService.deleteProfile(any()));
      verifyNever(() => mockAuthService.deleteAccount());
    });

    test('propagates reauthenticate errors without deleting anything', () async {
      when(() => mockAuthService.reauthenticate())
          .thenThrow(FirebaseAuthException(code: 'requires-recent-login'));

      final container = createContainer(
        authState: AsyncValue.data(mockUser),
      );

      // Listen to keep the autoDispose provider alive during the async operation
      final sub = container.listen(deleteAccountProvider, (_, __) {});
      await Future<void>.delayed(Duration.zero);
      final state = container.read(deleteAccountProvider);
      expect(state.hasError, true);
      expect(state.error, isA<FirebaseAuthException>());
      sub.close();

      verifyNever(() => mockProfileService.deleteProfile(any()));
      verifyNever(() => mockAuthService.deleteAccount());
    });
  });
}
