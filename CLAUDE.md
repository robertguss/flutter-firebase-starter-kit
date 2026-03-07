# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Project Overview

Flutter + Firebase mobile starter kit. Clone, configure 3 files, and start
building features. Uses Riverpod for state management, GoRouter for navigation,
Firebase for backend, and RevenueCat for payments.

## Commands

```bash
# Install dependencies
flutter pub get

# Run the app (defaults to dev environment)
flutter run

# Run with specific environment
flutter run --dart-define=ENV=dev
flutter run --dart-define=ENV=staging
flutter run --dart-define=ENV=prod

# Build for production
flutter build ios --dart-define=ENV=prod
flutter build apk --dart-define=ENV=prod

# Run all tests
flutter test

# Run a single test file
flutter test test/features/auth/providers/auth_provider_test.dart

# Analyze code (uses flutter_lints + custom_lint with riverpod_lint)
flutter analyze
```

## Architecture

### Feature-Folder Structure

Each feature is self-contained under `lib/features/` with its own `providers/`,
`screens/`, `services/`, and `widgets/` subdirectories. Features are designed to
be independently deletable.

```
lib/
├── main.dart                    # Entry point: init Firebase, RevenueCat, FCM
├── app.dart                     # MaterialApp.router with theme + router
├── config/
│   ├── app_config.dart          # App name, API keys, feature flags
│   ├── environment.dart         # ENV enum (dev/staging/prod) via --dart-define
│   └── theme.dart               # Material 3 theme (seed color + font)
├── routing/
│   ├── router.dart              # GoRouter with auth redirect guard
│   └── routes.dart              # Route path constants (AppRoutes)
├── features/
│   ├── auth/                    # Firebase Auth (Apple + Google sign-in)
│   ├── home/                    # Home screen with bottom nav shell
│   ├── notifications/           # FCM push notifications
│   ├── onboarding/              # 3-step onboarding flow
│   ├── paywall/                 # RevenueCat subscription management
│   └── settings/                # Theme toggle, account management
└── shared/
    ├── services/firebase_service.dart
    └── widgets/                 # loading_state.dart, premium_gate.dart
```

### Key Patterns

- **State Management**: Riverpod providers (`Provider`, `StreamProvider`). Auth
  state is a `StreamProvider<User?>` wrapping `FirebaseAuth.authStateChanges`.
- **Navigation**: GoRouter with a global `redirect` that gates all routes behind
  auth. Unauthenticated users go to `/auth`, authenticated users on `/auth`
  redirect to `/home`. `StatefulShellRoute` wraps the home tab scaffold.
- **Feature Flags**: `AppConfig.enablePaywall` and
  `AppConfig.enableNotifications` control whether RevenueCat and FCM initialize
  in `main()`.
- **Theming**: `AppTheme` generates light/dark `ThemeData` from a seed color.
  `themeModeProvider` (Riverpod) tracks user preference.
- **Environment**: Set via `--dart-define=ENV=dev|staging|prod`. Parsed in
  `EnvironmentConfig.init()`.

### Configuration Files (the 3 files to edit)

1. `lib/config/app_config.dart` — app name, RevenueCat API keys, feature flags
2. `lib/config/environment.dart` — environment selection
3. `lib/config/theme.dart` — seed color, font family

### Testing

Tests mirror the `lib/` structure under `test/`. Uses `mocktail` for mocking and
`fake_cloud_firestore` for Firestore fakes. Test files exist for providers,
services, and routing.

### Dependencies

- **State**: `flutter_riverpod`, `riverpod_annotation`
- **Navigation**: `go_router`
- **Firebase**: `firebase_core`, `firebase_auth`, `cloud_firestore`,
  `firebase_messaging`
- **Auth**: `google_sign_in`, `sign_in_with_apple`
- **Payments**: `purchases_flutter` (RevenueCat)
- **Storage**: `shared_preferences`
- **Observability**: `firebase_crashlytics`, `firebase_analytics`
- **UI**: `url_launcher`, `package_info_plus`
- **Dev**: `mocktail`, `fake_cloud_firestore`, `riverpod_lint`

### Package Name

The Dart package is `flutter_starter_kit` — use this in imports:
`package:flutter_starter_kit/...`
