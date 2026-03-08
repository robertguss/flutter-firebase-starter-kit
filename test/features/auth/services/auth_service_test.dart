import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_starter_kit/features/auth/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

class _FakeAuthCredential extends Fake implements AuthCredential {}

class _FakeAuthProvider extends Fake implements AuthProvider {}

void main() {
  late AuthService authService;
  late MockFirebaseAuth mockAuth;
  late MockGoogleSignIn mockGoogleSignIn;

  setUpAll(() {
    registerFallbackValue(_FakeAuthCredential());
    registerFallbackValue(_FakeAuthProvider());
  });

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
    authService = AuthService(
      firebaseAuth: mockAuth,
      googleSignIn: mockGoogleSignIn,
    );
  });

  group('AuthService', () {
    test('signOut calls FirebaseAuth.signOut', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await authService.signOut();

      verify(() => mockAuth.signOut()).called(1);
    });

    test('currentUser returns FirebaseAuth.currentUser', () {
      final mockUser = MockUser();
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final user = authService.currentUser;

      expect(user, mockUser);
    });

    test('authStateChanges returns FirebaseAuth stream', () {
      final mockUser = MockUser();
      when(
        () => mockAuth.authStateChanges(),
      ).thenAnswer((_) => Stream.value(mockUser));

      final stream = authService.authStateChanges;

      expect(stream, emits(mockUser));
    });

    test('deleteAccount calls user.delete', () async {
      final mockUser = MockUser();
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.delete()).thenAnswer((_) async {});

      await authService.deleteAccount();

      verify(() => mockUser.delete()).called(1);
    });

    test('deleteAccount does nothing when no current user', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      // Should complete without error when user is null
      await authService.deleteAccount();
    });

    test('signOut throws when FirebaseAuth.signOut fails', () async {
      when(() => mockAuth.signOut()).thenThrow(
        FirebaseAuthException(
          code: 'network-request-failed',
          message: 'A network error occurred.',
        ),
      );

      expect(
        () => authService.signOut(),
        throwsA(isA<FirebaseAuthException>().having(
          (e) => e.code,
          'code',
          'network-request-failed',
        )),
      );
    });

    test('deleteAccount throws when user.delete requires recent login',
        () async {
      final mockUser = MockUser();
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.delete()).thenThrow(
        FirebaseAuthException(
          code: 'requires-recent-login',
          message: 'This operation requires recent authentication.',
        ),
      );

      expect(
        () => authService.deleteAccount(),
        throwsA(isA<FirebaseAuthException>().having(
          (e) => e.code,
          'code',
          'requires-recent-login',
        )),
      );
    });

    group('signInWithGoogle', () {
      test('successful sign-in returns UserCredential', () async {
        final mockAccount = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication();
        final mockCredential = MockUserCredential();

        when(() => mockGoogleSignIn.signIn())
            .thenAnswer((_) async => mockAccount);
        when(() => mockAccount.authentication)
            .thenAnswer((_) async => mockGoogleAuth);
        when(() => mockGoogleAuth.accessToken).thenReturn('access-token');
        when(() => mockGoogleAuth.idToken).thenReturn('id-token');
        when(() => mockAuth.signInWithCredential(any()))
            .thenAnswer((_) async => mockCredential);

        final result = await authService.signInWithGoogle();

        expect(result, mockCredential);
        verify(() => mockAuth.signInWithCredential(any())).called(1);
      });

      test('cancelled sign-in throws exception', () async {
        when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

        expect(
          () => authService.signInWithGoogle(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('cancelled'),
          )),
        );
      });

      test('network error propagates', () async {
        when(() => mockGoogleSignIn.signIn()).thenThrow(
          FirebaseAuthException(
            code: 'network-request-failed',
            message: 'Network error',
          ),
        );

        expect(
          () => authService.signInWithGoogle(),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('signInWithApple', () {
      test('successful sign-in returns UserCredential', () async {
        final mockCredential = MockUserCredential();
        when(() => mockAuth.signInWithProvider(any()))
            .thenAnswer((_) async => mockCredential);

        final result = await authService.signInWithApple();

        expect(result, mockCredential);
        verify(() => mockAuth.signInWithProvider(any())).called(1);
      });

      test('error propagates', () async {
        when(() => mockAuth.signInWithProvider(any())).thenThrow(
          FirebaseAuthException(
            code: 'network-request-failed',
            message: 'Network error',
          ),
        );

        expect(
          () => authService.signInWithApple(),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });
  });
}
