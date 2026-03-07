import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements User {}

void main() {
  late MockAuthService mockAuthService;
  late ProviderContainer container;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  tearDown(() {
    container.dispose();
  });

  group('authStateProvider', () {
    test('emits null when user is not authenticated', () async {
      when(
        () => mockAuthService.authStateChanges,
      ).thenAnswer((_) => Stream.value(null));

      container = ProviderContainer(
        overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
      );

      final state = container.read(authStateProvider);
      expect(state, const AsyncValue<User?>.loading());
    });

    test('emits user when authenticated', () async {
      final mockUser = MockUser();
      when(
        () => mockAuthService.authStateChanges,
      ).thenAnswer((_) => Stream.value(mockUser));

      container = ProviderContainer(
        overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
      );

      await container.read(authStateProvider.future);
      final state = container.read(authStateProvider);
      expect(state.value, mockUser);
    });
  });
}
