import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/models/user_profile.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/features/auth/services/user_profile_service.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockAuthService mockAuthService;
  late MockUserProfileService mockProfileService;

  setUp(() {
    mockAuthService = MockAuthService();
    mockProfileService = MockUserProfileService();
  });

  group('userProfileServiceProvider', () {
    test('provides a UserProfileService instance', () {
      final container = ProviderContainer.test(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          authStateProvider.overrideWithValue(const AsyncValue.data(null)),
          userProfileServiceProvider.overrideWithValue(mockProfileService),
        ],
      );

      final service = container.read(userProfileServiceProvider);
      expect(service, isA<UserProfileService>());
    });
  });

  group('userProfileProvider', () {
    test('emits null when user is not authenticated', () async {
      final container = ProviderContainer.test(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          authStateProvider.overrideWithValue(const AsyncValue.data(null)),
          userProfileServiceProvider.overrideWithValue(mockProfileService),
        ],
      );

      final profile = container.read(userProfileProvider).value;
      expect(profile, isNull);
    });

    test('emits UserProfile when user is authenticated', () async {
      final expectedProfile = UserProfile(
        uid: 'uid-1',
        email: 'test@example.com',
        createdAt: DateTime(2026, 1, 1),
      );

      final container = ProviderContainer.test(
        overrides: [
          userProfileProvider
              .overrideWithValue(AsyncValue.data(expectedProfile)),
        ],
      );

      final profile = await container.read(userProfileProvider.future);
      expect(profile, isNotNull);
      expect(profile!.uid, 'uid-1');
      expect(profile.email, 'test@example.com');
    });
  });
}
