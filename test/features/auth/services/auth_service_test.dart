import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_starter_kit/features/auth/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  late AuthService authService;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    authService = AuthService(firebaseAuth: mockAuth);
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
  });
}
