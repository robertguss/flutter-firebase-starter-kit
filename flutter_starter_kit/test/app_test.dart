import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  testWidgets('App renders auth screen when not logged in', (tester) async {
    final mockAuthService = MockAuthService();
    when(
      () => mockAuthService.authStateChanges,
    ).thenAnswer((_) => Stream.value(null));

    final container = ProviderContainer(
      overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
    );

    final authState = await container.read(authStateProvider.future);
    expect(authState, isNull);

    container.dispose();
  });
}
