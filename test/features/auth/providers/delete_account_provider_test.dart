import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/features/auth/services/auth_service.dart';
import 'package:flutter_starter_kit/features/auth/services/user_profile_service.dart';
import 'package:flutter_starter_kit/shared/providers/feature_hooks.dart';
import 'package:flutter_starter_kit/features/auth/providers/delete_account_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements User {}

class MockUserProfileService extends Mock implements UserProfileService {}

void main() {
  late MockAuthService mockAuthService;
  late MockUserProfileService mockProfileService;
  late MockUser mockUser;
  late ProviderContainer container;

  setUp(() {
    mockAuthService = MockAuthService();
    mockProfileService = MockUserProfileService();
    mockUser = MockUser();

    when(() => mockUser.uid).thenReturn('uid-1');
    when(() => mockAuthService.authStateChanges)
        .thenAnswer((_) => Stream.value(mockUser));
    when(() => mockAuthService.reauthenticate()).thenAnswer((_) async {});
    when(() => mockAuthService.deleteAccount()).thenAnswer((_) async {});
    when(() => mockProfileService.deleteProfile(any()))
        .thenAnswer((_) async {});
  });

  tearDown(() {
    container.dispose();
  });

  ProviderContainer createContainer({List<FeatureHook>? deleteHooks}) {
    return ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
        userProfileServiceProvider.overrideWithValue(mockProfileService),
        if (deleteHooks != null)
          deleteAccountHooksProvider.overrideWithValue(deleteHooks),
      ],
    );
  }

  group('deleteAccountProvider', () {
    test('calls reauthenticate first', () async {
      container = createContainer();
      await container.read(authStateProvider.future);
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

      container = createContainer();
      await container.read(authStateProvider.future);
      await container.read(deleteAccountProvider.future);

      expect(callOrder, ['firestore_delete', 'auth_delete']);
    });

    test('runs delete account hooks before auth delete', () async {
      final callOrder = <String>[];
      when(() => mockAuthService.deleteAccount()).thenAnswer((_) async {
        callOrder.add('auth_delete');
      });

      container = createContainer(deleteHooks: [
        (ref, uid) async {
          callOrder.add('hook_cleanup');
        },
      ]);
      await container.read(authStateProvider.future);
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

      container = createContainer();
      await container.read(authStateProvider.future);
      await container.read(deleteAccountProvider.future);

      expect(callOrder, ['reauth', 'firestore_delete', 'auth_delete']);
    });

    test('does nothing when user is null', () async {
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(null));

      container = createContainer();
      await container.read(authStateProvider.future);
      await container.read(deleteAccountProvider.future);

      verifyNever(() => mockAuthService.reauthenticate());
      verifyNever(() => mockProfileService.deleteProfile(any()));
      verifyNever(() => mockAuthService.deleteAccount());
    });

    test('propagates reauthenticate errors without deleting anything', () async {
      when(() => mockAuthService.reauthenticate())
          .thenThrow(FirebaseAuthException(code: 'requires-recent-login'));

      container = createContainer();
      await container.read(authStateProvider.future);

      expect(
        () => container.read(deleteAccountProvider.future),
        throwsA(isA<FirebaseAuthException>()),
      );

      verifyNever(() => mockProfileService.deleteProfile(any()));
      verifyNever(() => mockAuthService.deleteAccount());
    });
  });
}
