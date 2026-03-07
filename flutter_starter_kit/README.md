# Flutter + Firebase Starter Kit

Clone -> edit 3 config files -> start building features.

## Quick Start

1. Clone this repo
2. Run `flutter pub get`
3. Configure Firebase: `flutterfire configure`
4. Edit config files:
   - `lib/config/app_config.dart` - app name, RevenueCat keys, feature flags
   - `lib/config/environment.dart` - environment selection
   - `lib/config/theme.dart` - seed color, font family
5. Run `flutter run`

## Features

- Auth: Apple + Google sign-in via Firebase Auth
- Onboarding: 3-step configurable flow with progress dots
- Paywall: RevenueCat subscription management
- Settings: Dark mode, subscription, about, sign out, delete account
- Push Notifications: FCM with foreground/background handling
- Navigation: GoRouter with auth guards and bottom nav
- Theming: Material 3, light + dark mode

## Architecture

Feature-folder structure. Each feature is self-contained and deletable.

## Environment

Set environment at build time:

```bash
flutter run --dart-define=ENV=dev
flutter build ios --dart-define=ENV=prod
```
