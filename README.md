# Flutter + Firebase Starter Kit

An open-source starter kit for building mobile apps with Flutter, Firebase,
Riverpod, GoRouter, RevenueCat, onboarding, settings, and push-notification
scaffolding.

This project is meant to save you from re-solving the same early app wiring
every time you start a new product.

## What You Get

- Firebase Authentication starter wiring for Google and Apple sign-in
- Firestore-backed user profile service
- GoRouter navigation with an auth guard
- RevenueCat subscription scaffolding and starter paywall
- Theme persistence with Riverpod + SharedPreferences
- Onboarding flow starter screens
- Settings screen starter implementation
- Firebase Cloud Messaging service scaffolding
- Tests for core providers and services

## Who This Is For

This starter kit is a good fit if you want to launch a Flutter mobile app and
you know you will likely need:

- authentication
- a user profile in Firestore
- subscriptions
- onboarding
- settings
- push notifications

It is especially useful if you want a practical baseline instead of a blank
Flutter app.

## Quick Start

If you want the full step-by-step setup flow, start here:

- [Getting Started on macOS](./docs/guides/getting-started-macos.md)

Short version:

```bash
git clone <your-fork-or-repo-url> my-app
cd my-app
make setup                    # install deps + analyze
flutterfire configure         # generate firebase_options.dart
flutter run                   # or: make run-dev
```

### 3 files to customize your app

1. `lib/config/app_config.dart` — app name, RevenueCat API keys, feature flags
2. `lib/config/theme.dart` — seed color, font family
3. `lib/config/environment.dart` — environment selection

### Plus standard platform setup

- Configure Firebase Authentication providers (Google, Apple) in the Firebase
  Console
- Configure Firestore security rules
- Configure RevenueCat products, offerings, and API keys (if paywall is enabled)
- Finish iOS push-notification capabilities and APNs setup (if notifications are
  enabled)
- Update bundle identifiers for your app

## Documentation Map

- [Documentation Index](./docs/README.md)
- [Getting Started on macOS](./docs/guides/getting-started-macos.md)
- [Firebase and Authentication Setup](./docs/guides/firebase-authentication-setup.md)
- [RevenueCat Setup](./docs/guides/revenuecat-setup.md)
- [Removing Features](./docs/guides/removing-features.md) — paywall,
  notifications, onboarding
- [Configuration Reference](./docs/reference/configuration-reference.md)
- [Architecture Overview](./docs/reference/architecture.md)
- [Changelog](./docs/CHANGELOG.md)

## Current Starter Kit Caveats

This repo is intentionally a starter, not a complete production app.

Current gaps you should plan to close:

- the router does not yet automatically enforce onboarding completion from
  Firestore profile state
- `firebase_options.dart` is not yet wired into `FirebaseService` by default
- the home screen is placeholder content
- push notifications are initialized, but in-app presentation and deep-link
  behavior are still placeholders
- the paywall expects a RevenueCat entitlement named `premium`

## Tech Stack

- Flutter
- Dart
- Riverpod
- GoRouter
- Firebase Auth
- Cloud Firestore
- Firebase Cloud Messaging
- RevenueCat
- SharedPreferences

## Local Verification

```bash
make analyze
make test
```

## Open Source Positioning

This repository is designed to be copied, adapted, and renamed for real apps.

You should expect to change:

- product naming and bundle identifiers
- visual design and copy
- legal URLs
- store and Firebase configuration
- subscription model
- onboarding flow behavior
