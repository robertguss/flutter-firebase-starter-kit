# Changelog

All notable changes to this project should be documented in this file.

This file follows the spirit of
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and is intended for
human readers.

## [0.1.0] - 2026-03-07

Initial open-source starter release.

### Added

- Flutter starter app structure organized by feature folders
- Riverpod-based state management and GoRouter-based navigation
- Firebase initialization service
- Firebase Auth service with Google and Apple sign-in entry points
- Firestore-backed user profile service
- Auth screen with social login buttons
- Settings screen with theme toggle, legal links, sign out, and delete-account
  flow
- Onboarding flow with page state and progress dots
- RevenueCat paywall service, providers, and starter UI
- Firebase Cloud Messaging service and provider scaffolding
- Shared loading and premium-gate widgets
- Automated tests covering providers, services, routes, and basic app smoke
  checks
- Beginner-friendly documentation set under `docs/`

### Notes

- RevenueCat setup assumes an entitlement ID of `premium`
- Firebase onboarding-based router enforcement is not finished yet
- Notification handling is wired at the service level but still needs
  product-specific UX and deep linking
