import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/app.dart';
import 'package:flutter_starter_kit/features/auth/models/user_profile.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/features/auth/services/auth_service.dart';
import 'package:flutter_starter_kit/features/auth/services/user_profile_service.dart';
import 'package:flutter_starter_kit/shared/providers/feature_hooks.dart';
import 'package:flutter_starter_kit/shared/providers/shared_preferences_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements User {}

class MockUserProfileService extends Mock implements UserProfileService {}

class MockUserCredential extends Mock implements UserCredential {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService mockAuthService;
  late MockUserProfileService mockProfileService;
  late StreamController<User?> authController;

  setUp(() async {
    mockAuthService = MockAuthService();
    mockProfileService = MockUserProfileService();
    authController = StreamController<User?>.broadcast();

    when(() => mockAuthService.authStateChanges)
        .thenAnswer((_) => authController.stream);

    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await authController.close();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          userProfileServiceProvider.overrideWithValue(mockProfileService),
          sharedPreferencesProvider.overrideWithValue(prefs),
          bootstrapHooksProvider.overrideWithValue([]),
          signOutHooksProvider.overrideWithValue([]),
          deleteAccountHooksProvider.overrideWithValue([]),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Full app flow', () {
    testWidgets('unauthenticated user sees auth screen', (tester) async {
      // Start unauthenticated
      authController.add(null);

      await pumpApp(tester);

      // Auth screen should be displayed
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
    });

    testWidgets(
      'sign in -> onboarding -> complete -> home',
      (tester) async {
        // Start unauthenticated
        authController.add(null);

        await pumpApp(tester);

        // Verify auth screen
        expect(find.text('Continue with Google'), findsOneWidget);

        // Simulate sign-in: emit authenticated user
        final mockUser = MockUser();
        when(() => mockUser.uid).thenReturn('test-uid');
        when(() => mockUser.email).thenReturn('test@example.com');
        when(() => mockUser.displayName).thenReturn('Test User');
        when(() => mockUser.photoURL).thenReturn(null);
        when(() => mockUser.providerData).thenReturn([]);
        when(() => mockAuthService.signInWithGoogle())
            .thenAnswer((_) async {
          authController.add(mockUser);
          return MockUserCredential();
        });

        // Set up profile service to return incomplete onboarding
        final incompleteProfile = UserProfile(
          uid: 'test-uid',
          email: 'test@example.com',
          displayName: 'Test User',
          onboardingComplete: false,
          createdAt: DateTime(2026, 1, 1),
        );
        when(() => mockProfileService.getProfile(any()))
            .thenAnswer((_) async => null);
        when(() => mockProfileService.createOrUpdateProfile(any(), any()))
            .thenAnswer((_) async {});
        when(() => mockProfileService.profileStream(any()))
            .thenAnswer((_) => Stream.value(incompleteProfile));

        // Tap sign in
        await tester.tap(find.text('Continue with Google'));
        await tester.pumpAndSettle();

        // Should be on onboarding screen (first page shows "Welcome")
        expect(find.textContaining('Welcome'), findsOneWidget);

        // Navigate through onboarding pages
        // Page 1 -> Page 2
        await tester.tap(find.widgetWithText(FilledButton, 'Next'));
        await tester.pumpAndSettle();

        // Page 2 -> Page 3
        await tester.tap(find.widgetWithText(FilledButton, 'Next'));
        await tester.pumpAndSettle();

        // Page 3: "Get Started" button
        expect(find.widgetWithText(FilledButton, 'Get Started'), findsOneWidget);

        // Complete onboarding — update profile to onboardingComplete: true
        final completeProfile = UserProfile(
          uid: 'test-uid',
          email: 'test@example.com',
          displayName: 'Test User',
          onboardingComplete: true,
          createdAt: DateTime(2026, 1, 1),
        );
        when(() => mockProfileService.markOnboardingComplete(any()))
            .thenAnswer((_) async {});
        when(() => mockProfileService.profileStream(any()))
            .thenAnswer((_) => Stream.value(completeProfile));

        await tester.tap(find.widgetWithText(FilledButton, 'Get Started'));
        await tester.pumpAndSettle();

        // Should now be on home screen
        expect(find.text('Home'), findsWidgets);
      },
    );
  });
}
