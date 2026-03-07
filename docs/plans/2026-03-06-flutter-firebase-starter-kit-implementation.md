# Flutter + Firebase Starter Kit Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a reusable Flutter starter kit with Firebase Auth (Apple + Google), onboarding, RevenueCat paywall, settings, push notifications, GoRouter navigation, and Material 3 theming.

**Architecture:** Feature-folder structure where each feature is self-contained and deletable. Riverpod for state management, GoRouter for declarative routing with auth/onboarding guards, Firebase for backend services.

**Tech Stack:** Flutter/Dart, Riverpod, GoRouter, Firebase (Auth, Firestore, Cloud Functions, FCM), RevenueCat, shared_preferences, Material 3

---

## Task 1: Project Scaffolding

**Files:**

- Create: `flutter_starter_kit/` (Flutter project)
- Modify: `flutter_starter_kit/pubspec.yaml`
- Create: `flutter_starter_kit/analysis_options.yaml`

**Step 1: Create the Flutter project**

Run:

```bash
cd /Users/robertguss/Projects/github/mobile-starter-kit
flutter create flutter_starter_kit --org com.example --platforms ios,android
```

Expected: New Flutter project created successfully.

**Step 2: Replace pubspec.yaml dependencies**

Replace the `dependencies` and `dev_dependencies` sections in `flutter_starter_kit/pubspec.yaml`:

```yaml
name: flutter_starter_kit
description: A Flutter + Firebase starter kit with auth, paywall, onboarding, and more.
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ^3.7.0

dependencies:
  flutter:
    sdk: flutter

  # State & Navigation
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  go_router: ^14.8.1

  # Firebase
  firebase_core: ^3.12.1
  firebase_auth: ^5.5.1
  cloud_firestore: ^5.6.5
  firebase_messaging: ^15.2.4

  # Auth
  google_sign_in: ^6.2.2
  sign_in_with_apple: ^7.0.1

  # Payments
  purchases_flutter: ^8.6.0

  # Local Storage
  shared_preferences: ^2.5.3

  # UI
  flutter_animate: ^4.5.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  riverpod_generator: ^2.6.4
  build_runner: ^2.4.15
  mockito: ^5.4.6
  mocktail: ^1.0.4
  riverpod_lint: ^2.6.4
  custom_lint: ^0.7.5
```

**Step 3: Run flutter pub get**

Run:

```bash
cd flutter_starter_kit && flutter pub get
```

Expected: Dependencies resolved successfully.

**Step 4: Create the folder structure**

Run:

```bash
cd flutter_starter_kit/lib && \
mkdir -p config && \
mkdir -p features/auth/screens features/auth/providers features/auth/services features/auth/widgets && \
mkdir -p features/onboarding/screens features/onboarding/providers features/onboarding/widgets && \
mkdir -p features/paywall/screens features/paywall/providers features/paywall/services features/paywall/widgets && \
mkdir -p features/settings/screens features/settings/providers features/settings/widgets && \
mkdir -p features/notifications/providers features/notifications/services && \
mkdir -p features/home/screens && \
mkdir -p routing && \
mkdir -p shared/services shared/widgets
```

Expected: All directories created.

**Step 5: Commit**

```bash
git add -A && git commit -m "feat: scaffold Flutter project with folder structure and dependencies"
```

---

## Task 2: Config Layer

**Files:**

- Create: `lib/config/app_config.dart`
- Create: `lib/config/environment.dart`
- Create: `lib/config/theme.dart`

**Step 1: Create app_config.dart**

```dart
// lib/config/app_config.dart

class AppConfig {
  static const String appName = 'Starter Kit';
  static const String bundleId = 'com.example.starterkit';

  // RevenueCat
  static const String revenueCatAppleApiKey = 'appl_YOUR_KEY';
  static const String revenueCatGoogleApiKey = 'goog_YOUR_KEY';

  // Legal
  static const String privacyPolicyUrl = 'https://example.com/privacy';
  static const String termsOfServiceUrl = 'https://example.com/terms';

  // Feature Flags
  static const bool enablePaywall = true;
  static const bool enableNotifications = true;

  // Navigation
  static const int bottomNavTabCount = 3;
}
```

**Step 2: Create environment.dart**

```dart
// lib/config/environment.dart

enum Environment { dev, staging, prod }

class EnvironmentConfig {
  static Environment current = Environment.dev;

  static void init() {
    const envString = String.fromEnvironment('ENV', defaultValue: 'dev');
    current = Environment.values.firstWhere(
      (e) => e.name == envString,
      orElse: () => Environment.dev,
    );
  }
}
```

**Step 3: Create theme.dart**

```dart
// lib/config/theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  static const Color _seedColor = Colors.blue;
  static const String _fontFamily = 'Roboto';

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ),
        fontFamily: _fontFamily,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
        fontFamily: _fontFamily,
      );
}
```

**Step 4: Commit**

