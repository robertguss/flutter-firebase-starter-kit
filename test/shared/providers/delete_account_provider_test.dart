import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/features/auth/services/auth_service.dart';
import 'package:flutter_starter_kit/features/auth/services/user_profile_service.dart';
import 'package:flutter_starter_kit/features/notifications/providers/notification_provider.dart';
import 'package:flutter_starter_kit/features/notifications/services/fcm_service.dart';
import 'package:flutter_starter_kit/features/paywall/providers/purchases_provider.dart';
import 'package:flutter_starter_kit/features/paywall/services/purchases_service.dart';
import 'package:flutter_starter_kit/shared/providers/delete_account_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements User {}

class MockUserProfileService extends Mock implements UserProfileService {}

class MockPurchasesService extends Mock implements PurchasesService {}

class MockFcmService extends Mock implements FcmService {}

void main() {
  late MockAuthService mockAuthService;
  late MockUserProfileService mockProfileService;
  late MockPurchasesService mockPurchasesService;
  late MockFcmService mockFcmService;
  late MockUser mockUser;
  late ProviderContainer container;

  setUp(() {
    mockAuthService = MockAuthService();
    mockProfileService = MockUserProfileService();
    mockPurchasesService = MockPurchasesService();
    mockFcmService = MockFcmService();
    mockUser = MockUser();

    when(() => mockUser.uid).thenReturn('uid-1');
    when(() => mockAuthService.authStateChanges)
        .thenAnswer((_) => Stream.value(mockUser));
    when(() => mockAuthService.reauthenticate()).thenAnswer((_) async {});
    when(() => mockAuthService.deleteAccount()).thenAnswer((_) async {});
    when(() => mockProfileService.deleteProfile(any()))
        .thenAnswer((_) async {});
    when(() => mockPurchasesService.logout()).thenAnswer((_) async {});
  });

  tearDown(() {
    container.dispose();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
        userProfileServiceProvider.overrideWithValue(mockProfileService),
        purchasesServiceProvider.overrideWithValue(mockPurchasesService),
        fcmServiceProvider.overrideWithValue(mockFcmService),
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
      // Track call order to verify Firestore delete happens before auth delete
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

    test('calls RevenueCat logout before auth delete', () async {
      final callOrder = <String>[];
      when(() => mockPurchasesService.logout()).thenAnswer((_) async {
        callOrder.add('rc_logout');
      });
      when(() => mockAuthService.deleteAccount()).thenAnswer((_) async {
        callOrder.add('auth_delete');
      });

      container = createContainer();
      await container.read(authStateProvider.future);
      await container.read(deleteAccountProvider.future);

      expect(callOrder, ['rc_logout', 'auth_delete']);
    });

    test('deletes auth account last', () async {
      final callOrder = <String>[];
      when(() => mockAuthService.reauthenticate()).thenAnswer((_) async {
        callOrder.add('reauth');
      });
      when(() => mockProfileService.deleteProfile(any())).thenAnswer((_) async {
        callOrder.add('firestore_delete');
      });
      when(() => mockPurchasesService.logout()).thenAnswer((_) async {
        callOrder.add('rc_logout');
      });
      when(() => mockAuthService.deleteAccount()).thenAnswer((_) async {
        callOrder.add('auth_delete');
      });

      container = createContainer();
      await container.read(authStateProvider.future);
      await container.read(deleteAccountProvider.future);

      expect(callOrder, ['reauth', 'firestore_delete', 'rc_logout', 'auth_delete']);
    });

    test('does nothing when user is null', () async {
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(null));

      container = createContainer();
      await container.read(authStateProvider.future);
      await container.read(deleteAccountProvider.future);

      verifyNever(() => mockAuthService.reauthenticate());
      verifyNever(() => mockProfileService.deleteProfile(any()));
      verifyNever(() => mockPurchasesService.logout());
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
