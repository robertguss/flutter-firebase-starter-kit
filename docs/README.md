# Documentation

This repository is a Flutter + Firebase starter kit for mobile apps that need:

- Firebase Authentication with Google and Apple sign-in
- Firestore-backed user profiles
- A starter onboarding flow
- RevenueCat-based subscriptions
- Push notification wiring with Firebase Cloud Messaging
- Riverpod state management and GoRouter navigation

If you are new to the project, start here:

1. [Getting Started on macOS](./guides/getting-started-macos.md)
2. [Configuration Reference](./reference/configuration-reference.md)
3. [Architecture Overview](./reference/architecture.md)

If you are setting up specific integrations:

- [Firebase and Authentication Setup](./guides/firebase-authentication-setup.md)
- [RevenueCat Setup](./guides/revenuecat-setup.md)
- [iOS Flavor Schemes](./guides/ios-flavor-schemes.md)
- [Removing Features](./guides/removing-features.md)

Release history lives in [CHANGELOG.md](./CHANGELOG.md).

## What These Docs Optimize For

- Beginner-friendly language
- Real setup steps, not just code snippets
- Honest notes about what is complete and what is still a starter-kit
  placeholder
- Open-source friendly guidance that avoids depending on private company context

## Current Starter Kit Caveats

These are intentional to keep the template flexible, but you should know about
them before building on top of it:

- The project currently calls `Firebase.initializeApp()` directly. Most teams
  will want to generate `firebase_options.dart` with `flutterfire configure` and
  wire it into `FirebaseService`.
- The onboarding route exists, but the router does not yet automatically
  redirect a signed-in user based on `onboardingComplete`.
- The paywall currently assumes the RevenueCat entitlement ID is `premium`.
- Push notifications are initialized, but in-app notification UI and deep-link
  handling are still placeholder implementations.
- The home screen and some copy are template content and meant to be replaced.