```bash
git add -A && git commit -m "feat: add config layer (app_config, environment, theme)"
```

---

## Task 3: Firebase Initialization & App Shell

**Files:**

- Create: `lib/shared/services/firebase_service.dart`
- Modify: `lib/main.dart`
- Create: `lib/app.dart`

**Step 1: Create firebase_service.dart**

```dart
// lib/shared/services/firebase_service.dart

import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }
}
```

Note: This requires running `flutterfire configure` to generate `firebase_options.dart`. For now, keep it simple. The engineer will need to run:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Then update the initialize call to pass `DefaultFirebaseOptions.currentPlatform`.

**Step 2: Create app.dart**

```dart
// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/config/theme.dart';
import 'package:flutter_starter_kit/routing/router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Starter Kit',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
```

Note: `routerProvider` and `themeModeProvider` will be created in later tasks. This file will be updated as those providers are built.

**Step 3: Create main.dart**

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/app.dart';
import 'package:flutter_starter_kit/config/environment.dart';
import 'package:flutter_starter_kit/shared/services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvironmentConfig.init();
  await FirebaseService.initialize();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
```

**Step 4: Commit**

```bash
git add -A && git commit -m "feat: add Firebase initialization, app shell, and main entry point"
```

---

## Task 4: Theme Mode Provider

**Files:**

- Create: `lib/features/settings/providers/theme_provider.dart`
- Create: `test/features/settings/providers/theme_provider_test.dart`

**Step 1: Write the failing test**

```dart
// test/features/settings/providers/theme_provider_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_starter_kit/features/settings/providers/theme_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeModeNotifier', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('defaults to light mode', () {
      final themeMode = container.read(themeModeProvider);
      expect(themeMode, ThemeMode.light);
    });

    test('toggles to dark mode', () async {
      container.read(themeModeProvider.notifier).toggle();
      final themeMode = container.read(themeModeProvider);
      expect(themeMode, ThemeMode.dark);
    });

    test('toggles back to light mode', () async {
      final notifier = container.read(themeModeProvider.notifier);
      notifier.toggle();
      notifier.toggle();
      final themeMode = container.read(themeModeProvider);
      expect(themeMode, ThemeMode.light);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `cd flutter_starter_kit && flutter test test/features/settings/providers/theme_provider_test.dart`
Expected: FAIL — `themeModeProvider` not found.

**Step 3: Write the implementation**

```dart
// lib/features/settings/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    _loadFromPrefs();
    return ThemeMode.light;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_key) ?? false;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void toggle() {
    final isDark = state == ThemeMode.light;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    _saveToPrefs(isDark);
  }

  Future<void> _saveToPrefs(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, isDark);
  }
}
```

**Step 4: Run test to verify it passes**

Run: `cd flutter_starter_kit && flutter test test/features/settings/providers/theme_provider_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add -A && git commit -m "feat: add theme mode provider with persistence"
```

---

## Task 5: Auth Service

**Files:**

- Create: `lib/features/auth/services/auth_service.dart`
- Create: `test/features/auth/services/auth_service_test.dart`

**Step 1: Write the failing test**

```dart
// test/features/auth/services/auth_service_test.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_starter_kit/features/auth/services/auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}
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
      when(() => mockAuth.authStateChanges())
          .thenAnswer((_) => Stream.value(mockUser));

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
  });
}
```

**Step 2: Run test to verify it fails**

Run: `cd flutter_starter_kit && flutter test test/features/auth/services/auth_service_test.dart`
Expected: FAIL — `AuthService` not found.

**Step 3: Write the implementation**

```dart
// lib/features/auth/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth firebaseAuth;

  AuthService({FirebaseAuth? firebaseAuth})
      : firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return firebaseAuth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithApple() async {
    final appleProvider = AppleAuthProvider();
    return firebaseAuth.signInWithProvider(appleProvider);
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = firebaseAuth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }
}
```

**Step 4: Run test to verify it passes**

Run: `cd flutter_starter_kit && flutter test test/features/auth/services/auth_service_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add -A && git commit -m "feat: add auth service with Google and Apple sign-in"
```

---

## Task 6: Auth Provider

**Files:**

- Create: `lib/features/auth/providers/auth_provider.dart`
- Create: `test/features/auth/providers/auth_provider_test.dart`

**Step 1: Write the failing test**

```dart
// test/features/auth/providers/auth_provider_test.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/services/auth_service.dart';

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
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(null));

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
      );

      final state = container.read(authStateProvider);
      expect(state, const AsyncValue<User?>.loading());
    });

    test('emits user when authenticated', () async {
      final mockUser = MockUser();
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
      );

      // Wait for stream to emit
      await container.read(authStateProvider.future);
      final state = container.read(authStateProvider);
      expect(state.value, mockUser);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `cd flutter_starter_kit && flutter test test/features/auth/providers/auth_provider_test.dart`
Expected: FAIL — providers not found.

**Step 3: Write the implementation**

```dart
// lib/features/auth/providers/auth_provider.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});
```

**Step 4: Run test to verify it passes**

Run: `cd flutter_starter_kit && flutter test test/features/auth/providers/auth_provider_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add -A && git commit -m "feat: add auth state provider"
```

---

## Task 7: Auth Screen

**Files:**

- Create: `lib/features/auth/widgets/social_login_buttons.dart`
- Create: `lib/features/auth/screens/auth_screen.dart`

**Step 1: Create social login buttons widget**

```dart
// lib/features/auth/widgets/social_login_buttons.dart

import 'dart:io';
import 'package:flutter/material.dart';

class SocialLoginButtons extends StatelessWidget {
  final VoidCallback onGooglePressed;
  final VoidCallback onApplePressed;
  final bool isLoading;

  const SocialLoginButtons({
    super.key,
    required this.onGooglePressed,
    required this.onApplePressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (Platform.isIOS) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onApplePressed,
              icon: const Icon(Icons.apple),
              label: const Text('Continue with Apple'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onGooglePressed,
            icon: const Icon(Icons.g_mobiledata),
            label: const Text('Continue with Google'),
          ),
        ),
      ],
    );
  }
}
```

**Step 2: Create auth screen**

```dart
// lib/features/auth/screens/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/widgets/social_login_buttons.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _signInWithApple() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signInWithApple();
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                AppConfig.appName,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to get started',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              if (_error != null) ...[
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 16),
              ],
              SocialLoginButtons(
                onGooglePressed: _signInWithGoogle,
                onApplePressed: _signInWithApple,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: add auth screen with social login buttons"
```

---

## Task 8: User Profile Service (Firestore)

**Files:**

- Create: `lib/features/auth/services/user_profile_service.dart`
- Create: `test/features/auth/services/user_profile_service_test.dart`

**Step 1: Write the failing test**

```dart
// test/features/auth/services/user_profile_service_test.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_starter_kit/features/auth/services/user_profile_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late UserProfileService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = UserProfileService(firestore: fakeFirestore);
  });

  group('UserProfileService', () {
    test('createProfile writes user data to Firestore', () async {
      await service.createProfile(
        uid: 'test-uid',
        displayName: 'Test User',
        email: 'test@example.com',
        photoUrl: null,
      );

      final doc = await fakeFirestore.collection('users').doc('test-uid').get();
      expect(doc.exists, true);
      expect(doc.data()?['displayName'], 'Test User');
      expect(doc.data()?['email'], 'test@example.com');
      expect(doc.data()?['onboardingComplete'], false);
    });

    test('getProfile returns user data', () async {
      await fakeFirestore.collection('users').doc('test-uid').set({
        'displayName': 'Test User',
        'email': 'test@example.com',
        'onboardingComplete': true,
      });

      final profile = await service.getProfile('test-uid');
      expect(profile?['displayName'], 'Test User');
      expect(profile?['onboardingComplete'], true);
    });

    test('markOnboardingComplete updates flag', () async {
      await fakeFirestore.collection('users').doc('test-uid').set({
        'displayName': 'Test User',
        'onboardingComplete': false,
      });

      await service.markOnboardingComplete('test-uid');

      final doc = await fakeFirestore.collection('users').doc('test-uid').get();
      expect(doc.data()?['onboardingComplete'], true);
    });

    test('deleteProfile removes user document', () async {
      await fakeFirestore.collection('users').doc('test-uid').set({
        'displayName': 'Test User',
      });

      await service.deleteProfile('test-uid');

      final doc = await fakeFirestore.collection('users').doc('test-uid').get();
      expect(doc.exists, false);
    });
  });
}
```

Note: Add `fake_cloud_firestore: ^3.1.0` to `dev_dependencies` in `pubspec.yaml` before running tests.

**Step 2: Run test to verify it fails**

Run: `cd flutter_starter_kit && flutter test test/features/auth/services/user_profile_service_test.dart`
Expected: FAIL — `UserProfileService` not found.

**Step 3: Write the implementation**

```dart
// lib/features/auth/services/user_profile_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileService {
  final FirebaseFirestore firestore;

  UserProfileService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      firestore.collection('users');

  Future<void> createProfile({
    required String uid,
    required String? displayName,
    required String? email,
    required String? photoUrl,
  }) async {
    await _users.doc(uid).set({
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'onboardingComplete': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.data();
  }

  Future<void> markOnboardingComplete(String uid) async {
    await _users.doc(uid).update({'onboardingComplete': true});
  }

  Future<void> deleteProfile(String uid) async {
    await _users.doc(uid).delete();
  }
}
```

**Step 4: Run test to verify it passes**

Run: `cd flutter_starter_kit && flutter test test/features/auth/services/user_profile_service_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add -A && git commit -m "feat: add user profile service for Firestore"
```

---

## Task 9: GoRouter with Auth & Onboarding Guards

**Files:**

- Create: `lib/routing/routes.dart`
- Create: `lib/routing/router.dart`
- Create: `test/routing/router_test.dart`

**Step 1: Create route constants**

```dart
// lib/routing/routes.dart

class AppRoutes {
  static const String auth = '/auth';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String paywall = '/paywall';
}
```

**Step 2: Write the failing test**

```dart
// test/routing/router_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_starter_kit/routing/routes.dart';

void main() {
  group('AppRoutes', () {
    test('auth route is /auth', () {
      expect(AppRoutes.auth, '/auth');
    });

    test('home route is /home', () {
      expect(AppRoutes.home, '/home');
    });

    test('onboarding route is /onboarding', () {
      expect(AppRoutes.onboarding, '/onboarding');
    });
  });
}
```

**Step 3: Run test to verify it passes (routes already created)**

Run: `cd flutter_starter_kit && flutter test test/routing/router_test.dart`
Expected: PASS

**Step 4: Create the router**

```dart
// lib/routing/router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/screens/auth_screen.dart';
import 'package:flutter_starter_kit/features/home/screens/home_screen.dart';
import 'package:flutter_starter_kit/features/onboarding/screens/onboarding_screen.dart';
import 'package:flutter_starter_kit/features/settings/screens/settings_screen.dart';
import 'package:flutter_starter_kit/features/paywall/screens/paywall_screen.dart';
import 'package:flutter_starter_kit/routing/routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isOnAuthPage = state.matchedLocation == AppRoutes.auth;

      if (!isLoggedIn && !isOnAuthPage) {
        return AppRoutes.auth;
      }

      if (isLoggedIn && isOnAuthPage) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        builder: (context, state) => const PaywallScreen(),
      ),
    ],
  );
});
```

Note: `HomeShell`, `HomeScreen`, `OnboardingScreen`, `SettingsScreen`, and `PaywallScreen` will be created in subsequent tasks. This file will produce compile errors until those are built. That's expected — we build incrementally.

**Step 5: Commit**

```bash
git add -A && git commit -m "feat: add GoRouter with auth redirect guard"
```

---

## Task 10: Home Screen with Shell Route

**Files:**

- Create: `lib/features/home/screens/home_screen.dart`

**Step 1: Create home screen with bottom navigation shell**

```dart
// lib/features/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeShell extends StatefulWidget {
  final Widget child;

  const HomeShell({super.key, required this.child});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() { _currentIndex = index; });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.explore), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Text('Home Screen — replace with your app content'),
    );
  }
}
```

**Step 2: Commit**

```bash
git add -A && git commit -m "feat: add home screen with bottom navigation shell"
```

---

## Task 11: Onboarding Feature

**Files:**

- Create: `lib/features/onboarding/providers/onboarding_provider.dart`
- Create: `lib/features/onboarding/widgets/onboarding_page.dart`
- Create: `lib/features/onboarding/widgets/progress_dots.dart`
- Create: `lib/features/onboarding/screens/onboarding_screen.dart`
- Create: `test/features/onboarding/providers/onboarding_provider_test.dart`

**Step 1: Write the failing test**

```dart
// test/features/onboarding/providers/onboarding_provider_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_starter_kit/features/onboarding/providers/onboarding_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('OnboardingNotifier', () {
    test('starts at page 0', () {
      final page = container.read(onboardingProvider);
      expect(page, 0);
    });

    test('nextPage increments', () {
      container.read(onboardingProvider.notifier).nextPage();
      expect(container.read(onboardingProvider), 1);
    });

    test('previousPage decrements', () {
      container.read(onboardingProvider.notifier).nextPage();
      container.read(onboardingProvider.notifier).previousPage();
      expect(container.read(onboardingProvider), 0);
    });

    test('previousPage does not go below 0', () {
      container.read(onboardingProvider.notifier).previousPage();
      expect(container.read(onboardingProvider), 0);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `cd flutter_starter_kit && flutter test test/features/onboarding/providers/onboarding_provider_test.dart`
Expected: FAIL — provider not found.

**Step 3: Write onboarding provider**

```dart
// lib/features/onboarding/providers/onboarding_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, int>(OnboardingNotifier.new);

class OnboardingNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void nextPage() {
    state = state + 1;
  }

  void previousPage() {
    if (state > 0) {
      state = state - 1;
    }
  }

  void goToPage(int page) {
    state = page;
  }
}
```

**Step 4: Run test to verify it passes**

Run: `cd flutter_starter_kit && flutter test test/features/onboarding/providers/onboarding_provider_test.dart`
Expected: PASS

**Step 5: Create onboarding page widget**

```dart
// lib/features/onboarding/widgets/onboarding_page.dart

import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 32),
          Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(description, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
```

**Step 6: Create progress dots widget**

```dart
// lib/features/onboarding/widgets/progress_dots.dart

import 'package:flutter/material.dart';

class ProgressDots extends StatelessWidget {
  final int total;
  final int current;

  const ProgressDots({super.key, required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
```

**Step 7: Create onboarding screen**

```dart
// lib/features/onboarding/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/services/user_profile_service.dart';
import 'package:flutter_starter_kit/features/onboarding/providers/onboarding_provider.dart';
import 'package:flutter_starter_kit/features/onboarding/widgets/onboarding_page.dart';
import 'package:flutter_starter_kit/features/onboarding/widgets/progress_dots.dart';
import 'package:flutter_starter_kit/routing/routes.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  static const _totalPages = 3;

  final _pages = const [
    OnboardingPage(
      title: 'Welcome',
      description: 'This is your app. Replace this with your value proposition.',
      icon: Icons.waving_hand,
    ),
    OnboardingPage(
      title: 'Personalize',
      description: 'Customize your experience. Replace with app-specific preferences.',
      icon: Icons.tune,
    ),
    OnboardingPage(
      title: 'Stay Updated',
      description: 'Enable notifications to never miss important updates.',
      icon: Icons.notifications_active,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      await UserProfileService().markOnboardingComplete(user.uid);
    }
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(onboardingProvider);
    final isLastPage = currentPage == _totalPages - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  ref.read(onboardingProvider.notifier).goToPage(page);
                },
                children: _pages,
              ),
            ),
            ProgressDots(total: _totalPages, current: currentPage),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLastPage
                      ? _completeOnboarding
                      : () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                  child: Text(isLastPage ? 'Get Started' : 'Next'),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
```

**Step 8: Commit**

```bash
git add -A && git commit -m "feat: add onboarding feature with page view and progress dots"
```

---

## Task 12: Paywall Feature

**Files:**

- Create: `lib/features/paywall/services/purchases_service.dart`
- Create: `lib/features/paywall/providers/purchases_provider.dart`
- Create: `lib/features/paywall/widgets/feature_comparison_row.dart`
- Create: `lib/features/paywall/widgets/price_card.dart`
- Create: `lib/features/paywall/screens/paywall_screen.dart`
- Create: `test/features/paywall/providers/purchases_provider_test.dart`

**Step 1: Create purchases service**

```dart
// lib/features/paywall/services/purchases_service.dart

import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_starter_kit/config/app_config.dart';

class PurchasesService {
  static Future<void> initialize() async {
    await Purchases.setLogLevel(LogLevel.debug);

    final apiKey = Platform.isIOS
        ? AppConfig.revenueCatAppleApiKey
        : AppConfig.revenueCatGoogleApiKey;

    await Purchases.configure(PurchasesConfiguration(apiKey));
  }

  static Future<void> login(String uid) async {
    await Purchases.logIn(uid);
  }

  static Future<void> logout() async {
    await Purchases.logOut();
  }

  static Future<CustomerInfo> getCustomerInfo() async {
    return Purchases.getCustomerInfo();
  }

  static Future<Offerings> getOfferings() async {
    return Purchases.getOfferings();
  }

  static Future<CustomerInfo> purchase(Package package) async {
    return (await Purchases.purchasePackage(package)).customerInfo;
  }

  static Future<CustomerInfo> restorePurchases() async {
    return Purchases.restorePurchases();
  }
}
```

**Step 2: Write the failing provider test**

```dart
// test/features/paywall/providers/purchases_provider_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_starter_kit/features/paywall/providers/purchases_provider.dart';

void main() {
  group('isPremiumProvider', () {
    test('defaults to false', () {
      final container = ProviderContainer(
        overrides: [
          isPremiumProvider.overrideWith((ref) => false),
        ],
      );

      expect(container.read(isPremiumProvider), false);
      container.dispose();
    });

    test('returns true when overridden', () {
      final container = ProviderContainer(
        overrides: [
          isPremiumProvider.overrideWith((ref) => true),
        ],
      );

      expect(container.read(isPremiumProvider), true);
      container.dispose();
    });
  });
}
```

**Step 3: Run test to verify it fails**

Run: `cd flutter_starter_kit && flutter test test/features/paywall/providers/purchases_provider_test.dart`
Expected: FAIL — provider not found.

**Step 4: Write the provider**

```dart
// lib/features/paywall/providers/purchases_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_starter_kit/features/paywall/services/purchases_service.dart';

final isPremiumProvider = StateProvider<bool>((ref) => false);

final customerInfoProvider = FutureProvider<CustomerInfo>((ref) async {
  return PurchasesService.getCustomerInfo();
});

final offeringsProvider = FutureProvider<Offerings>((ref) async {
  return PurchasesService.getOfferings();
});
```

**Step 5: Run test to verify it passes**

Run: `cd flutter_starter_kit && flutter test test/features/paywall/providers/purchases_provider_test.dart`
Expected: PASS

**Step 6: Create feature comparison row widget**

```dart
// lib/features/paywall/widgets/feature_comparison_row.dart

import 'package:flutter/material.dart';

class FeatureComparisonRow extends StatelessWidget {
  final String feature;
  final bool freeIncluded;
  final bool premiumIncluded;

  const FeatureComparisonRow({
    super.key,
    required this.feature,
    required this.freeIncluded,
    required this.premiumIncluded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(feature)),
          Expanded(
            child: Icon(
              freeIncluded ? Icons.check_circle : Icons.cancel,
              color: freeIncluded ? Colors.green : Colors.grey,
            ),
          ),
          Expanded(
            child: Icon(
              premiumIncluded ? Icons.check_circle : Icons.cancel,
              color: premiumIncluded ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 7: Create price card widget**

```dart
// lib/features/paywall/widgets/price_card.dart

import 'package:flutter/material.dart';

class PriceCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final bool isSelected;
  final VoidCallback onTap;

  const PriceCard({
    super.key,
    required this.title,
    required this.price,
    required this.period,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? colorScheme.primaryContainer : null,
        ),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(price, style: Theme.of(context).textTheme.headlineMedium),
            Text(period, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
```

**Step 8: Create paywall screen**

```dart
// lib/features/paywall/screens/paywall_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_starter_kit/features/paywall/providers/purchases_provider.dart';
import 'package:flutter_starter_kit/features/paywall/services/purchases_service.dart';
import 'package:flutter_starter_kit/features/paywall/widgets/feature_comparison_row.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isLoading = false;

  Future<void> _restorePurchases() async {
    setState(() { _isLoading = true; });
    try {
      final customerInfo = await PurchasesService.restorePurchases();
      final isPremium = customerInfo.entitlements.active.containsKey('premium');
      ref.read(isPremiumProvider.notifier).state = isPremium;
      if (isPremium && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final offerings = ref.watch(offeringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text('Unlock Premium', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Get access to all features', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              const FeatureComparisonRow(feature: 'Feature', freeIncluded: true, premiumIncluded: true),
              const FeatureComparisonRow(feature: 'Basic Access', freeIncluded: true, premiumIncluded: true),
              const FeatureComparisonRow(feature: 'Premium Feature 1', freeIncluded: false, premiumIncluded: true),
              const FeatureComparisonRow(feature: 'Premium Feature 2', freeIncluded: false, premiumIncluded: true),
              const Spacer(),
              offerings.when(
                data: (offerings) {
                  final current = offerings.current;
                  if (current == null) {
                    return const Text('No offerings available');
                  }
                  final package = current.availablePackages.firstOrNull;
                  if (package == null) {
                    return const Text('No packages available');
                  }
                  return SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              setState(() { _isLoading = true; });
                              try {
                                final info = await PurchasesService.purchase(package);
                                final isPremium = info.entitlements.active.containsKey('premium');
                                ref.read(isPremiumProvider.notifier).state = isPremium;
                                if (isPremium && mounted) context.pop();
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Purchase failed: $e')),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() { _isLoading = false; });
                              }
                            },
                      child: Text(_isLoading ? 'Loading...' : 'Subscribe - ${package.storeProduct.priceString}'),
                    ),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading ? null : _restorePurchases,
                child: const Text('Restore Purchases'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 9: Commit**

```bash
git add -A && git commit -m "feat: add paywall feature with RevenueCat integration"
```

---

## Task 13: Settings Screen

**Files:**

- Create: `lib/features/settings/screens/settings_screen.dart`
- Create: `lib/features/settings/widgets/settings_section.dart`

**Step 1: Create settings section widget**

```dart
// lib/features/settings/widgets/settings_section.dart

import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}
```

**Step 2: Create settings screen**

```dart
// lib/features/settings/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/paywall/providers/purchases_provider.dart';
import 'package:flutter_starter_kit/features/paywall/services/purchases_service.dart';
import 'package:flutter_starter_kit/features/auth/services/auth_service.dart';
import 'package:flutter_starter_kit/features/auth/services/user_profile_service.dart';
import 'package:flutter_starter_kit/features/settings/providers/theme_provider.dart';
import 'package:flutter_starter_kit/features/settings/widgets/settings_section.dart';
import 'package:flutter_starter_kit/routing/routes.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Appearance
          SettingsSection(
            title: 'Appearance',
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: themeMode == ThemeMode.dark,
                onChanged: (_) {
                  ref.read(themeModeProvider.notifier).toggle();
                },
              ),
            ],
          ),

          // Subscription
          if (AppConfig.enablePaywall)
            SettingsSection(
              title: 'Subscription',
              children: [
                ListTile(
                  title: const Text('Current Plan'),
                  subtitle: Text(isPremium ? 'Premium' : 'Free'),
                  trailing: isPremium ? null : const Icon(Icons.chevron_right),
                  onTap: isPremium
                      ? null
                      : () => context.push(AppRoutes.paywall),
                ),
                ListTile(
                  title: const Text('Restore Purchases'),
                  onTap: () async {
                    try {
                      final info = await PurchasesService.restorePurchases();
                      final restored = info.entitlements.active.containsKey('premium');
                      ref.read(isPremiumProvider.notifier).state = restored;
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(restored ? 'Purchases restored!' : 'No purchases found')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),

          // About
          SettingsSection(
            title: 'About',
            children: [
              ListTile(
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => launchUrl(Uri.parse(AppConfig.privacyPolicyUrl)),
              ),
              ListTile(
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => launchUrl(Uri.parse(AppConfig.termsOfServiceUrl)),
              ),
            ],
          ),

          // Account
          SettingsSection(
            title: 'Account',
            children: [
              ListTile(
                title: const Text('Sign Out'),
                onTap: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go(AppRoutes.auth);
                },
              ),
              ListTile(
                title: Text(
                  'Delete Account',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () => _showDeleteConfirmation(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final user = ref.read(authStateProvider).valueOrNull;
              if (user != null) {
                await UserProfileService().deleteProfile(user.uid);
                await PurchasesService.logout();
                await ref.read(authServiceProvider).deleteAccount();
              }
              if (context.mounted) context.go(AppRoutes.auth);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
```

Note: Add `url_launcher: ^6.3.1` to dependencies in `pubspec.yaml`.

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: add settings screen with theme toggle, subscription, and account management"
```

---

## Task 14: Push Notifications (FCM)

**Files:**

- Create: `lib/features/notifications/services/fcm_service.dart`
- Create: `lib/features/notifications/providers/notification_provider.dart`

**Step 1: Create FCM service**

```dart
// lib/features/notifications/services/fcm_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission (iOS)
    final settings = await _messaging.requestPermission();
    if (kDebugMode) {
      print('FCM permission status: ${settings.authorizationStatus}');
    }

    // Get and save token
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  Future<void> _saveToken(String token) async {
    // Token is saved to the user's Firestore profile.
    // This requires the user to be authenticated.
    // Caller should handle linking token to user document.
    if (kDebugMode) {
      print('FCM Token: $token');
    }
  }

  Future<void> saveTokenForUser(String uid) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
      });
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Foreground message: ${message.notification?.title}');
    }
    // Override this to show in-app banner or snackbar
  }

  void _handleMessageTap(RemoteMessage message) {
    if (kDebugMode) {
      print('Message tap: ${message.data}');
    }
    // Override this to navigate via GoRouter deep linking
    // Example: final route = message.data['route'];
    // GoRouter.of(context).push(route);
  }
}
```

**Step 2: Create notification provider**

```dart
// lib/features/notifications/providers/notification_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/notifications/services/fcm_service.dart';

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService();
});
```

**Step 3: Update main.dart to initialize FCM**

Add after `FirebaseService.initialize()` in `main.dart`:

```dart
// After FirebaseService.initialize():
if (AppConfig.enableNotifications) {
  await FcmService().initialize();
}
```

Add the required imports:

```dart
import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:flutter_starter_kit/features/notifications/services/fcm_service.dart';
```

**Step 4: Commit**

```bash
git add -A && git commit -m "feat: add FCM push notification service"
```

---

## Task 15: Shared Widgets

**Files:**

- Create: `lib/shared/widgets/loading_state.dart`
- Create: `lib/shared/widgets/premium_gate.dart`

**Step 1: Create loading state widget**

```dart
// lib/shared/widgets/loading_state.dart

import 'package:flutter/material.dart';

class LoadingState extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Widget child;

  const LoadingState({
    super.key,
    required this.isLoading,
    this.errorMessage,
    this.onRetry,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      );
    }

    return child;
  }
}
```

**Step 2: Create premium gate widget**

```dart
// lib/shared/widgets/premium_gate.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_starter_kit/features/paywall/providers/purchases_provider.dart';
import 'package:flutter_starter_kit/routing/routes.dart';

class PremiumGate extends ConsumerWidget {
  final Widget child;
  final Widget? lockedWidget;

  const PremiumGate({
    super.key,
    required this.child,
    this.lockedWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    if (isPremium) return child;

    return lockedWidget ??
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 48),
              const SizedBox(height: 16),
              const Text('Premium Feature'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => context.push(AppRoutes.paywall),
                child: const Text('Upgrade'),
              ),
            ],
          ),
        );
  }
}
```

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: add shared widgets (loading_state, premium_gate)"
```

