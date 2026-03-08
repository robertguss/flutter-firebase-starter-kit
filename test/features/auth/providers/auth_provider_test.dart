import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/mocks.dart';

void main() {
  group('authStateProvider', () {
    test('emits null when user is not authenticated', () async {
      final container = ProviderContainer.test(
        overrides: [
          authStateProvider.overrideWithValue(const AsyncValue.data(null)),
        ],
      );

      final user = await container.read(authStateProvider.future);
      expect(user, isNull);
    });

    test('emits user when authenticated', () async {
      final mockUser = MockUser();
      final container = ProviderContainer.test(
        overrides: [
          authStateProvider.overrideWithValue(AsyncValue.data(mockUser)),
        ],
      );

      await container.read(authStateProvider.future);
      final state = container.read(authStateProvider);
      expect(state.value, mockUser);
    });
  });
}
