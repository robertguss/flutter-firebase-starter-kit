# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Project Overview

Flutter + Firebase mobile starter kit. Clone, configure 3 files, and start
building features. Uses Riverpod for state management, GoRouter for navigation,
Firebase for backend, and RevenueCat for payments.

## Commands

```bash
# Initial setup (install deps + analyze)
make setup

# Install dependencies
make get

# Run the app (default — uses --dart-define=ENV=dev)
flutter run

# Run with flavors (recommended)
make run-dev        # flutter run --flavor dev -t lib/main_dev.dart
make run-staging    # flutter run --flavor staging -t lib/main_staging.dart
make run-prod       # flutter run --flavor prod -t lib/main_prod.dart

# Build for production
flutter build ios --flavor prod -t lib/main_prod.dart
flutter build apk --flavor prod -t lib/main_prod.dart

# Run all tests
make test

# Run a single test file
flutter test test/features/auth/providers/auth_provider_test.dart

# Analyze code (uses flutter_lints + custom_lint with riverpod_lint)
make analyze

# Code generation (Riverpod codegen, l10n)
make build-runner
make watch          # watch mode

# See all available commands
make help
```

## Architecture

### Feature-Folder Structure

Each feature is self-contained under `lib/features/` with its own `providers/`,
`screens/`, `services/`, and `widgets/` subdirectories. Features are designed to
be independently deletable.

```
lib/
├── main.dart                    # Default entry point (--dart-define fallback)
├── main_dev.dart                # Dev flavor entry point
├── main_staging.dart            # Staging flavor entry point
├── main_prod.dart               # Prod flavor entry point
├── bootstrap.dart               # Shared init: Firebase, RevenueCat, FCM, hooks
├── app.dart                     # MaterialApp.router with theme + router + l10n
├── l10n/
│   └── app_en.arb               # English strings (add app_XX.arb for new locales)
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
  in `bootstrap()`.
- **Theming**: `AppTheme` generates light/dark `ThemeData` from a seed color.
  `themeModeProvider` (Riverpod) tracks user preference.
- **Environment**: Set via flavor entry points (`main_dev.dart`,
  `main_staging.dart`, `main_prod.dart`) or fallback `--dart-define=ENV=dev`.
- **Localization**: Flutter's built-in l10n with ARB files in `lib/l10n/`. All
  user-facing strings use `AppLocalizations.of(context)`.

### Architectural Rules

- `shared/` **never** imports from `features/`. Features may import from
  `shared/` and from other features only through the composition root
  (`lib/bootstrap.dart`).
- Each feature is independently deletable. See
  `docs/guides/removing-features.md` for step-by-step removal checklists.

### Documentation

See `docs/guides/` for detailed guides:

- `getting-started-macos.md` — full setup walkthrough
- `removing-features.md` — how to remove paywall, notifications, or onboarding
- `firebase-authentication-setup.md` — Firebase Auth configuration
- `revenuecat-setup.md` — RevenueCat configuration

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