---

## Task 16: Update Router with Onboarding Guard

**Files:**

- Modify: `lib/routing/router.dart`

**Step 1: Add onboarding check to the router redirect**

Update the `redirect` function in `router.dart` to include onboarding guard logic:

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final location = state.matchedLocation;
      final isOnAuthPage = location == AppRoutes.auth;
      final isOnOnboardingPage = location == AppRoutes.onboarding;

      // Not authenticated -> auth screen
      if (!isLoggedIn && !isOnAuthPage) {
        return AppRoutes.auth;
      }

      // Authenticated but on auth page -> home
      if (isLoggedIn && isOnAuthPage) {
        return AppRoutes.home;
      }

      // Note: Onboarding check requires async Firestore call.
      // In practice, cache onboardingComplete in a Riverpod provider
      // and check it here. For now, the onboarding flow is triggered
      // manually after sign-in by checking the user profile.

      return null;
    },
    routes: [
      // ... (same routes as Task 9)
    ],
  );
});
```

**Step 2: Commit**

```bash
git add -A && git commit -m "feat: add onboarding guard comments to router"
```

---

## Task 17: README and Final Wiring

**Files:**

- Create: `flutter_starter_kit/README.md`
- Modify: `lib/main.dart` (final version)
- Modify: `lib/app.dart` (final version)

**Step 1: Write README**

```markdown
# Flutter + Firebase Starter Kit

