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
import 'package:flutter_starter_kit/shared/providers/post_auth_bootstrap_provider.dart';
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

  group('postAuthBootstrapProvider', () {
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
      await container.read(postAuthBootstrapProvider.future);

      verifyNever(() => mockProfileService.createOrUpdateProfile(any(), any()));
    });

    test('creates profile on sign-in', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-1');
      when(() => mockUser.email).thenReturn('test@example.com');
      when(() => mockUser.displayName).thenReturn('Test User');
      when(() => mockUser.photoURL).thenReturn(null);
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));
      when(() => mockProfileService.createOrUpdateProfile(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockPurchasesService.login(any()))
          .thenAnswer((_) async {});
      when(() => mockFcmService.getToken())
          .thenAnswer((_) async => 'fcm-token');
      when(() => mockProfileService.updateFcmToken(any(), any()))
          .thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          userProfileServiceProvider.overrideWithValue(mockProfileService),
          purchasesServiceProvider.overrideWithValue(mockPurchasesService),
          fcmServiceProvider.overrideWithValue(mockFcmService),
        ],
      );

      await container.read(authStateProvider.future);
      await container.read(postAuthBootstrapProvider.future);

      verify(() => mockProfileService.createOrUpdateProfile(
            'uid-1',
            any(that: containsPair('email', 'test@example.com')),
          )).called(1);
    });

    test('calls RevenueCat login on sign-in', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-1');
      when(() => mockUser.email).thenReturn('test@example.com');
      when(() => mockUser.displayName).thenReturn('Test');
      when(() => mockUser.photoURL).thenReturn(null);
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));
      when(() => mockProfileService.createOrUpdateProfile(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockPurchasesService.login(any()))
          .thenAnswer((_) async {});
      when(() => mockFcmService.getToken())
          .thenAnswer((_) async => 'token');
      when(() => mockProfileService.updateFcmToken(any(), any()))
          .thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          userProfileServiceProvider.overrideWithValue(mockProfileService),
          purchasesServiceProvider.overrideWithValue(mockPurchasesService),
          fcmServiceProvider.overrideWithValue(mockFcmService),
        ],
      );

      await container.read(authStateProvider.future);
      await container.read(postAuthBootstrapProvider.future);

      verify(() => mockPurchasesService.login('uid-1')).called(1);
    });

    test('saves FCM token on sign-in', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-1');
      when(() => mockUser.email).thenReturn('test@example.com');
      when(() => mockUser.displayName).thenReturn('Test');
      when(() => mockUser.photoURL).thenReturn(null);
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));
      when(() => mockProfileService.createOrUpdateProfile(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockPurchasesService.login(any()))
          .thenAnswer((_) async {});
      when(() => mockFcmService.getToken())
          .thenAnswer((_) async => 'fcm-token-123');
      when(() => mockProfileService.updateFcmToken(any(), any()))
          .thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          userProfileServiceProvider.overrideWithValue(mockProfileService),
          purchasesServiceProvider.overrideWithValue(mockPurchasesService),
          fcmServiceProvider.overrideWithValue(mockFcmService),
        ],
      );

      await container.read(authStateProvider.future);
      await container.read(postAuthBootstrapProvider.future);

      verify(() => mockProfileService.updateFcmToken('uid-1', 'fcm-token-123'))
          .called(1);
    });
  });
}
