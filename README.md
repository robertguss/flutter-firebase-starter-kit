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
git clone <your-fork-or-repo-url> mobile-starter-kit
cd mobile-starter-kit
flutter pub get
flutterfire configure
flutter run --dart-define=ENV=dev
```

Before the app is truly ready, you still need to:

- replace placeholder values in `lib/config/app_config.dart`
- configure Firebase Authentication providers
- configure Firestore
- configure RevenueCat products, offerings, and API keys
- finish iOS push-notification capabilities and APNs setup if notifications are
  enabled

## Documentation Map

- [Documentation Index](./docs/README.md)
- [Getting Started on macOS](./docs/guides/getting-started-macos.md)
- [Firebase and Authentication Setup](./docs/guides/firebase-authentication-setup.md)
- [RevenueCat Setup](./docs/guides/revenuecat-setup.md)
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
flutter analyze
flutter test
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