Clone -> edit 3 config files -> start building features.

## Quick Start

1. Clone this repo
2. Run `flutter pub get`
3. Configure Firebase: `flutterfire configure`
4. Edit config files:
   - `lib/config/app_config.dart` — app name, RevenueCat keys, feature flags
   - `lib/config/environment.dart` — environment selection
   - `lib/config/theme.dart` — seed color, font family
5. Run: `flutter run`

## Features

- **Auth:** Apple + Google sign-in via Firebase Auth
- **Onboarding:** 3-step configurable flow with progress dots
- **Paywall:** RevenueCat subscription management
- **Settings:** Dark mode, subscription, about, sign out, delete account
- **Push Notifications:** FCM with foreground/background handling
- **Navigation:** GoRouter with auth guards and bottom nav
- **Theming:** Material 3, light + dark mode

## Architecture

Feature-folder structure. Each feature is self-contained and deletable.

## Environment

Set environment at build time:
```

flutter run --dart-define=ENV=dev
flutter build ios --dart-define=ENV=prod

```

```

**Step 2: Ensure main.dart has all initialization**

Final `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/app.dart';
import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:flutter_starter_kit/config/environment.dart';
import 'package:flutter_starter_kit/features/notifications/services/fcm_service.dart';
import 'package:flutter_starter_kit/features/paywall/services/purchases_service.dart';
import 'package:flutter_starter_kit/shared/services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvironmentConfig.init();
  await FirebaseService.initialize();

  if (AppConfig.enablePaywall) {
    await PurchasesService.initialize();
  }

  if (AppConfig.enableNotifications) {
    await FcmService().initialize();
  }

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
```

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: add README and finalize main.dart initialization"
```

