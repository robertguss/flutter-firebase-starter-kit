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
import 'package:flutter_starter_kit/shared/providers/sign_out_provider.dart';
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
  late ProviderContainer container;

  setUp(() {
    mockAuthService = MockAuthService();
    mockProfileService = MockUserProfileService();
    mockPurchasesService = MockPurchasesService();
    mockFcmService = MockFcmService();
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
      when(() => mockPurchasesService.logout()).thenAnswer((_) async {});
      when(() => mockAuthService.signOut()).thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          userProfileServiceProvider.overrideWithValue(mockProfileService),
          purchasesServiceProvider.overrideWithValue(mockPurchasesService),
          fcmServiceProvider.overrideWithValue(mockFcmService),
        ],
      );

      await container.read(authStateProvider.future);
      await container.read(signOutProvider.future);

      verify(() => mockProfileService.clearFcmToken('uid-1')).called(1);
    });

    test('calls RevenueCat logout before sign-out', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-1');
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));
      when(() => mockProfileService.clearFcmToken(any()))
          .thenAnswer((_) async {});
      when(() => mockPurchasesService.logout()).thenAnswer((_) async {});
      when(() => mockAuthService.signOut()).thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          userProfileServiceProvider.overrideWithValue(mockProfileService),
          purchasesServiceProvider.overrideWithValue(mockPurchasesService),
          fcmServiceProvider.overrideWithValue(mockFcmService),
        ],
      );

      await container.read(authStateProvider.future);
      await container.read(signOutProvider.future);

      verify(() => mockPurchasesService.logout()).called(1);
    });

    test('calls auth signOut last', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-1');
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));
      when(() => mockProfileService.clearFcmToken(any()))
          .thenAnswer((_) async {});
      when(() => mockPurchasesService.logout()).thenAnswer((_) async {});
      when(() => mockAuthService.signOut()).thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          userProfileServiceProvider.overrideWithValue(mockProfileService),
          purchasesServiceProvider.overrideWithValue(mockPurchasesService),
          fcmServiceProvider.overrideWithValue(mockFcmService),
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
          purchasesServiceProvider.overrideWithValue(mockPurchasesService),
          fcmServiceProvider.overrideWithValue(mockFcmService),
        ],
      );

      await container.read(authStateProvider.future);
      await container.read(signOutProvider.future);

      verifyNever(() => mockProfileService.clearFcmToken(any()));
      verifyNever(() => mockPurchasesService.logout());
      verifyNever(() => mockAuthService.signOut());
    });
  });
}
