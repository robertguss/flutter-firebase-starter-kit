import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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

    test('stream wiring: authState reflects authService.authStateChanges', () async {
      final mockUser = MockUser();
      final completer = Completer<User?>();
      final mockService = MockAuthService();
      when(() => mockService.authStateChanges).thenAnswer(
        (_) => Stream.value(mockUser),
      );

      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // Listen to force the provider to subscribe to the stream
      container.listen(authStateProvider, (prev, next) {
        final value = next.value;
        if (!completer.isCompleted && next is AsyncData) {
          completer.complete(value);
        }
      });

      final user = await completer.future;
      expect(user, mockUser);
    });
  });
}
