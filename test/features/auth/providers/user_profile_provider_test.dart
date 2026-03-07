import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/models/user_profile.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/features/auth/services/auth_service.dart';
import 'package:flutter_starter_kit/features/auth/services/user_profile_service.dart';
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

  group('userProfileServiceProvider', () {
    test('provides a UserProfileService instance', () {
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(null));

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          userProfileServiceProvider
              .overrideWithValue(mockProfileService),
        ],
      );

      final service = container.read(userProfileServiceProvider);
      expect(service, isA<UserProfileService>());
    });
  });

  group('userProfileProvider', () {
    test('emits null when user is not authenticated', () async {
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(null));

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          userProfileServiceProvider
              .overrideWithValue(mockProfileService),
        ],
      );

      await container.read(authStateProvider.future);
      final profile = container.read(userProfileProvider).valueOrNull;
      expect(profile, isNull);
    });

    test('emits UserProfile when user is authenticated', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-1');
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));

      final expectedProfile = UserProfile(
        uid: 'uid-1',
        email: 'test@example.com',
        createdAt: DateTime(2026, 1, 1),
      );
      when(() => mockProfileService.profileStream('uid-1'))
          .thenAnswer((_) => Stream.value(expectedProfile));

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          userProfileServiceProvider
              .overrideWithValue(mockProfileService),
        ],
      );

      await container.read(authStateProvider.future);
      final profile = await container.read(userProfileProvider.future);
      expect(profile, isNotNull);
      expect(profile!.uid, 'uid-1');
      expect(profile.email, 'test@example.com');
    });
  });
}
