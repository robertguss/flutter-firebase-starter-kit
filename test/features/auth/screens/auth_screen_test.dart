import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/screens/auth_screen.dart';
import 'package:flutter_starter_kit/features/auth/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUserCredential extends Mock implements UserCredential {}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  Widget createApp() {
    return ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
      ],
      child: const MaterialApp(home: AuthScreen()),
    );
  }

  group('AuthScreen error sanitization', () {
    testWidgets('shows friendly message for FirebaseAuthException', (
      tester,
    ) async {
      when(() => mockAuthService.signInWithGoogle()).thenThrow(
        FirebaseAuthException(
          code: 'account-exists-with-different-credential',
          message: 'internal details that should not be shown',
        ),
      );

      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      // Should show user-friendly message, not raw exception
      expect(find.text('Authentication error. Please try again.'), findsOneWidget);
      expect(
        find.text('internal details that should not be shown'),
        findsNothing,
      );
    });

    testWidgets('shows friendly message for PlatformException', (
      tester,
    ) async {
      when(() => mockAuthService.signInWithGoogle()).thenThrow(
        PlatformException(
          code: 'sign_in_failed',
          message: 'com.google.android.gms internal error',
        ),
      );

      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
      expect(
        find.text('com.google.android.gms internal error'),
        findsNothing,
      );
    });

    testWidgets('shows friendly message for generic exceptions', (
      tester,
    ) async {
      when(
        () => mockAuthService.signInWithGoogle(),
      ).thenThrow(Exception('socket connection refused'));

      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('socket connection refused'), findsNothing);
    });

    testWidgets('shows cancellation message when sign-in cancelled', (
      tester,
    ) async {
      when(
        () => mockAuthService.signInWithGoogle(),
      ).thenThrow(Exception('Google sign-in was cancelled'));

      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      // Cancelled sign-in should show a friendly message, not raw exception
      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('does not expose error.toString() to user', (tester) async {
      when(
        () => mockAuthService.signInWithGoogle(),
      ).thenThrow(Exception('Exception: internal stack trace details'));

      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      // Should never show raw Exception text
      expect(
        find.textContaining('Exception:'),
        findsNothing,
      );
    });
  });
}