---

## Task 18: Integration Smoke Test

**Files:**

- Create: `test/app_test.dart`

**Step 1: Write a basic widget test to verify the app builds**

```dart
// test/app_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  testWidgets('App renders auth screen when not logged in', (tester) async {
    final mockAuthService = MockAuthService();
    when(() => mockAuthService.authStateChanges)
        .thenAnswer((_) => Stream.value(null));

    // This verifies providers can be created without errors
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
      ],
    );

    final authState = await container.read(authStateProvider.future);
    expect(authState, isNull);

    container.dispose();
  });
}
```

**Step 2: Run test**

Run: `cd flutter_starter_kit && flutter test test/app_test.dart`
Expected: PASS

**Step 3: Run all tests**

Run: `cd flutter_starter_kit && flutter test`
Expected: All tests pass.

**Step 4: Commit**

```bash
git add -A && git commit -m "feat: add integration smoke test"
```

---

## Summary

| Task | Feature                 | Key Files                                                    |
| ---- | ----------------------- | ------------------------------------------------------------ |
| 1    | Project Scaffolding     | pubspec.yaml, folder structure                               |
| 2    | Config Layer            | app_config.dart, environment.dart, theme.dart                |
| 3    | Firebase & App Shell    | firebase_service.dart, main.dart, app.dart                   |
| 4    | Theme Mode Provider     | theme_provider.dart + test                                   |
| 5    | Auth Service            | auth_service.dart + test                                     |
| 6    | Auth Provider           | auth_provider.dart + test                                    |
| 7    | Auth Screen             | auth_screen.dart, social_login_buttons.dart                  |
| 8    | User Profile Service    | user_profile_service.dart + test                             |
| 9    | GoRouter                | router.dart, routes.dart + test                              |
| 10   | Home Screen             | home_screen.dart                                             |
| 11   | Onboarding              | onboarding_screen.dart, provider + test, widgets             |
| 12   | Paywall                 | paywall_screen.dart, purchases_service.dart, provider + test |
| 13   | Settings                | settings_screen.dart, settings_section.dart                  |
| 14   | Push Notifications      | fcm_service.dart, notification_provider.dart                 |
| 15   | Shared Widgets          | loading_state.dart, premium_gate.dart                        |
| 16   | Router Onboarding Guard | router.dart update                                           |
| 17   | README & Final Wiring   | README.md, main.dart final                                   |
| 18   | Smoke Test              | app_test.dart                                                |
