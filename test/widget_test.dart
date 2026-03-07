import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/app.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/services/auth_service.dart';
import 'package:flutter_starter_kit/shared/providers/shared_preferences_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  testWidgets('renders the auth screen shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final mockAuthService = MockAuthService();
    when(
      () => mockAuthService.authStateChanges,
    ).thenAnswer((_) => Stream.value(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Starter Kit'), findsOneWidget);
    expect(find.text('Sign in to get started'), findsOneWidget);
  });
}
